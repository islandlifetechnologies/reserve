import 'dart:convert';

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:logging/logging.dart';
import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  hierarchicalLoggingEnabled = true;
  late final FileSystem fs;
  setUpAll(() {
    fs = MemoryFileSystem();
    fs.file('output.html')
      ..createSync(recursive: true)
      ..writeAsString(
        r'${vars.greeting}: ${vars.config.firstName} ${vars.config.lastName}!',
      );
    fs.file('output.mustache.html')
      ..createSync(recursive: true)
      ..writeAsString(r'''
{{vars.greeting}}: {{vars.config.firstName}} {{vars.config.lastName}}!
function foo() {
  const bar = 'bar';
  console.log(`${bar}`);
}
''');
  });

  tearDownAll(() {});

  test('set-response', () async {
    final config = ServerConfig(
      fileSystem: fs,
      path: 'reserve.yaml',
      routes: const {},
      vars: {
        'greeting': 'Hello',
        'config': {'firstName': 'Mickey', 'lastName': 'Mouse'},
      },
    );

    final interceptor = SetResponseRequestInterceptor(
      body: 'output.html',
      config: config,
      headers: {'content-type': 'text/html'},
    );

    final (_, response) = await interceptor.interceptRequest(
      ReServeRequest.empty(),
    );

    expect(utf8.decode(response!.bytes), 'Hello: Mickey Mouse!');
    expect(response.headers, {'content-type': 'text/html'});
    expect(response.statusCode, 200);
  });

  test('set-response: mustache', () async {
    final config = ServerConfig(
      fileSystem: fs,
      path: 'reserve.yaml',
      routes: const {},
      vars: {
        'greeting': 'Hello',
        'config': {'firstName': 'Mickey', 'lastName': 'Mouse'},
      },
    );

    final interceptor = SetResponseRequestInterceptor(
      body: 'output.mustache.html',
      config: config,
      headers: {'content-type': 'text/html'},
      templateSyntax: 'mustache',
    );

    final (_, response) = await interceptor.interceptRequest(
      ReServeRequest.empty(),
    );

    expect(utf8.decode(response!.bytes), r'''
Hello: Mickey Mouse!
function foo() {
  const bar = 'bar';
  console.log(`${bar}`);
}
''');
    expect(response.headers, {'content-type': 'text/html'});
    expect(response.statusCode, 200);
  });

  test('set-response: binary file and status code', () async {
    final binaryBytes = [0, 1, 2, 3, 255];
    fs.file('image.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(binaryBytes);

    final config = ServerConfig(
      fileSystem: fs,
      path: 'reserve.yaml',
      routes: const {},
    );

    final interceptor = SetResponseRequestInterceptor.builder(
      config: config,
      params: {
        'body': 'image.png',
        'headers': {'content-type': 'image/png'},
        'status-code': 404,
      },
    );

    final (_, response) = await interceptor.interceptRequest(
      ReServeRequest.empty(),
    );

    expect(response!.bytes, binaryBytes);
    expect(response.headers['content-type'], 'image/png');
    expect(response.statusCode, 404);
  });

  group('folder resolution relative to config', () {
    test('body in nested subfolder relative to config', () async {
      fs.file('/app/config/templates/nested.html')
        ..createSync(recursive: true)
        ..writeAsStringSync('<span>Nested</span>');

      final config = ServerConfig(
        fileSystem: fs,
        path: '/app/config/reserve.yaml',
        routes: const {},
      );

      final interceptor = SetResponseRequestInterceptor(
        body: 'templates/nested.html',
        config: config,
        headers: {'content-type': 'text/html'},
      );

      final (_, response) = await interceptor.interceptRequest(
        ReServeRequest.empty(),
      );

      expect(utf8.decode(response!.bytes), '<span>Nested</span>');
    });

    test('body in parent / sibling folder relative to config', () async {
      fs.directory('/app/config/sub').createSync(recursive: true);
      fs.file('/app/public/index.html')
        ..createSync(recursive: true)
        ..writeAsStringSync('<div>Parent/Sibling</div>');

      final config = ServerConfig(
        fileSystem: fs,
        path: '/app/config/sub/reserve.yaml',
        routes: const {},
      );

      final interceptor = SetResponseRequestInterceptor(
        body: '../../public/index.html',
        config: config,
        headers: {'content-type': 'text/html'},
      );

      final (_, response) = await interceptor.interceptRequest(
        ReServeRequest.empty(),
      );

      expect(utf8.decode(response!.bytes), '<div>Parent/Sibling</div>');
    });

    test('body using absolute path from root', () async {
      fs.directory('/var/www/site').createSync(recursive: true);
      fs.file('/shared/assets/header.html')
        ..createSync(recursive: true)
        ..writeAsStringSync('<header>Header</header>');

      final config = ServerConfig(
        fileSystem: fs,
        path: '/var/www/site/reserve.yaml',
        routes: const {},
      );

      final interceptor = SetResponseRequestInterceptor(
        body: '/shared/assets/header.html',
        config: config,
        headers: {'content-type': 'text/html'},
      );

      final (_, response) = await interceptor.interceptRequest(
        ReServeRequest.empty(),
      );

      expect(utf8.decode(response!.bytes), '<header>Header</header>');
    });
  });
}
