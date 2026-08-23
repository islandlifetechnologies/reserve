import 'dart:async';
import 'dart:convert';

import 'package:reserve/reserve.dart';
import 'package:template_expressions/template_expressions.dart';

class SetResponseRequestInterceptor extends RequestInterceptor {
  SetResponseRequestInterceptor({
    required this._body,
    required super.config,
    Map headers = const {},
    this._statusCode = 200,
    this._type = BodyContentType.text,
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
    type:
        BodyContentType.values
            .where((t) => t.name == params[kParamType])
            .firstOrNull ??
        BodyContentType.text,
  );

  static const kParamBody = 'body';
  static const kParamHeaders = 'headers';
  static const kParamStatusCode = 'status-code';
  static const kParamType = 'type';

  final String _body;
  final Map<String, String> _headers;
  final int _statusCode;
  final BodyContentType _type;

  @override
  FutureOr<(ReServeRequest, ReServeResponse?)> interceptRequest(
    ReServeRequest request,
  ) async {
    final bytes = switch (_type) {
      BodyContentType.binary => Template(_body).evaluate(),
      BodyContentType.text => utf8.encode(Template(_body).process()),
    };

    final response = ReServeResponse(
      bytes: bytes,
      headers: _headers.entries.map(
        (e) => ReServeHeader(key: e.key, value: Template(e.value).process()),
      ),
      statusCode: _statusCode,
    );

    return (request, response);
  }
}

enum BodyContentType { binary, text }
