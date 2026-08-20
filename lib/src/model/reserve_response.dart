import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_cookie_parser/http_cookie_parser.dart';
import 'package:reserve/reserve.dart';
import 'package:shelf/shelf.dart' as shelf;

class ReServeResponse {
  ReServeResponse({
    required this.bytes,
    required this.headers,
    required this.statusCode,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ReServeResponse.empty() =>
      ReServeResponse(bytes: Uint8List(0), headers: const [], statusCode: 200);

  static ReServeResponse fromHttpResponse(http.Response response) {
    final bytes = response.bodyBytes;
    final headers = ReServeHeader.fromHeaders(
      response.headers.map((key, value) {
        // The set-cookie header is a bit of a pain with the HTTP package
        // because it blindly joins multiple headers with a comma, but the
        // cookie header includes an expiry date such as:
        // "Expires=Thu, 19 Aug 2027 21:06:54 GMT"
        // That, annoyingly, also contains a comma which prevents a simple
        // `split(',')`.
        if (key == 'set-cookie') {
          final cookies = CookieParser(value).cookies;
          return MapEntry(key, cookies);
        }

        // Otherwise, assume that there's only one header per value.  The header
        // set-cookie is the only common cookie with more than one.  As others
        // are discovered, they will have to be added on a case-by-case basis.
        return MapEntry(key, [value]);
      }),
    );

    return ReServeResponse(
      bytes: bytes,
      headers: headers,
      statusCode: response.statusCode,
    );
  }

  final Uint8List bytes;
  final List<ReServeHeader> headers;
  final int statusCode;
  final DateTime timestamp;

  ReServeResponse copyWith({
    Uint8List? bytes,
    List<ReServeHeader>? headers,
    int? statusCode,
    DateTime? timestamp,
  }) => ReServeResponse(
    bytes: bytes ?? this.bytes,
    headers: headers ?? this.headers,
    statusCode: statusCode ?? this.statusCode,
    timestamp: timestamp ?? this.timestamp,
  );

  shelf.Response toShelfResponse() => shelf.Response(
    statusCode,
    body: bytes,
    headers: ReServeHeader.toMapList(headers),
  );
}
