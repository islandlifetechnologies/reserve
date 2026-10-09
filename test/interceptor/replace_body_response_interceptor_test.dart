import 'dart:convert';
import 'dart:typed_data';

import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  group('ReplaceBodyResponseInterceptor', () {
    test('builder initializes from params', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = ReplaceBodyResponseInterceptor.builder(
        config: config,
        params: {'from': 'foo', 'replace': 'bar'},
      );

      expect(interceptor.type, InterceptorType.replaceBody);
    });

    test('replaces text in JSON body', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = ReplaceBodyResponseInterceptor(
        config: config,
        from: 'http://internal.backend',
        replace: 'https://public.api',
      );

      final request = ReServeRequest.empty();
      final response = ReServeResponse(
        bytes: Uint8List.fromList(
          utf8.encode('{"url": "http://internal.backend/item"}'),
        ),
        headers: [
          ReServeHeader(
            key: 'content-type',
            value: 'application/json; charset=utf-8',
          ),
        ],
        statusCode: 200,
      );

      final result = interceptor.interceptResponse(request, response);
      expect(utf8.decode(result.bytes), '{"url": "https://public.api/item"}');
    });

    test('replaces text in text/html body', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = ReplaceBodyResponseInterceptor(
        config: config,
        from: 'localhost:8080',
        replace: 'example.com',
      );

      final request = ReServeRequest.empty();
      final response = ReServeResponse(
        bytes: Uint8List.fromList(
          utf8.encode('<a href="http://localhost:8080/home">Home</a>'),
        ),
        headers: [ReServeHeader(key: 'content-type', value: 'text/html')],
        statusCode: 200,
      );

      final result = interceptor.interceptResponse(request, response);
      expect(
        utf8.decode(result.bytes),
        '<a href="http://example.com/home">Home</a>',
      );
    });

    test('replaces text in application/javascript body', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = ReplaceBodyResponseInterceptor(
        config: config,
        from: 'const API = "http://dev"',
        replace: 'const API = "http://prod"',
      );

      final request = ReServeRequest.empty();
      final response = ReServeResponse(
        bytes: Uint8List.fromList(
          utf8.encode('const API = "http://dev"; console.log(API);'),
        ),
        headers: [
          ReServeHeader(key: 'content-type', value: 'application/javascript'),
        ],
        statusCode: 200,
      );

      final result = interceptor.interceptResponse(request, response);
      expect(
        utf8.decode(result.bytes),
        'const API = "http://prod"; console.log(API);',
      );
    });

    test('leaves non-text body untouched', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = ReplaceBodyResponseInterceptor(
        config: config,
        from: 'ABC',
        replace: 'XYZ',
      );

      final rawBytes = Uint8List.fromList([65, 66, 67, 0, 1]); // ABC\0\1
      final request = ReServeRequest.empty();
      final response = ReServeResponse(
        bytes: rawBytes,
        headers: [
          ReServeHeader(key: 'content-type', value: 'application/octet-stream'),
        ],
        statusCode: 200,
      );

      final result = interceptor.interceptResponse(request, response);
      expect(result.bytes, rawBytes);
    });
  });
}
