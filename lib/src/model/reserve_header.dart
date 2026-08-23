class ReServeHeaders {
  ReServeHeaders(Iterable<ReServeHeader> all) : all = List.from(all);

  /// Splits the grouped headers from the given mapping of header keys to their
  /// values.
  factory ReServeHeaders.fromHeaders(Map<String, List<String>> headers) {
    final result = <ReServeHeader>[];

    for (final header in headers.entries) {
      for (final value in header.value) {
        result.add(ReServeHeader(key: header.key, value: value));
      }
    }

    return ReServeHeaders(result);
  }

  factory ReServeHeaders.fromMap(Map<String, String> headers) {
    final result = <ReServeHeader>[];

    for (final header in headers.entries) {
      result.add(ReServeHeader(key: header.key, value: header.value));
    }

    return ReServeHeaders(result);
  }

  final List<ReServeHeader> all;

  String? operator [](String name) =>
      all.where((h) => name == h.key).firstOrNull?.value;

  Map<String, String> toMap() {
    final result = <String, String>{};
    for (final header in all) {
      final value = result[header.key];

      if (value != null) {
        result[header.key] = '$value,${header.value}';
      } else {
        result[header.key] = header.value;
      }
    }

    return result;
  }

  Map<String, List<String>> toMapList() {
    final result = <String, List<String>>{};
    for (final header in all) {
      final list = result[header.key] ?? <String>[];
      list.add(header.value);
      result[header.key] = list;
    }

    return result;
  }
}

// Header for the ReServe server.  This is a simple PODO that does a few handy
// things.  First it provides a simple [copyWith] function to clone it into a
// new object with new attributes.  Next, it guarantees all keys are lower case.
class ReServeHeader {
  ReServeHeader({required String key, required this.value})
    : key = key.toLowerCase();

  final String key;
  final String value;

  ReServeHeader copyWith({String? key, String? value}) =>
      ReServeHeader(key: key ?? this.key, value: value ?? this.value);
}
