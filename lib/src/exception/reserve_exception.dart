class ReServeException implements Exception {
  ReServeException({this.body = 'Server Error', this.statusCode = 500});

  factory ReServeException.fromException(
    int statusCode,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final buf = StringBuffer();

    buf.writeln(message);
    if (error != null) {
      buf.writeln(error.toString());
    }
    if (stackTrace != null) {
      buf.writeln(stackTrace.toString());
    }

    return ReServeException(body: buf.toString(), statusCode: statusCode);
  }

  final String body;
  final int statusCode;

  @override
  String toString() => '$statusCode: $body';
}
