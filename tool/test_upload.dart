import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class RawAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    stdout.writeln('RAWADAPTER_URI: ${options.uri}');
    stdout.writeln('RAWADAPTER_HEADERS: ${options.headers}');
    final client = HttpClient();
    final req = await client.postUrl(options.uri);
    options.headers.forEach((k, v) {
      if (v != null) req.headers.set(k, v);
    });
    req.headers.contentType = ContentType.parse(
        (options.headers['Content-Type'] as String?) ?? 'application/octet-stream');
    final chunks = <List<int>>[];
    await for (final chunk in requestStream!) {
      chunks.add(chunk);
    }
    final total = chunks.fold<int>(0, (a, b) => a + b.length);
    req.contentLength = total;
    for (final chunk in chunks) {
      req.add(chunk);
    }
    final resp = await req.close();
    final headers = <String, List<String>>{};
    resp.headers.forEach((k, v) => headers[k] = v);
    return ResponseBody(
      resp.cast(),
      resp.statusCode,
      headers: headers,
      statusMessage: resp.reasonPhrase,
    );
  }

  @override
  void close({bool force = false}) {}
}

class DioHttpClientAdapter extends IOHttpClientAdapter {
  DioHttpClientAdapter() : super(createHttpClient: () => HttpClient());
}

const anon =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmcGF1b3FqZWZwbm5scGxjZXZmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQ2ODkzMjQsImV4cCI6MjEwMDI2NTMyNH0.ADj51tYG-jypH8ZeGYwO0uLV5Pz_GxdU-B-t0DntL-k';
const url = 'https://yfpauoqjefpnnlplcevf.supabase.co';

final dio = Dio(BaseOptions(
  baseUrl: '$url/storage/v1',
  connectTimeout: const Duration(seconds: 30),
  receiveTimeout: const Duration(seconds: 30),
  sendTimeout: const Duration(minutes: 2),
  headers: {
    'apikey': anon,
    'Authorization': 'Bearer $anon',
  },
));

