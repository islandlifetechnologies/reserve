import 'package:reserve/reserve.dart';

class RemoveHeadersInterceptor extends Interceptor {
  RemoveHeadersInterceptor({
    required super.config,
    required Iterable headers,
    this._request = true,
    this._response = true,
  }) : _headers = Set<String>.from(
         headers.map((e) => e.toString().toLowerCase()),
       ),
       super(InterceptorType.removeHeaders);

  factory RemoveHeadersInterceptor.builder({
    required ServerConfig config,
    Map<String, dynamic>? params,
    ReServeRoute? route,
  }) => RemoveHeadersInterceptor(
    config: config,
    headers: params!['headers'] as Iterable,
    request: Interceptor.parseBool(params[kParamRequest], defaultsTo: true),
    response: Interceptor.parseBool(params[kParamResponse], defaultsTo: true),
  );

  static const kParamHeaders = 'headers';
  static const kParamRequest = 'request';
  static const kParamResponse = 'response';

  final Set<String> _headers;
  final bool _request;
  final bool _response;

  @override
  (ReServeRequest, ReServeResponse?) interceptRequest(ReServeRequest request) {
    if (!_request) {
      return (request, null);
    }
    final headers = List<ReServeHeader>.from(request.headers.all);
    headers.removeWhere((h) => _headers.contains(h.key));
    return (request.copyWith(headers: headers), null);
  }

  @override
  ReServeResponse interceptResponse(
    ReServeRequest request,
    ReServeResponse response,
  ) {
    if (!_response) {
      return response;
    }
    final headers = List<ReServeHeader>.from(response.headers.all);
    headers.removeWhere((h) => _headers.contains(h.key));
    return response.copyWith(headers: headers);
  }
}
