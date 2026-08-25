import 'package:reserve/reserve.dart';

class SetHeadersInterceptor extends Interceptor {
  SetHeadersInterceptor({
    required super.config,
    required Map headers,
    this._request = true,
    this._response = true,
  }) : _headers = Map<String, String>.from(
         headers.map(
           (key, value) => MapEntry<String, String>(
             key.toString().toLowerCase(),
             value.toString(),
           ),
         ),
       ),
       super(InterceptorType.setHeaders);

  factory SetHeadersInterceptor.builder({
    required ServerConfig config,
    Map<String, dynamic>? params,
    ReServeRoute? route,
  }) => SetHeadersInterceptor(
    config: config,
    headers: (params?[kParamHeaders] as Map? ?? const {}),
    request: Interceptor.parseBool(params?[kParamRequest], defaultsTo: true),
    response: Interceptor.parseBool(params?[kParamResponse], defaultsTo: true),
  );

  static const kParamHeaders = 'headers';
  static const kParamRequest = 'request';
  static const kParamResponse = 'response';

  final Map<String, String> _headers;
  final bool _request;
  final bool _response;

  @override
  (ReServeRequest, ReServeResponse?) interceptRequest(ReServeRequest request) =>
      _request
      ? (request.copyWith(headers: _updateHeaders(request.headers.all)), null)
      : (request, null);

  @override
  ReServeResponse interceptResponse(
    ReServeRequest request,
    ReServeResponse response,
  ) => _response
      ? response.copyWith(headers: _updateHeaders(response.headers.all))
      : response;

  List<ReServeHeader> _updateHeaders(List<ReServeHeader> headers) {
    headers = List<ReServeHeader>.from(headers);
    headers.removeWhere((h) => _headers.keys.contains(h.key));
    headers.addAll(
      _headers.entries.map((e) => ReServeHeader(key: e.key, value: e.value)),
    );

    return headers;
  }
}
