import 'package:file/memory.dart';
import 'package:logging/logging.dart';
import 'package:reserve/reserve.dart';
import 'package:template_expressions/template_expressions.dart';
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

    final config = ServerConfig.fromString(yml);

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
    setUpAll(() {
      final fs = MemoryFileSystem();
      fs.file('contents/config.yaml')
        ..createSync(recursive: true)
        ..writeAsString('''
keyNotForApi: definitely-not-a-key-for-an-api
apiServer: https://api.example.com
webServer: https://www.example.com
''');
      FileSystemFunctions.fileSystemOverride = fs;
    });

    tearDownAll(() {
      FileSystemFunctions.fileSystemOverride = null;
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

      final config = ServerConfig.fromString(yml);

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
}
