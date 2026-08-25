import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:logging/logging.dart';
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
    if (headers.isEmpty) {
      return response;
    }

    final cookies = <ReServeCookie>[];

    logger.finest('Modified cookies for response:');
    String maxln(String input, {int length = 16}) =>
        input.length < length ? input : '${input.substring(0, length - 3)}...';
    final cookieTable = <List<String>>[];

    for (final header in headers) {
      final cookie = ReServeCookie.fromCookie(
        Cookie.fromSetCookieValue(header.value),
      );

      final host = config.origin?.host ?? config.host;

      final copied = cookie.copyWith(
        domain: '.$host',
        secure: allowSecure ? cookie.secure : false,
      );

      if (logger.isLoggable(Level.FINEST)) {
        cookieTable.add([
          maxln(copied.name),
          maxln(copied.value),
          maxln(copied.domain ?? ''),
          maxln(copied.path ?? '/'),
          maxln(copied.httpOnly.toString()),
          maxln(copied.secure.toString()),
          maxln(copied.maxAge.toString()),
          maxln(copied.expires?.toString() ?? '', length: 20),
        ]);
      }
      cookies.add(copied);
    }

    if (logger.isLoggable(Level.FINEST)) {
      cookieTable.sort(
        (a, b) => a[0].toLowerCase().compareTo(b[0].toLowerCase()),
      );
      final table = Table()
        ..insertColumn(header: 'Name')
        ..insertColumn(header: 'Value')
        ..insertColumn(header: 'Domain')
        ..insertColumn(header: 'Path')
        ..insertColumn(header: 'HttpOnly')
        ..insertColumn(header: 'Secure')
        ..insertColumn(header: 'MaxAge')
        ..insertColumn(header: 'Expires')
        ..insertRows(cookieTable);

      // The table is already long and the previous line has the timestamp and
      // logger info.  In this case, directly write the output rather than going
      // through the logger.
      //
      // ignore: avoid_print
      print(table);
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
