import 'package:reserve/reserve.dart';

class RemoveHeadersInterceptor extends Interceptor {
  RemoveHeadersInterceptor({required super.config, required Iterable headers})
    : _headers = Set<String>.from(
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
  );

  static const kParamHeaders = 'headers';

  final Set<String> _headers;

  @override
  (ReServeRequest, ReServeResponse?) interceptRequest(ReServeRequest request) {
    final headers = List<ReServeHeader>.from(request.headers.all);
    headers.removeWhere((h) => _headers.contains(h.key));
    return (request.copyWith(headers: headers), null);
  }

  @override
  ReServeResponse interceptResponse(
    ReServeRequest request,
    ReServeResponse response,
  ) {
    final headers = List<ReServeHeader>.from(response.headers.all);
    headers.removeWhere((h) => _headers.contains(h.key));
    return response.copyWith(headers: headers);
  }
}