Future<void> main(List<String> args) async {
  final sizeMb = args.isNotEmpty ? double.parse(args[0]) : 1.0;
  final useProgress = args.length > 1 && args[1] == 'progress';
  final mode = args.length > 2 ? args[2] : 'bytes';

  final size = (sizeMb * 1024 * 1024).round();
  var bytes = Uint8List(size);
  for (var i = 0; i < size; i++) {
    bytes[i] = 0x61;
  }
  final head = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  for (var i = 0; i < head.length; i++) {
    bytes[i] = head[i];
  }
  final plainList = bytes.toList();

  final key =
      'menu/dio-test-$mode-$sizeMb-${DateTime.now().millisecondsSinceEpoch}.png';

  if (mode == 'httpclient' || mode == 'httpclient_chunked' ||
      mode == 'httpclient_gzip' || mode == 'capture_raw') {
    final target = mode == 'capture_raw'
        ? Uri.parse('http://localhost:9000/object/pawan/capture-raw.png')
        : Uri.parse('$url/storage/v1/object/pawan/$key');
    final client = HttpClient();
    final req = await client.postUrl(target);
    req.headers.set('apikey', anon);
    req.headers.set('Authorization', 'Bearer $anon');
    req.headers.contentType = ContentType('image', 'png');
    if (mode == 'httpclient_gzip') {
      req.headers.set('Accept-Encoding', 'gzip');
    }
    if (mode == 'httpclient_chunked') {
      const size = 1024;
      final chunks = <List<int>>[];
      for (var i = 0; i < bytes.length; i += size) {
        final end = (i + size < bytes.length) ? i + size : bytes.length;
        chunks.add(bytes.sublist(i, end));
      }
      req.contentLength = bytes.length;
      await req.addStream(Stream.fromIterable(chunks));
    } else {
      req.contentLength = bytes.length;
      req.add(bytes);
    }
    final resp = await req.close();
    final body = await resp.transform(SystemEncoding().decoder).join();
    stdout.writeln('RESULT mode=$mode size=${sizeMb}MB '
        'status=${resp.statusCode} body=$body');
    client.close();
    return;
  }

  if (mode == 'capture') {
    final localDio = Dio(BaseOptions(
      baseUrl: 'http://localhost:9000',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'apikey': anon,
        'Authorization': 'Bearer $anon',
      },
    ));
    final response = await localDio.post(
      '/object/pawan/capture-test.png',
      data: bytes,
      options: Options(
        validateStatus: (_) => true,
        headers: {'Content-Type': 'image/png'},
      ),
      onSendProgress: useProgress ? (s, t) {} : null,
    );
    stdout.writeln('CAPTURE status=${response.statusCode}');
    stdout.writeln('REQ_HEADERS: ${response.requestOptions.headers}');
    return;
  }

  if (mode == 'dio_plainclient') {
    final plainDio = Dio(BaseOptions(
      baseUrl: '$url/storage/v1',
      headers: {
        'apikey': anon,
        'Authorization': 'Bearer $anon',
      },
    ));
    plainDio.httpClientAdapter = DioHttpClientAdapter();
    final response = await plainDio.post(
      'object/pawan/$key',
      data: bytes,
      options: Options(
        validateStatus: (_) => true,
        headers: {'Content-Type': 'image/png'},
      ),
      onSendProgress: useProgress ? (s, t) {} : null,
    );
    stdout.writeln('RESULT mode=$mode progress=$useProgress '
        'status=${response.statusCode} body=${response.data}');
    return;
  }

  if (mode == 'dio_nokeepalive') {
    final response = await dio.post(
      'object/pawan/$key',
      data: bytes,
      options: Options(
        validateStatus: (_) => true,
        persistentConnection: false,
        headers: {'Content-Type': 'image/png'},
      ),
    );
    stdout.writeln('RESULT mode=$mode status=${response.statusCode} '
        'body=${response.data}');
    return;
  }

  if (mode == 'dio_rawadapter') {
    final plainDio = Dio(BaseOptions(
      baseUrl: '$url/storage/v1',
      headers: {
        'apikey': anon,
        'Authorization': 'Bearer $anon',
      },
    ));
    plainDio.httpClientAdapter = RawAdapter();
    final response = await plainDio.post(
      'object/pawan/$key',
      data: bytes,
      options: Options(
        validateStatus: (_) => true,
        headers: {'Content-Type': 'image/png'},
      ),
      onSendProgress: useProgress ? (s, t) {} : null,
    );
    stdout.writeln('RESULT mode=$mode progress=$useProgress '
        'status=${response.statusCode} body=${response.data}');
    return;
  }

  final Object data;
  final String path;
  switch (mode) {
    case 'uint8':
      data = bytes;
      path = 'object/pawan/$key';
      break;
    case 'uint8_slash':
      data = bytes;
      path = '/object/pawan/$key';
      break;
    case 'uint8_slash_jpg':
      data = bytes;
      path = '/object/pawan/$key';
      break;
    case 'uint8_slash_webp':
      data = bytes;
      path = '/object/pawan/$key';
      break;
    case 'list':
      data = plainList;
      path = 'object/pawan/$key';
      break;
    case 'multipart':
      data = MultipartFile.fromBytes(bytes, filename: 'photo.png');
      path = 'object/pawan/$key';
      break;
    default:
      throw ArgumentError('unknown mode $mode');
  }

  try {
    final response = await dio.post(
      path,
      data: data,
      options: Options(
        validateStatus: (_) => true,
        headers: {
          'Content-Type': mode == 'multipart'
              ? 'multipart/form-data'
              : (mode == 'uint8_slash_jpg'
                  ? 'image/jpeg'
                  : (mode == 'uint8_slash_webp' ? 'image/webp' : 'image/png')),
        },
      ),
      onSendProgress: useProgress ? (s, t) {} : null,
    );
    stdout.writeln('RESULT mode=$mode size=${sizeMb}MB progress=$useProgress '
        'dataType=${data.runtimeType} '
        'status=${response.statusCode} body=${response.data}');
    stdout.writeln('HEADERS: ${response.headers.toString()}');
    stdout.writeln('REQ_HEADERS: ${response.requestOptions.headers}');
  } on DioException catch (e) {
    stdout.writeln('RESULT mode=$mode size=${sizeMb}MB progress=$useProgress '
        'dataType=${data.runtimeType} '
        'status=${e.response?.statusCode} '
        'type=${e.type} body=${e.response?.data}');
    if (e.response != null) {
      stdout.writeln('HEADERS: ${e.response!.headers.toString()}');
      stdout.writeln('REQ_HEADERS: ${e.response!.requestOptions.headers}');
    }
  }
}
