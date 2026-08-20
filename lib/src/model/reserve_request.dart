import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:reserve/reserve.dart';
import 'package:shelf/shelf.dart' as shelf;

class ReServeRequest {
  ReServeRequest({
    required this.bytes,
    required this.headers,
    required String method,
    required this.uri,
    DateTime? timestamp,
  }) : method = method.toUpperCase(),
       timestamp = DateTime.now();

  factory ReServeRequest.empty() => ReServeRequest(
    bytes: Uint8List(0),
    headers: const [],
    method: 'GET',
    uri: Uri(),
  );

  static Future<ReServeRequest> fromShelfRequest(shelf.Request request) async {
    final method = request.method;
    final uri = request.url;
    final headers = ReServeHeader.fromHeaders(request.headersAll);

    final bytes = await request
        .read()
        .fold(BytesBuilder(), (builder, chunk) => builder..add(chunk))
        .then((builder) => builder.takeBytes());

    return ReServeRequest(
      bytes: bytes,
      headers: headers,
      method: method,
      uri: uri,
    );
  }

  final Uint8List bytes;
  final List<ReServeHeader> headers;
  final String method;
  final DateTime timestamp;
  final Uri uri;

  ReServeRequest copyWith({
    Uint8List? bytes,
    List<ReServeHeader>? headers,
    String? method,
    DateTime? timestamp,
    Uri? uri,
  }) => ReServeRequest(
    bytes: bytes ?? this.bytes,
    headers: headers ?? this.headers,
    method: method ?? this.method,
    timestamp: timestamp ?? this.timestamp,
    uri: uri ?? this.uri,
  );

  http.Request toHttpRequest() {
    final req = http.Request(method, uri)..bodyBytes = bytes;
    req.headers.addAll(ReServeHeader.toMap(headers));

    return req;
  }
}
