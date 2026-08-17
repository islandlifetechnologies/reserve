// Header for the ReServe server.  This is a simple PODO that does a few handy
// things.  First it provides a simple [copyWith] function to clone it into a
// new object with new attributes.  Next, it guarantees all keys are lower case.
class ReServeHeader {
  ReServeHeader({required String key, required this.value})
    : key = key.toLowerCase();

  /// Splits the grouped headers from the given mapping of header keys to their
  /// values.
  static List<ReServeHeader> fromHeaders(Map<String, List<String>> headers) {
    final result = <ReServeHeader>[];

    for (final header in headers.entries) {
      for (final value in header.value) {
        result.add(ReServeHeader(key: header.key, value: value));
      }
    }

    return result;
  }

  static Map<String, String> toMap(List<ReServeHeader> headers) {
    final result = <String, String>{};
    for (final header in headers) {
      final value = result[header.key];

      if (value != null) {
        result[header.key] = '$value,${header.value}';
      } else {
        result[header.key] = header.value;
      }
    }

    return result;
  }

  static Map<String, List<String>> toMapList(List<ReServeHeader> headers) {
    final result = <String, List<String>>{};
    for (final header in headers) {
      final list = result[header.key] ?? <String>[];
      list.add(header.value);
      result[header.key] = list;
    }

    return result;
  }

  final String key;
  final String value;

  ReServeHeader copyWith({String? key, String? value}) =>
      ReServeHeader(key: key ?? this.key, value: value ?? this.value);
}
