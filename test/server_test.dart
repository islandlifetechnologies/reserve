import 'dart:io';

import 'package:file/memory.dart';
import 'package:http/http.dart' as http;
import 'package:reserve/reserve.dart';
import 'package:reserve/src/server.dart';
import 'package:test/test.dart';

void main() {
  group('Server', () {
    test('starts, routes requests, handles 404, and stops', () async {
      // Find a free port
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;
      await socket.close();

      final fs = MemoryFileSystem();
      fs.file('/app/index.html')
        ..createSync(recursive: true)
        ..writeAsStringSync('<h1>Hello Server</h1>');

      final config = ServerConfig(
        fileSystem: fs,
        host: '127.0.0.1',
        path: '/app/reserve.yaml',
        port: port,
        routes: {
          '/hello': ReServeRoute(
            interceptors: [
              InterceptorData(
                type: InterceptorType.setResponse,
                params: {
                  'body': 'index.html',
                  'headers': {'content-type': 'text/html'},
                  'status-code': 200,
                },
              ),
            ],
          ),
        },
      );

      final server = Server(config: config);
      await server.start();

      try {
        // Request to matching route
        final response = await http.get(
          Uri.parse('http://127.0.0.1:$port/hello'),
        );
        expect(response.statusCode, 200);
        expect(response.body, '<h1>Hello Server</h1>');
        expect(response.headers['content-type'], startsWith('text/html'));

        // Request to non-matching route
        final notFoundResponse = await http.get(
          Uri.parse('http://127.0.0.1:$port/notfound'),
        );
        expect(notFoundResponse.statusCode, 404);
        expect(
          notFoundResponse.body,
          contains('No route exists for: notfound/'),
        );
      } finally {
        await server.stop();
      }
    });
  });
}
