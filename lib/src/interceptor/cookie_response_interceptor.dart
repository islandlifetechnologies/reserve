import 'dart:io';

import 'package:reserve/reserve.dart';

class CookieResponseInterceptor extends ResponseInterceptor {
  CookieResponseInterceptor(super.data, {required super.config, super.route})
    : assert(route != null),
      allowSecure = Interceptor.parseBool(
        data.params[kParamAllowSecure],
        defaultsTo: true,
      ),
      _route = route!;

  static const kParamAllowSecure = 'allow-secure';
  static const kType = 'cookie';
  static const _kHeaderName = 'set-cookie';

  final bool allowSecure;
  final ReServeRoute _route;

  @override
  ReServeResponse interceptResponse(
    ReServeRequest request,
    ReServeResponse response,
  ) {
    final headers = response.headers.where((h) => h.key == _kHeaderName);

    final cookies = <ReServeCookie>[];

    for (final header in headers) {
      final cookie = ReServeCookie.fromCookie(
        Cookie.fromSetCookieValue(header.value),
      );
      cookies.add(
        cookie.copyWith(
          domain: cookie.domain == null ? null : '.${config.host}',
          path: _route.listen.path,
          secure: allowSecure ? cookie.secure : false,
        ),
      );
    }

    final result = List<ReServeHeader>.from(response.headers)
      ..removeWhere((h) => h.key == _kHeaderName)
      ..addAll(
        cookies.map(
          (c) => ReServeHeader(key: _kHeaderName, value: c.toString()),
        ),
      );

    return response.copyWith(headers: result);
  }
}
