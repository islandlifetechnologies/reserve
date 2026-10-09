import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  group('ReServeResponse', () {
    test('constructs with given values', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final header = ReServeHeader(key: 'x-resp', value: 'resp-val');
      final time = DateTime.utc(2025, 2, 1);
      final response = ReServeResponse(
        bytes: bytes,
        headers: [header],
        statusCode: 201,
        timestamp: time,
      );

      expect(response.bytes, bytes);
      expect(response.headers['x-resp'], 'resp-val');
      expect(response.statusCode, 201);
      expect(response.timestamp, time);
    });

    test('empty factory creates default 200 response', () {
      final empty = ReServeResponse.empty();

      expect(empty.bytes, isEmpty);
      expect(empty.headers.all, isEmpty);
      expect(empty.statusCode, 200);
      expect(empty.timestamp, isNotNull);
    });

    test('copyWith clones or replaces fields', () {
      final res = ReServeResponse(
        bytes: Uint8List.fromList([1]),
        headers: [ReServeHeader(key: 'k1', value: 'v1')],
        statusCode: 200,
      );

      final newBytes = Uint8List.fromList([2, 3]);
      final newHeaders = [ReServeHeader(key: 'k2', value: 'v2')];
      final newTime = DateTime.utc(2025, 5, 5);

      final copy1 = res.copyWith(
        bytes: newBytes,
        headers: newHeaders,
        statusCode: 404,
        timestamp: newTime,
      );

      expect(copy1.bytes, newBytes);
      expect(copy1.headers['k2'], 'v2');
      expect(copy1.statusCode, 404);
      expect(copy1.timestamp, newTime);

      final copy2 = res.copyWith();
      expect(copy2.bytes, res.bytes);
      expect(copy2.headers['k1'], 'v1');
      expect(copy2.statusCode, 200);
    });

    test('toShelfResponse maps fields correctly', () async {
      final body = utf8.encode('Hello shelf');
      final res = ReServeResponse(
        bytes: Uint8List.fromList(body),
        headers: [
          ReServeHeader(key: 'content-type', value: 'text/plain'),
          ReServeHeader(key: 'x-id', value: '123'),
        ],
        statusCode: 202,
      );

      final shelfRes = res.toShelfResponse();
      expect(shelfRes.statusCode, 202);
      expect(await shelfRes.readAsString(), 'Hello shelf');
      expect(shelfRes.headers['content-type'], startsWith('text/plain'));
      expect(shelfRes.headers['x-id'], '123');
    });

    test('fromHttpResponse parses normal headers', () {
      final httpResponse = http.Response(
        'OK Body',
        200,
        headers: {'content-type': 'text/plain', 'x-header': 'value'},
      );

      final res = ReServeResponse.fromHttpResponse(httpResponse);
      expect(res.statusCode, 200);
      expect(utf8.decode(res.bytes), 'OK Body');
      expect(res.headers['content-type'], 'text/plain');
      expect(res.headers['x-header'], 'value');
    });

    test('fromHttpResponse handles multiple set-cookie with comma in expires', () {
      // In http package, multiple set-cookie headers might be joined with comma
      final setCookieHeader =
          'cookie1=val1; Expires=Thu, 19 Aug 2027 21:06:54 GMT; Path=/, '
          'cookie2=val2; Secure; HttpOnly';

      final httpResponse = http.Response(
        '',
        200,
        headers: {'set-cookie': setCookieHeader},
      );

      final res = ReServeResponse.fromHttpResponse(httpResponse);
      final setCookieHeaders = res.headers.all
          .where((h) => h.key == 'set-cookie')
          .toList();

      expect(setCookieHeaders.length, 2);
      expect(setCookieHeaders[0].value, contains('cookie1=val1'));
      expect(
        setCookieHeaders[0].value,
        contains('Expires=Thu, 19 Aug 2027 21:06:54 GMT'),
      );
      expect(setCookieHeaders[1].value, contains('cookie2=val2'));
      expect(setCookieHeaders[1].value, contains('Secure'));
    });
  });
}
