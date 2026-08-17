import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:reserve/reserve.dart';
import 'package:shelf/shelf.dart' as shelf;

class ReServeResponse {
  ReServeResponse({
    required this.bytes,
    required this.headers,
    required this.statusCode,
  });

  static ReServeResponse fromHttpResponse(http.Response response) {
    final bytes = response.bodyBytes;
    final headers = ReServeHeader.fromHeaders(
      response.headers.map((key, value) => MapEntry(key, value.split(','))),
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

  ReServeResponse copyWith({
    Uint8List? bytes,
    List<ReServeHeader>? headers,
    int? statusCode,
  }) => ReServeResponse(
    bytes: bytes ?? this.bytes,
    headers: headers ?? this.headers,
    statusCode: statusCode ?? this.statusCode,
  );

  shelf.Response toShelfResponse() => shelf.Response(
    statusCode,
    body: bytes,
    headers: ReServeHeader.toMapList(headers),
  );
}
