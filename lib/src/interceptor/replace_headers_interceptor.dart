import 'package:reserve/reserve.dart';

class ReplaceHeadersInterceptor extends Interceptor {
  ReplaceHeadersInterceptor({
    required super.config,
    required this._from,
    required this._replace,
  }) : super(InterceptorType.replaceBody);

  factory ReplaceHeadersInterceptor.builder({
    required ServerConfig config,
    Map<String, dynamic>? params,
    ReServeRoute? route,
  }) => ReplaceHeadersInterceptor(
    config: config,
    from: params![kParamFrom],
    replace: params[kParamReplace],
  );

  static const kParamFrom = 'from';
  static const kParamReplace = 'replace';

  final String _from;
  final String _replace;

  @override
  (ReServeRequest, ReServeResponse?) interceptRequest(ReServeRequest request) {
    final result = <ReServeHeader>[];

    for (final header in request.headers.all) {
      result.add(
        ReServeHeader(
          key: header.key,
          value: header.value.replaceAll(_from, _replace),
        ),
      );
    }

    return (request.copyWith(headers: result), null);
  }

  @override
  ReServeResponse interceptResponse(
    ReServeRequest request,
    ReServeResponse response,
  ) {
    final result = <ReServeHeader>[];

    for (final header in response.headers.all) {
      result.add(
        ReServeHeader(
          key: header.key,
          value: header.value.replaceAll(_from, _replace),
        ),
      );
    }

    return response.copyWith(headers: result);
  }
}
