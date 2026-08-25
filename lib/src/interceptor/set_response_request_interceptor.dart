import 'dart:async';
import 'dart:io';

import 'package:reserve/reserve.dart';

class SetResponseRequestInterceptor extends RequestInterceptor {
  SetResponseRequestInterceptor({
    required this._body,
    required super.config,
    Map headers = const {},
    this._statusCode = 200,
  }) : _headers = Map<String, String>.from(
         headers.map(
           (key, value) => MapEntry<String, String>(
             key.toString().toLowerCase(),
             value.toString(),
           ),
         ),
       ),
       super(InterceptorType.setResponse);

  factory SetResponseRequestInterceptor.builder({
    required ServerConfig config,
    Map<String, dynamic>? params,
    ReServeRoute? route,
  }) => SetResponseRequestInterceptor(
    config: config,
    body: params![kParamBody].toString(),
    headers: params[kParamHeaders] ?? const {},
    statusCode: Interceptor.maybeParseNum<int>(params[kParamBody]) ?? 200,
  );

  static const kParamBody = 'body';
  static const kParamHeaders = 'headers';
  static const kParamStatusCode = 'status-code';

  final String _body;
  final Map<String, String> _headers;
  final int _statusCode;

  @override
  FutureOr<(ReServeRequest, ReServeResponse?)> interceptRequest(
    ReServeRequest request,
  ) async {
    final bytes = File(_body).readAsBytesSync();

    final response = ReServeResponse(
      bytes: bytes,
      headers: _headers.entries.map(
        (e) => ReServeHeader(key: e.key, value: e.value),
      ),
      statusCode: _statusCode,
    );

    return (request, response);
  }
}
