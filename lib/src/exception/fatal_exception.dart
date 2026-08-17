class FatalException implements Exception {
  FatalException(this.message, [this.error, this.stackTrace]);

  final Object? error;
  final String message;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final buf = StringBuffer();
    buf.writeln(message);
    for (final i in [error, stackTrace]) {
      if (i != null) {
        buf.writeln(i.toString());
      }
    }

    return buf.toString();
  }
}
