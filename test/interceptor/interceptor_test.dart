import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  group('Interceptor static helpers', () {
    test('maybeParseNum handles num, String, int, double', () {
      expect(Interceptor.maybeParseNum<int>(42), 42);
      expect(Interceptor.maybeParseNum<int>('42'), 42);
      expect(Interceptor.maybeParseNum<int>(42.7), 42);
      expect(Interceptor.maybeParseNum<double>(3.14), 3.14);
      expect(Interceptor.maybeParseNum<double>('3.14'), 3.14);
      expect(Interceptor.maybeParseNum<int>('invalid'), isNull);
      expect(Interceptor.maybeParseNum<int>(null), isNull);
    });

    test('parseBool handles boolean and string representations', () {
      expect(Interceptor.parseBool(true), isTrue);
      expect(Interceptor.parseBool(false), isFalse);
      expect(Interceptor.parseBool('true'), isTrue);
      expect(Interceptor.parseBool('TRUE'), isTrue);
      expect(Interceptor.parseBool('false'), isFalse);
      expect(Interceptor.parseBool('random'), isFalse);
      expect(Interceptor.parseBool(null, defaultsTo: true), isTrue);
      expect(Interceptor.parseBool(null, defaultsTo: false), isFalse);
    });

    test('replaceUrl builds full redirect URL from entrypoint', () {
      final config = ServerConfig(
        host: 'localhost',
        path: 'test.yaml',
        port: 5433,
        routes: const {},
      );

      final route = ReServeRoute(
        path: '/api',
        redirect: Uri.parse('http://backend.internal:9000/service/v1'),
      );

      final interceptor = SetHeadersInterceptor(
        config: config,
        headers: const {},
      );

      final url = interceptor.replaceUrl('anything', route: route);
      expect(url, 'http://localhost:5433/service/v1');
    });

    test('replaceUrl throws ReServeException if route has no redirect', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final route = ReServeRoute(path: '/api');
      final interceptor = SetHeadersInterceptor(
        config: config,
        headers: const {},
      );

      expect(
        () => interceptor.replaceUrl('url', route: route),
        throwsA(isA<ReServeException>()),
      );
    });

    test('Interceptor.create constructs appropriate subclass', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = Interceptor.create(
        InterceptorData(
          type: InterceptorType.setHeaders,
          params: {
            'headers': {'x-key': '123'},
          },
        ),
        config: config,
      );

      expect(interceptor, isA<SetHeadersInterceptor>());
      expect(interceptor.type, InterceptorType.setHeaders);
    });
  });
}
