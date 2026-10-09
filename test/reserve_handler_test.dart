import 'dart:convert';
import 'dart:io';

import 'package:file/memory.dart';
import 'package:reserve/reserve.dart';
import 'package:reserve/src/reserve_handler.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

void main() {
  group('ReServeHandler', () {
    test('path normalization and handles', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final route1 = ReServeRoute(path: '/api/v1');
      final handler1 = ReServeHandler(config: config, route: route1);
      expect(handler1.path, 'api/v1/');
      expect(handler1.handles('api/v1/users'), isTrue);
      expect(handler1.handles('api/v2/users'), isFalse);

      final route2 = ReServeRoute(path: '/');
      final handler2 = ReServeHandler(config: config, route: route2);
      expect(handler2.path, '');
      expect(handler2.handles('any/path'), isTrue);

      final route3 = ReServeRoute(path: 'webhook/');
      final handler3 = ReServeHandler(config: config, route: route3);
      expect(handler3.path, 'webhook/');
      expect(handler3.handles('webhook/event'), isTrue);
    });

    test(
      'process returns immediately if request interceptor returns response',
      () async {
        final fs = MemoryFileSystem();
        fs.file('/app/mock.json')
          ..createSync(recursive: true)
          ..writeAsStringSync('{"mock": true}');

        final config = ServerConfig(
          fileSystem: fs,
          path: '/app/test.yaml',
          routes: const {},
        );

        final route = ReServeRoute(
          path: '/mock',
          interceptors: [
            InterceptorData(
              type: InterceptorType.setResponse,
              params: {
                'body': 'mock.json',
                'headers': {'content-type': 'application/json'},
                'status-code': 200,
              },
            ),
          ],
        );

        final handler = ReServeHandler(config: config, route: route);
        final request = shelf.Request(
          'GET',
          Uri.parse('http://localhost:5433/mock'),
        );

        final response = await handler.process(request);
        expect(response.statusCode, 200);
        expect(response.headers['content-type'], 'application/json');
        expect(await response.readAsString(), '{"mock": true}');
      },
    );

    test('process returns 500 when no interceptor defines response and no redirect in route', () async {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final route = ReServeRoute(path: '/empty');
      final handler = ReServeHandler(config: config, route: route);
      final request = shelf.Request(
        'GET',
        Uri.parse('http://localhost:5433/empty'),
      );

      final response = await handler.process(request);
      expect(response.statusCode, 500);
      expect(
        await response.readAsString(),
        contains(
          'No response defined by interceptors and no redirect defined in route',
        ),
      );
    });

    test('process forwards request to target redirect server and applies response interceptors', () async {
      // Create a temporary backend HTTP server to receive the forwarded request
      final backend = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      backend.listen((req) async {
        final body = await utf8.decodeStream(req);
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.json;
        req.response.headers.add('x-backend-header', 'from-backend');
        req.response.write(
          json.encode({
            'path': req.uri.path,
            'query': req.uri.query,
            'body': body,
            'method': req.method,
            'host': req.headers.value('host'),
          }),
        );
        await req.response.close();
      });

      try {
        final config = ServerConfig(path: 'test.yaml', routes: const {});

        final route = ReServeRoute(
          path: '/api',
          redirect: Uri.parse(
            'http://${backend.address.host}:${backend.port}/target',
          ),
          interceptors: [
            InterceptorData(
              type: InterceptorType.replaceBody,
              params: {'from': 'from-backend', 'replace': 'intercepted'},
            ),
          ],
        );

        final handler = ReServeHandler(config: config, route: route);

        final request = shelf.Request(
          'POST',
          Uri.parse('http://localhost:5433/api/users?active=true'),
          body: '{"name":"Alice"}',
        );

        final response = await handler.process(request);
        expect(response.statusCode, 200);

        final responseJson = json.decode(await response.readAsString());
        expect(responseJson['path'], '/target/users');
        expect(responseJson['query'], 'active=true');
        expect(responseJson['method'], 'POST');
        expect(responseJson['body'], '{"name":"Alice"}');
        // host header was set by default interceptor to backend host:port
        expect(responseJson['host'], '${backend.address.host}:${backend.port}');
      } finally {
        await backend.close();
      }
    });

    test('process handles unsupported HTTP method gracefully', () async {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final route = ReServeRoute(
        path: '/unsupported',
        redirect: Uri.parse('http://localhost:9999/'),
      );

      final handler = ReServeHandler(config: config, route: route);
      final request = shelf.Request(
        'CONNECT',
        Uri.parse('http://localhost:5433/unsupported'),
      );

      final response = await handler.process(request);
      expect(response.statusCode, 500);
      expect(
        await response.readAsString(),
        contains('Unsupported method: CONNECT'),
      );
    });
  });
}
