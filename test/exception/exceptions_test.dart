import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  group('ReServeException', () {
    test('constructs with defaults', () {
      final ex = ReServeException();
      expect(ex.statusCode, 500);
      expect(ex.body, 'Server Error');
      expect(ex.toString(), '500: Server Error');
    });

    test('constructs with custom status code and body', () {
      final ex = ReServeException(statusCode: 404, body: 'Not Found');
      expect(ex.statusCode, 404);
      expect(ex.body, 'Not Found');
      expect(ex.toString(), '404: Not Found');
    });

    test('fromException creates formatted message with error and stack', () {
      final stack = StackTrace.current;
      final ex = ReServeException.fromException(
        502,
        'Bad Gateway Error',
        Exception('Connection refused'),
        stack,
      );

      expect(ex.statusCode, 502);
      expect(ex.body, contains('Bad Gateway Error'));
      expect(ex.body, contains('Exception: Connection refused'));
      expect(ex.body, contains(stack.toString()));
    });
  });

  group('FatalException', () {
    test('constructs with message only', () {
      final ex = FatalException('Fatal config error');
      expect(ex.message, 'Fatal config error');
      expect(ex.error, isNull);
      expect(ex.stackTrace, isNull);
      expect(ex.toString(), contains('Fatal config error'));
    });

    test('constructs with error and stack trace', () {
      final stack = StackTrace.current;
      final ex = FatalException(
        'Critical failure',
        FormatException('Invalid format'),
        stack,
      );

      expect(ex.message, 'Critical failure');
      expect(ex.error, isA<FormatException>());
      expect(ex.stackTrace, stack);
      expect(ex.toString(), contains('Critical failure'));
      expect(ex.toString(), contains('FormatException: Invalid format'));
    });
  });
}
