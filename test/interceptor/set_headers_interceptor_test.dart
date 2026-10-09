import 'dart:typed_data';

import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  group('SetHeadersInterceptor', () {
    test('builder initializes from params', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = SetHeadersInterceptor.builder(
        config: config,
        params: {
          'headers': {'X-Custom': '123', 'Host': 'newhost.com'},
          'request': true,
          'response': false,
        },
      );

      expect(interceptor.type, InterceptorType.setHeaders);

      final req = ReServeRequest(
        bytes: Uint8List(0),
        headers: [
          ReServeHeader(key: 'host', value: 'oldhost.com'),
          ReServeHeader(key: 'accept', value: '*/*'),
        ],
        method: 'GET',
        uri: Uri(),
      );

      // request is true, so host is overwritten and x-custom is added
      final (interceptedReq, _) = interceptor.interceptRequest(req);
      expect(interceptedReq.headers['host'], 'newhost.com');
      expect(interceptedReq.headers['x-custom'], '123');
      expect(interceptedReq.headers['accept'], '*/*');

      // response is false, so untouched
      final res = ReServeResponse(
        bytes: Uint8List(0),
        headers: [ReServeHeader(key: 'host', value: 'oldhost.com')],
        statusCode: 200,
      );

      final interceptedRes = interceptor.interceptResponse(req, res);
      expect(interceptedRes.headers['host'], 'oldhost.com');
      expect(interceptedRes.headers['x-custom'], isNull);
    });

    test('sets headers on response when response flag is true', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = SetHeadersInterceptor(
        config: config,
        headers: {
          'cache-control': 'no-cache, no-store',
          'x-frame-options': 'DENY',
        },
        response: true,
      );

      final req = ReServeRequest.empty();
      final res = ReServeResponse(
        bytes: Uint8List(0),
        headers: [
          ReServeHeader(key: 'cache-control', value: 'max-age=3600'),
          ReServeHeader(key: 'content-type', value: 'text/html'),
        ],
        statusCode: 200,
      );

      final result = interceptor.interceptResponse(req, res);
      expect(result.headers['cache-control'], 'no-cache, no-store');
      expect(result.headers['x-frame-options'], 'DENY');
      expect(result.headers['content-type'], 'text/html');
    });
  });
}
