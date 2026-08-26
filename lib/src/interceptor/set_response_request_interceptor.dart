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
    String? templateSyntax,
  }) : _headers = Map<String, String>.from(
         headers.map(
           (key, value) => MapEntry<String, String>(
             key.toString().toLowerCase(),
             value.toString(),
           ),
         ),
       ),
       _templateSyntax = TemplateSyntax.lookup(templateSyntax).syntax,
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
    templateSyntax: params[kParamTemplateSyntax],
  );

  static const kParamBody = 'body';
  static const kParamHeaders = 'headers';
  static const kParamStatusCode = 'status-code';
  static const kParamTemplateSyntax = 'template-syntax';

  final String _body;
  final Map<String, String> _headers;
  final int _statusCode;
  final ExpressionSyntax _templateSyntax;

  @override
  FutureOr<(ReServeRequest, ReServeResponse?)> interceptRequest(
    ReServeRequest request,
  ) async {
    final fs = FileSystemFunctions.fileSystem;
    final textTypes = ['text/', 'application/json', 'application/yaml'];
    var bytes = fs.file(_body).readAsBytesSync();

    final contentType =
        _headers['content-type']?.toString() ?? 'application/octet-stream';
    for (final type in textTypes) {
      if (contentType.startsWith(type)) {
        try {
          final body = utf8.decode(bytes);
          final processed = Template(
            body,
            syntax: [_templateSyntax],
          ).process(context: {'vars': config.vars});
          bytes = utf8.encode(processed);
        } catch (_) {
          logger.warning(
            'For file: $_body, encountered text type but could not decode to text.',
          );
        }
      }
    }

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
