import 'package:logging/logging.dart';
import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  group('ReServeRoute', () {
    test('path setter configures logger and path', () {
      final route = ReServeRoute(
        log: ReServeLoggerLevel.warning,
        redirect: Uri.parse('http://example.com'),
      );

      route.path = '/api';
      expect(route.path, '/api');
      expect(route.logger.name, '/api');
      expect(route.logger.level, Level.WARNING);
    });

    test('constructor with path initializes path', () {
      final route = ReServeRoute(
        log: ReServeLoggerLevel.info,
        path: '/v1',
        redirect: Uri.parse('http://example.com/v1'),
      );

      expect(route.path, '/v1');
      expect(route.logger.name, '/v1');
      expect(route.logger.level, Level.INFO);
    });

    test('fromJson deserializes route properties', () {
      final json = {
        'log': 'severe',
        'name': 'API Route',
        'redirect': 'https://api.example.com',
        'interceptors': [
          {
            'type': 'remove-headers',
            'with': {
              'headers': ['x-test'],
            },
          },
        ],
      };

      final route = ReServeRoute.fromJson(json);
      expect(route.log, ReServeLoggerLevel.severe);
      expect(route.name, 'API Route');
      expect(route.redirect, Uri.parse('https://api.example.com'));
      expect(route.interceptors.length, 1);
      expect(route.interceptors[0].type, InterceptorType.removeHeaders);
    });

    test('getInterceptors creates and caches interceptors', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final route = ReServeRoute(
        interceptors: [
          InterceptorData(
            type: InterceptorType.setHeaders,
            params: {
              'headers': {'x-key': 'val'},
            },
          ),
        ],
        path: '/test',
      );

      final interceptors1 = route.getInterceptors(config);
      expect(interceptors1.length, 1);
      expect(interceptors1.first, isA<SetHeadersInterceptor>());

      // Calling again returns cached instance
      final interceptors2 = route.getInterceptors(config);
      expect(identical(interceptors1, interceptors2), isTrue);
    });
  });
}
