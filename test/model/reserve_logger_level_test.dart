import 'package:logging/logging.dart';
import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  group('ReServeLoggerLevel', () {
    test('maps all enum values to correct Level', () {
      expect(ReServeLoggerLevel.all.level, Level.ALL);
      expect(ReServeLoggerLevel.config.level, Level.CONFIG);
      expect(ReServeLoggerLevel.fine.level, Level.FINE);
      expect(ReServeLoggerLevel.finer.level, Level.FINER);
      expect(ReServeLoggerLevel.finest.level, Level.FINEST);
      expect(ReServeLoggerLevel.info.level, Level.INFO);
      expect(ReServeLoggerLevel.off.level, Level.OFF);
      expect(ReServeLoggerLevel.severe.level, Level.SEVERE);
      expect(ReServeLoggerLevel.shout.level, Level.SHOUT);
      expect(ReServeLoggerLevel.warning.level, Level.WARNING);
    });
  });
}
