import 'dart:io';

import 'package:reserve/reserve.dart';

class CookieResponseInterceptor extends ResponseInterceptor {
  CookieResponseInterceptor({this.allowSecure = true, required super.config})
    : super(InterceptorType.cookie);

  factory CookieResponseInterceptor.builder({
    required ServerConfig config,
    Map<String, dynamic>? params,
    ReServeRoute? route,
  }) => CookieResponseInterceptor(
    config: config,
    allowSecure: Interceptor.parseBool(
      params?[kParamAllowSecure],
      defaultsTo: true,
    ),
  );

  static const kParamAllowSecure = 'allow-secure';
  static const _kHeaderName = 'set-cookie';

  final bool allowSecure;

  @override
  ReServeResponse interceptResponse(
    ReServeRequest request,
    ReServeResponse response,
  ) {
    final headers = response.headers.all.where((h) => h.key == _kHeaderName);

    final cookies = <ReServeCookie>[];

    for (final header in headers) {
      final cookie = ReServeCookie.fromCookie(
        Cookie.fromSetCookieValue(header.value),
      );

      final host = config.origin?.host ?? config.host;

      cookies.add(
        cookie.copyWith(
          domain: cookie.domain == null ? null : '.$host',
          secure: allowSecure ? cookie.secure : false,
        ),
      );
    }

    final result = List<ReServeHeader>.from(response.headers.all)
      ..removeWhere((h) => h.key == _kHeaderName)
      ..addAll(
        cookies.map(
          (c) => ReServeHeader(key: _kHeaderName, value: c.toString()),
        ),
      );

    return response.copyWith(headers: result);
  }
}
