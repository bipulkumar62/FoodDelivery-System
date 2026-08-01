import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../config/theme.dart';
import '../services/image_upload_service.dart';

class MenuImagePicker extends StatefulWidget {
  const MenuImagePicker({
    super.key,
    required this.urlController,
    this.onUploadStarted,
    this.onUploadFinished,
    this.onUploaded,
  });

  /// The image URL field of the form. The widget writes the uploaded
  /// public URL into this controller so only the URL reaches the backend.
  final TextEditingController urlController;
  final VoidCallback? onUploadStarted;
  final VoidCallback? onUploadFinished;
  final ValueChanged<String>? onUploaded;

  @override
  State<MenuImagePicker> createState() => _MenuImagePickerState();
}

class _MenuImagePickerState extends State<MenuImagePicker> {
  bool _isUploading = false;
  double? _progress;
  String? _error;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    if (_isUploading) return;

    final XFile? picked;
    try {
      picked = await ImageUploadService.instance.pickImageFromGallery();
    } on PlatformException {
      _setError(
        'Photo access was denied. Please allow photo access in app settings.',
      );
      return;
    } on Exception {
      _setError('Could not open the photo gallery.');
      return;
    }
    if (picked == null) return;

    final file = File(picked.path);
    final validationError = ImageUploadService.instance.validateImage(file);
    if (validationError != null) {
      _setError(validationError);
      return;
    }

    setState(() {
      _isUploading = true;
      _progress = 0;
      _error = null;
    });
    widget.onUploadStarted?.call();

    try {
      final url = await ImageUploadService.instance.uploadImage(
        file,
        onProgress: (sent, total) {
          if (_disposed) return;
          setState(() => _progress = total > 0 ? sent / total : null);
        },
      );
      if (_disposed) return;
      widget.urlController.text = url;
      setState(() => _progress = null);
      widget.onUploaded?.call(url);
    } on ImageUploadException catch (e) {
      if (_disposed) return;
      if (e.uploadedUrl != null) {
        widget.urlController.text = e.uploadedUrl!;
      }
      setState(() {
        _error = e.message;
        _progress = null;
      });
    } catch (_) {
      if (_disposed) return;
      setState(() {
        _error = 'Upload failed. Please try again.';
        _progress = null;
      });
    } finally {
      if (!_disposed) setState(() => _isUploading = false);
      widget.onUploadFinished?.call();
    }
  }

  void _setError(String message) {
    if (_disposed) return;
    setState(() {
      _error = message;
      _progress = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.urlController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 160,
            color: AppTheme.surfaceColor,
            child: url.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _placeholder(),
                  )
                : _placeholder(),
          ),
        ),
        const SizedBox(height: 12),
        if (_isUploading) ...[
          _progress != null
              ? LinearProgressIndicator(
                  value: _progress,
                  color: AppTheme.primaryColor,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                )
              : const LinearProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 6),
          Text(
            _progress != null
                ? 'Uploading ${(_progress! * 100).round()}%'
                : 'Uploading...',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: _isUploading ? null : _pickAndUpload,
          icon: const Icon(Icons.photo_library_outlined),
          label: Text(url.isEmpty ? 'Upload Image' : 'Replace Image'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _error!,
              style: const TextStyle(color: AppTheme.errorColor, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  Widget _placeholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          const Text(
            'No image yet',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
