import 'dart:typed_data';

import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  group('RemoveHeadersInterceptor', () {
    test('builder initializes from params', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = RemoveHeadersInterceptor.builder(
        config: config,
        params: {
          'headers': ['X-Secret', 'Authorization'],
          'request': false,
          'response': true,
        },
      );

      final req = ReServeRequest(
        bytes: Uint8List(0),
        headers: [
          ReServeHeader(key: 'x-secret', value: '123'),
          ReServeHeader(key: 'accept', value: 'text/html'),
        ],
        method: 'GET',
        uri: Uri(),
      );

      // request is false, so request should not be altered
      final (interceptedReq, _) = interceptor.interceptRequest(req);
      expect(interceptedReq.headers['x-secret'], '123');

      // response is true, so response headers should be stripped
      final res = ReServeResponse(
        bytes: Uint8List(0),
        headers: [
          ReServeHeader(key: 'x-secret', value: '123'),
          ReServeHeader(key: 'content-type', value: 'text/plain'),
        ],
        statusCode: 200,
      );

      final interceptedRes = interceptor.interceptResponse(req, res);
      expect(interceptedRes.headers['x-secret'], isNull);
      expect(interceptedRes.headers['content-type'], 'text/plain');
    });

    test('removes headers from request when request flag is true', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = RemoveHeadersInterceptor(
        config: config,
        headers: ['X-Remove-Me', 'cookie'],
        request: true,
      );

      final req = ReServeRequest(
        bytes: Uint8List(0),
        headers: [
          ReServeHeader(key: 'x-remove-me', value: 'val1'),
          ReServeHeader(key: 'cookie', value: 'c=1'),
          ReServeHeader(key: 'keep-me', value: 'val2'),
        ],
        method: 'GET',
        uri: Uri(),
      );

      final (result, res) = interceptor.interceptRequest(req);
      expect(res, isNull);
      expect(result.headers['x-remove-me'], isNull);
      expect(result.headers['cookie'], isNull);
      expect(result.headers['keep-me'], 'val2');
    });

    test('leaves response untouched when response flag is false', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = RemoveHeadersInterceptor(
        config: config,
        headers: ['content-type'],
        response: false,
      );

      final req = ReServeRequest.empty();
      final res = ReServeResponse(
        bytes: Uint8List(0),
        headers: [ReServeHeader(key: 'content-type', value: 'text/html')],
        statusCode: 200,
      );

      final result = interceptor.interceptResponse(req, res);
      expect(result.headers['content-type'], 'text/html');
    });
  });
}
