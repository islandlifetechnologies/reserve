import 'package:reserve/reserve.dart';

class RedirectResponseInterceptor extends ResponseInterceptor {
  RedirectResponseInterceptor(super.data, {required super.config, super.route})
    : assert(route != null),
      _route = route!;

  static const kType = 'redirect';
  static const _kHeaderName = 'location';

  final ReServeRoute _route;

  @override
  ReServeResponse interceptResponse(ReServeResponse response) {
    final headers = response.headers.where((h) => h.key == _kHeaderName);

    final result = List<ReServeHeader>.from(response.headers)
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
