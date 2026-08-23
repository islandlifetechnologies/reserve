import 'dart:convert';

import 'package:reserve/reserve.dart';

class ReplaceBodyInterceptor extends ResponseInterceptor {
  ReplaceBodyInterceptor({
    required super.config,
    required this._from,
    required this._replace,
  }) : super(InterceptorType.replaceBody);

  factory ReplaceBodyInterceptor.builder({
    required ServerConfig config,
    Map<String, dynamic>? params,
    ReServeRoute? route,
  }) => ReplaceBodyInterceptor(
    config: config,
    from: params![kParamFrom],
    replace: params[kParamReplace],
  );

  static const kParamFrom = 'from';
  static const kParamReplace = 'replace';

  final String _from;
  final String _replace;

  @override
  ReServeResponse interceptResponse(
    ReServeRequest request,
    ReServeResponse response,
  ) {
    var result = response;

    final contentType = response.headers['content-type'] ?? '';
    const textTypes = ['application/json', 'application/javascript', 'text/'];
    if (textTypes.where((t) => contentType.startsWith(t)).firstOrNull != null) {
      try {
        final body = utf8.decode(response.bytes);
        final replaced = body.replaceAll(_from, _replace);
        result = response.copyWith(bytes: utf8.encode(replaced));
      } catch (_) {
        // no-op
      }
    }
    return result;
  }
}
