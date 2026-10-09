import 'dart:convert';
import 'dart:typed_data';

import 'package:reserve/reserve.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

void main() {
  group('ReServeRequest', () {
    test('constructs with given values and uppercases method', () {
      final uri = Uri.parse('http://example.com/test');
      final bytes = Uint8List.fromList([1, 2, 3]);
      final header = ReServeHeader(key: 'X-Custom', value: 'Value');
      final request = ReServeRequest(
        bytes: bytes,
        headers: [header],
        method: 'post',
        uri: uri,
      );

      expect(request.bytes, bytes);
      expect(request.headers['x-custom'], 'Value');
      expect(request.method, 'POST');
      expect(request.uri, uri);
      expect(request.path, '/test');
      expect(request.timestamp, isNotNull);
    });

    test('empty factory creates default GET request', () {
      final empty = ReServeRequest.empty();

      expect(empty.bytes, isEmpty);
      expect(empty.headers.all, isEmpty);
      expect(empty.method, 'GET');
      expect(empty.uri, Uri());
      expect(empty.path, '/');
    });

    test('path ensures leading slash', () {
      final req1 = ReServeRequest(
        bytes: Uint8List(0),
        headers: const [],
        method: 'GET',
        uri: Uri.parse('http://localhost:8080/foo/bar'),
      );
      expect(req1.path, '/foo/bar');

      final req2 = ReServeRequest(
        bytes: Uint8List(0),
        headers: const [],
        method: 'GET',
        uri: Uri.parse('http://localhost:8080'),
      );
      expect(req2.path, '/');
    });

    test('copyWith clones or replaces fields', () {
      final req = ReServeRequest(
        bytes: Uint8List.fromList([1]),
        headers: [ReServeHeader(key: 'k1', value: 'v1')],
        method: 'GET',
        uri: Uri.parse('http://example.com/one'),
      );

      final newBytes = Uint8List.fromList([2, 3]);
      final newHeaders = [ReServeHeader(key: 'k2', value: 'v2')];
      final newUri = Uri.parse('http://example.com/two');
      final newTime = DateTime.utc(2025, 1, 1);

      final copy1 = req.copyWith(
        bytes: newBytes,
        headers: newHeaders,
        method: 'put',
        timestamp: newTime,
        uri: newUri,
      );

      expect(copy1.bytes, newBytes);
      expect(copy1.headers['k2'], 'v2');
      expect(copy1.method, 'PUT');
      expect(copy1.timestamp, newTime);
      expect(copy1.uri, newUri);

      // copy with nothing changed
      final copy2 = req.copyWith();
      expect(copy2.bytes, req.bytes);
      expect(copy2.headers['k1'], 'v1');
      expect(copy2.method, req.method);
      expect(copy2.uri, req.uri);
    });

    test('toHttpRequest converts to http.Request', () {
      final uri = Uri.parse('http://example.com/api/test');
      final body = utf8.encode('test-body');
      final request = ReServeRequest(
        bytes: Uint8List.fromList(body),
        headers: [
          ReServeHeader(key: 'authorization', value: 'Bearer token'),
          ReServeHeader(key: 'content-type', value: 'text/plain'),
        ],
        method: 'POST',
        uri: uri,
      );

      final httpReq = request.toHttpRequest();
      expect(httpReq.method, 'POST');
      expect(httpReq.url, uri);
      expect(httpReq.bodyBytes, body);
      expect(httpReq.headers['authorization'], 'Bearer token');
      expect(httpReq.headers['content-type'], startsWith('text/plain'));
    });

    test('fromShelfRequest parses shelf.Request with stream body', () async {
      final shelfReq = shelf.Request(
        'POST',
        Uri.parse('http://example.com/api/shelf'),
        headers: {'X-Custom': 'Val', 'accept': 'application/json'},
        body: 'shelf payload',
      );

      final reServeReq = await ReServeRequest.fromShelfRequest(shelfReq);

      expect(reServeReq.method, 'POST');
      expect(reServeReq.uri, shelfReq.url);
      expect(utf8.decode(reServeReq.bytes), 'shelf payload');
      expect(reServeReq.headers['x-custom'], 'Val');
      expect(reServeReq.headers['accept'], 'application/json');
    });
  });
}
