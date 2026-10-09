import 'package:file/memory.dart';
import 'package:logging/logging.dart';
import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  hierarchicalLoggingEnabled = true;
  test('config', () {
    final yml = r'''
vars: 
  api-host: api.example.com
  api-server: https://api.example.com
  host: localhost
  port: 5433
  web-server: https://www.example.com
host: ${vars.host}
port: ${vars.port}
origin: http://${vars.host}:8888
proxy: ${vars.host}:8000
routes:
  /api/:
    redirect: ${vars['api-server']}/api/
    interceptors:
      - type: replace-headers
        with:
          from: ${vars['api-server']}
          replace: http://${vars.host}
  
  /:
    redirect: ${vars['web-server']}/
    interceptors:
      - type: replace-body
        with:
          from: ${vars['api-server']}
          replace: http://${vars.host}:${vars.port}

''';

    final config = ServerConfig.fromString(yml, path: './pubspec.yaml');

    expect(config.host, 'localhost');
    expect(config.port, 5433);
    expect(config.origin.toString(), 'http://localhost:8888');
    expect(config.proxy, 'localhost:8000');

    final api = config.routes['/api/']!;
    expect(api.redirect.toString(), 'https://api.example.com/api/');
    expect(api.interceptors[0].params['from'], 'https://api.example.com');
    expect(api.interceptors[0].params['replace'], 'http://localhost');

    final root = config.routes['/']!;
    expect(root.redirect.toString(), 'https://www.example.com/');
    expect(root.interceptors[0].params['from'], 'https://api.example.com');
    expect(root.interceptors[0].params['replace'], 'http://localhost:5433');
  });

  group('template', () {
    late MemoryFileSystem fs;
    setUpAll(() {
      fs = MemoryFileSystem();
      fs.file('contents/config.yaml')
        ..createSync(recursive: true)
        ..writeAsString('''
keyNotForApi: definitely-not-a-key-for-an-api
apiServer: https://api.example.com
webServer: https://www.example.com
''');
    });

    test('vars template', () {
      final yml = r'''
vars: 
  config: ${yaon.decode(File('contents/config.yaml').readAsStringSync())}
routes:
  /api/:
    redirect: ${vars.config.apiServer}/api/
    interceptors:
      - type: set-headers
        with:
          x-key: ${vars.config.keyNotForApi}
  
  /:
    redirect: ${vars.config.webServer}/
''';

      final config = ServerConfig.fromString(
        yml,
        fileSystem: fs,
        path: './pubspec.yaml',
      );

      final api = config.routes['/api/']!;
      expect(api.redirect.toString(), 'https://api.example.com/api/');
      expect(
        api.interceptors[0].params['x-key'],
        'definitely-not-a-key-for-an-api',
      );

      expect(
        config.routes['/']!.redirect.toString(),
        'https://www.example.com/',
      );
    });
  });

  group('entrypoint', () {
    test('uses origin when provided', () {
      final config = ServerConfig(
        host: 'myhost.com',
        origin: Uri.parse('http://custom-origin.com:9000'),
        path: 'test.yaml',
        port: 8080,
        routes: const {},
      );

      expect(config.entrypoint, 'http://custom-origin.com:9000');
    });

    test('formats http without port for port 80', () {
      final config = ServerConfig(
        host: 'myhost.com',
        path: 'test.yaml',
        port: 80,
        routes: const {},
      );

      expect(config.entrypoint, 'http://myhost.com');
    });

    test('formats https without port for port 443', () {
      final config = ServerConfig(
        host: 'myhost.com',
        https: SslData(certChain: 'cert', privateKey: 'key'),
        path: 'test.yaml',
        port: 443,
        routes: const {},
      );

      expect(config.entrypoint, 'https://myhost.com');
    });

    test('includes non-standard port in entrypoint', () {
      final config = ServerConfig(
        host: 'myhost.com',
        path: 'test.yaml',
        port: 5433,
        routes: const {},
      );

      expect(config.entrypoint, 'http://myhost.com:5433');
    });
  });

  group('client', () {
    test('creates client without proxy', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      expect(config.client, isNotNull);
    });

    test('creates client with proxy configured', () {
      final config = ServerConfig(
        path: 'test.yaml',
        proxy: 'localhost:8080',
        routes: const {},
      );

      expect(config.client, isNotNull);
    });
  });

  group('fromFile', () {
    test('loads config from file with and without prefix', () {
      final fs = MemoryFileSystem();
      final file = fs.file('/app/config.yaml')
        ..createSync(recursive: true)
        ..writeAsString('''
my-root:
  host: custom.domain
  port: 8000
  routes:
    /test:
      redirect: https://api.test.com
''');

      final configWithPrefix = ServerConfig.fromFile(file, prefix: 'my-root');
      expect(configWithPrefix.path, file.absolute.path);
      expect(configWithPrefix.host, 'custom.domain');
      expect(configWithPrefix.port, 8000);
      expect(
        configWithPrefix.routes['/test']?.redirect.toString(),
        'https://api.test.com',
      );
      expect(configWithPrefix.path, file.absolute.path);

      final simpleFile = fs.file('/app/simple.yaml')
        ..createSync(recursive: true)
        ..writeAsString('''
host: direct.domain
port: 9000
routes:
  /direct:
    redirect: https://direct.test.com
''');

      final configWithoutPrefix = ServerConfig.fromFile(simpleFile);
      expect(configWithoutPrefix.path, simpleFile.absolute.path);
      expect(configWithoutPrefix.host, 'direct.domain');
      expect(configWithoutPrefix.port, 9000);
      expect(
        configWithoutPrefix.routes['/direct']?.redirect.toString(),
        'https://direct.test.com',
      );
    });
  });
}
