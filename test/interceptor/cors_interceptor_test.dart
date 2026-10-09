import 'dart:typed_data';

import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  group('CorsInterceptor', () {
    test('builder initializes defaults', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = CorsInterceptor.builder(config: config);
      expect(interceptor.credentials, isFalse);
      expect(interceptor.additionalHeaders, isEmpty);
      expect(interceptor.exposeHeaders, isEmpty);
      expect(interceptor.headers, contains('accept'));
      expect(interceptor.headers, contains('content-type'));
      expect(interceptor.maxAge, 86400);
      expect(interceptor.methods, contains('GET'));
      expect(interceptor.methods, contains('POST'));
    });

    test('builder initializes custom parameters', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = CorsInterceptor.builder(
        config: config,
        params: {
          'allow-credentials': true,
          'additional-headers': ['x-custom-1'],
          'expose-headers': ['x-exposed'],
          'allow-headers': ['authorization', 'content-type'],
          'max-age': 3600,
          'allow-methods': ['GET', 'POST'],
        },
      );

      expect(interceptor.credentials, isTrue);
      expect(interceptor.additionalHeaders, ['x-custom-1']);
      expect(interceptor.exposeHeaders, ['x-exposed']);
      expect(interceptor.headers, ['authorization', 'content-type']);
      expect(interceptor.maxAge, 3600);
      expect(interceptor.methods, ['GET', 'POST']);
    });

    test('OPTIONS request with origin returns preflight CORS response', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = CorsInterceptor(
        additionalHeaders: ['x-requested-with'],
        config: config,
        credentials: true,
        exposeHeaders: ['x-token'],
        headers: ['content-type'],
        maxAge: 600,
        methods: ['GET', 'POST', 'OPTIONS'],
      );

      final request = ReServeRequest(
        bytes: Uint8List(0),
        headers: [ReServeHeader(key: 'origin', value: 'https://example.com')],
        method: 'OPTIONS',
        uri: Uri.parse('http://localhost/api'),
      );

      final (req, res) = interceptor.interceptRequest(request);
      expect(req, request);
      expect(res, isNotNull);
      expect(res!.statusCode, 200);
      expect(res.headers['access-control-allow-origin'], 'https://example.com');
      expect(res.headers['access-control-allow-credentials'], 'true');
      expect(
        res.headers['access-control-allow-headers'],
        'content-type,x-requested-with',
      );
      expect(res.headers['access-control-allow-methods'], 'GET,POST,OPTIONS');
      expect(res.headers['access-control-expose-headers'], 'x-token');
      expect(res.headers['access-control-max-age'], '600');
    });

    test('OPTIONS request without origin does not return response', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = CorsInterceptor.builder(config: config);
      final request = ReServeRequest(
        bytes: Uint8List(0),
        headers: const [],
        method: 'OPTIONS',
        uri: Uri.parse('http://localhost/api'),
      );

      final (_, res) = interceptor.interceptRequest(request);
      expect(res, isNull);
    });

    test(
      'GET request with origin does not return response on interceptRequest',
      () {
        final config = ServerConfig(path: 'test.yaml', routes: const {});

        final interceptor = CorsInterceptor.builder(config: config);
        final request = ReServeRequest(
          bytes: Uint8List(0),
          headers: [ReServeHeader(key: 'origin', value: 'https://example.com')],
          method: 'GET',
          uri: Uri.parse('http://localhost/api'),
        );

        final (_, res) = interceptor.interceptRequest(request);
        expect(res, isNull);
      },
    );

    test('interceptResponse adds CORS headers when origin is present and replaces existing ones', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = CorsInterceptor.builder(config: config);
      final request = ReServeRequest(
        bytes: Uint8List(0),
        headers: [ReServeHeader(key: 'origin', value: 'https://client.app')],
        method: 'GET',
        uri: Uri.parse('http://localhost/api'),
      );

      final originalResponse = ReServeResponse(
        bytes: Uint8List(0),
        headers: [
          ReServeHeader(key: 'content-type', value: 'application/json'),
          ReServeHeader(
            key: 'access-control-allow-origin',
            value: 'old-origin',
          ),
        ],
        statusCode: 200,
      );

      final result = interceptor.interceptResponse(request, originalResponse);
      expect(
        result.headers['access-control-allow-origin'],
        'https://client.app',
      );
      expect(result.headers['content-type'], 'application/json');
      expect(result.headers['access-control-allow-methods'], contains('GET'));
    });

    test(
      'interceptResponse leaves response untouched when origin is absent',
      () {
        final config = ServerConfig(path: 'test.yaml', routes: const {});

        final interceptor = CorsInterceptor.builder(config: config);
        final request = ReServeRequest.empty();
        final originalResponse = ReServeResponse(
          bytes: Uint8List(0),
          headers: [
            ReServeHeader(key: 'content-type', value: 'application/json'),
          ],
          statusCode: 200,
        );

        final result = interceptor.interceptResponse(request, originalResponse);
        expect(result.headers['content-type'], 'application/json');
        expect(result.headers['access-control-allow-origin'], isNull);
      },
    );
  });
}
