import 'package:reserve/reserve.dart';

class RedirectResponseInterceptor extends ResponseInterceptor {
  RedirectResponseInterceptor({required super.config, required this._route})
    : super(InterceptorType.redirect, route: _route);

  factory RedirectResponseInterceptor.builder({
    required ServerConfig config,
    Map<String, dynamic>? params,
    ReServeRoute? route,
  }) => RedirectResponseInterceptor(config: config, route: route!);

  static const _kHeaderName = 'location';

  final ReServeRoute _route;

  @override
  ReServeResponse interceptResponse(
    ReServeRequest request,
    ReServeResponse response,
  ) {
    final headers = response.headers.all.where((h) => h.key == _kHeaderName);

    final result = List<ReServeHeader>.from(response.headers.all)
      ..removeWhere((h) => h.key == _kHeaderName)
      ..addAll(
        headers.map(
          (h) => ReServeHeader(
            key: _kHeaderName,
            value: replaceUrl(h.value, route: _route),
          ),
        ),
      );

    return response.copyWith(headers: result);
  }
}
