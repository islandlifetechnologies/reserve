import 'dart:typed_data';

import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  group('ReplaceHeadersInterceptor', () {
    test('builder initializes from params', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = ReplaceHeadersInterceptor.builder(
        config: config,
        params: {
          'from': 'http://internal',
          'replace': 'https://external',
          'request': false,
          'response': true,
        },
      );

      expect(interceptor.type, InterceptorType.replaceHeaders);

      final req = ReServeRequest(
        bytes: Uint8List(0),
        headers: [ReServeHeader(key: 'referer', value: 'http://internal/page')],
        method: 'GET',
        uri: Uri(),
      );

      // request is false, so no changes
      final (interceptedReq, _) = interceptor.interceptRequest(req);
      expect(interceptedReq.headers['referer'], 'http://internal/page');

      // response is true, so header replaced
      final res = ReServeResponse(
        bytes: Uint8List(0),
        headers: [
          ReServeHeader(key: 'location', value: 'http://internal/login'),
        ],
        statusCode: 302,
      );

      final interceptedRes = interceptor.interceptResponse(req, res);
      expect(interceptedRes.headers['location'], 'https://external/login');
    });

    test('replaces headers in request when request is true', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = ReplaceHeadersInterceptor(
        config: config,
        from: 'staging',
        replace: 'production',
        request: true,
      );

      final req = ReServeRequest(
        bytes: Uint8List(0),
        headers: [ReServeHeader(key: 'x-host', value: 'staging.domain.com')],
        method: 'GET',
        uri: Uri(),
      );

      final (result, res) = interceptor.interceptRequest(req);
      expect(res, isNull);
      expect(result.headers['x-host'], 'production.domain.com');
    });

    test('leaves response untouched when response is false', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = ReplaceHeadersInterceptor(
        config: config,
        from: 'staging',
        replace: 'production',
        response: false,
      );

      final req = ReServeRequest.empty();
      final res = ReServeResponse(
        bytes: Uint8List(0),
        headers: [ReServeHeader(key: 'x-host', value: 'staging.domain.com')],
        statusCode: 200,
      );

      final result = interceptor.interceptResponse(req, res);
      expect(result.headers['x-host'], 'staging.domain.com');
    });
  });
}
