import 'package:logging/logging.dart';

enum ReServeLoggerLevel {
  all(Level.ALL),
  config(Level.CONFIG),
  fine(Level.FINE),
  finer(Level.FINER),
  finest(Level.FINEST),
  info(Level.INFO),
  off(Level.OFF),
  severe(Level.SEVERE),
  shout(Level.SHOUT),
  warning(Level.WARNING);

  const ReServeLoggerLevel(this.level);
  final Level level;
}
