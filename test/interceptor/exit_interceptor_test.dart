import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  group('ExitInterceptor', () {
    test('constructs with default exitCode', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = ExitInterceptor(config: config);
      expect(interceptor.exitCode, 0);
      expect(interceptor.type, InterceptorType.exit);
    });

    test('builder initializes from params', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = ExitInterceptor.builder(
        config: config,
        params: {'code': '42'},
      );

      expect(interceptor.exitCode, 42);
      expect(interceptor.type, InterceptorType.exit);
    });

    test('builder defaults to 0 when code is invalid or missing', () {
      final config = ServerConfig(path: 'test.yaml', routes: const {});

      final interceptor = ExitInterceptor.builder(
        config: config,
        params: {'code': 'abc'},
      );

      expect(interceptor.exitCode, 0);
    });
  });
}
