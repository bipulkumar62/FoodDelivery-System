import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../config/storage_constants.dart';

enum ImageUploadErrorType {
  permissionDenied,
  invalidFile,
  uploadFailed,
  networkError,
  urlUnavailable,
}

class ImageUploadException implements Exception {
  const ImageUploadException(this.type, this.message, {this.uploadedUrl});

  final ImageUploadErrorType type;
  final String message;

  /// Set when the file was uploaded but the public URL could not be
  /// verified, so the caller can keep the URL instead of losing it.
  final String? uploadedUrl;

  @override
  String toString() => message;
}

class ImageUploadService {
  ImageUploadService._();

  static final ImageUploadService instance = ImageUploadService._();

  static const Set<String> _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
  static const int _maxFileSizeBytes = 5 * 1024 * 1024;

  final ImagePicker _picker = ImagePicker();

  late final Dio _dio = Dio(
    BaseOptions(
      baseUrl: '${StorageConstants.supabaseUrl}/storage/v1',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(minutes: 2),
      headers: {
        'apikey': StorageConstants.supabaseAnonKey,
        'Authorization': 'Bearer ${StorageConstants.supabaseAnonKey}',
      },
    ),
  );

  Future<XFile?> pickImageFromGallery() {
    return _picker.pickImage(source: ImageSource.gallery);
  }

  /// Returns an error message when the file is invalid, otherwise null.
  String? validateImage(File file) {
    final extension = _extensionOf(file.path);
    if (extension == null || !_allowedExtensions.contains(extension)) {
      return 'Unsupported image type. Please choose a JPG, PNG or WEBP file.';
    }
    if (!file.existsSync() || file.lengthSync() == 0) {
      return 'The selected file is empty. Please choose another image.';
    }
    if (file.lengthSync() > _maxFileSizeBytes) {
      return 'Image is too large (max 5 MB). Please choose a smaller image.';
    }
    return null;
  }

  /// Uploads [file] to the existing bucket under a unique name and returns
  /// the public URL. Reports progress via [onProgress] (sent, total bytes).
  Future<String> uploadImage(
    File file, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw const ImageUploadException(
        ImageUploadErrorType.invalidFile,
        'The selected file is empty.',
      );
    }

    final extension = _extensionOf(file.path) ?? 'jpg';
    final key =
        '${StorageConstants.uploadFolder}/${DateTime.now().millisecondsSinceEpoch}-${_randomHex(6)}.$extension';
    final publicUrl =
        '${StorageConstants.supabaseUrl}/storage/v1/object/public/${StorageConstants.bucketName}/$key';

    debugPrint(
      '[ImageUpload] Uploading to bucket="${StorageConstants.bucketName}" '
      'path="$key" size=${bytes.length}B mime=${_contentTypeFor(extension)}',
    );

    try {
      final response = await _dio.post(
        '/object/${StorageConstants.bucketName}/$key',
        data: bytes,
        options: Options(
          headers: {'Content-Type': _contentTypeFor(extension)},
        ),
        onSendProgress: onProgress,
      );
      debugPrint(
        '[ImageUpload] Response status=${response.statusCode} '
        'message=${response.data}',
      );
      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw ImageUploadException(
          ImageUploadErrorType.uploadFailed,
          _statusMessage(response.statusCode),
        );
      }
    } on DioException catch (e) {
      debugPrint(
        '[ImageUpload] Error type=${e.type} status=${e.response?.statusCode} '
        'message=${e.response?.data}',
      );
      throw _mapDioError(e);
    }

    try {
      await _dio.get(publicUrl);
    } on DioException {
      throw ImageUploadException(
        ImageUploadErrorType.urlUnavailable,
        'Upload succeeded but the public image URL is not available yet. '
        'The URL has been kept in the field.',
        uploadedUrl: publicUrl,
      );
    }

    return publicUrl;
  }

  String _statusMessage(int? status) {
    switch (status) {
      case 400:
        return 'Invalid image. The file could not be uploaded.';
      case 401:
      case 403:
        return 'Storage permission denied. '
            'The storage bucket is not configured for admin uploads.';
      case 404:
        return 'Bucket not found. The storage bucket is misconfigured.';
      case 413:
        return 'File too large. Please choose a smaller image.';
      case 408:
        return 'Upload timed out. Please check your connection and retry.';
      case 429:
        return 'Too many uploads right now. Please try again in a moment.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Supabase storage is temporarily unavailable. '
            'Please try again in a moment.';
      default:
        return 'Upload failed (HTTP $status). Please try again.';
    }
  }

  ImageUploadException _mapDioError(DioException e) {
    if (e.type == DioExceptionType.sendTimeout) {
      return const ImageUploadException(
        ImageUploadErrorType.networkError,
        'Upload timed out. Please check your connection and retry.',
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const ImageUploadException(
        ImageUploadErrorType.networkError,
        'Network error while uploading. Check your connection and try again.',
      );
    }
    final status = e.response?.statusCode;
    if (status != null) {
      return ImageUploadException(
        ImageUploadErrorType.uploadFailed,
        _statusMessage(status),
      );
    }
    return const ImageUploadException(
      ImageUploadErrorType.uploadFailed,
      'Upload failed. Please try again.',
    );
  }

  static String? _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return null;
    return path.substring(dot + 1).toLowerCase();
  }

  static String _contentTypeFor(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  static String _randomHex(int length) {
    final random = Random.secure();
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(random.nextInt(16).toRadixString(16));
    }
    return buffer.toString();
  }
}
