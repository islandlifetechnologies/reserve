import 'package:reserve/reserve.dart';

class ReplaceHeadersInterceptor extends Interceptor {
  ReplaceHeadersInterceptor({
    required super.config,
    required this._from,
    required this._replace,
    this._request = true,
    this._response = true,
  }) : super(InterceptorType.replaceBody);

  factory ReplaceHeadersInterceptor.builder({
    required ServerConfig config,
    Map<String, dynamic>? params,
    ReServeRoute? route,
  }) => ReplaceHeadersInterceptor(
    config: config,
    from: params![kParamFrom],
    replace: params[kParamReplace],
    request: Interceptor.parseBool(params[kParamRequest], defaultsTo: true),
    response: Interceptor.parseBool(params[kParamResponse], defaultsTo: true),
  );

  static const kParamFrom = 'from';
  static const kParamReplace = 'replace';
  static const kParamRequest = 'request';
  static const kParamResponse = 'response';

  final String _from;
  final String _replace;
  final bool _request;
  final bool _response;

  @override
  (ReServeRequest, ReServeResponse?) interceptRequest(ReServeRequest request) {
    if (!_request) {
      return (request, null);
    }
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
    if (!_response) {
      return response;
    }
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
