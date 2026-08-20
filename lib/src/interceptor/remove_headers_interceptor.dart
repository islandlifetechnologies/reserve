import 'package:reserve/reserve.dart';

class RemoveHeadersInterceptor extends Interceptor {
  RemoveHeadersInterceptor(super.data, {required super.config, super.route})
    : _headers = Set<String>.from(
        (data.params[kParamHeaders] as List? ?? const []).map(
          (e) => e.toString().toLowerCase(),
        ),
      );

  factory RemoveHeadersInterceptor.direct({
    required ServerConfig config,
    required Iterable<String> headers,
  }) => RemoveHeadersInterceptor(
    InterceptorData(type: kType, params: {kParamHeaders: headers.toList()}),
    config: config,
  );

  static const kParamHeaders = 'headers';
  static const kType = 'remove-headers';

  final Set<String> _headers;

  @override
  (ReServeRequest, ReServeResponse?) interceptRequest(ReServeRequest request) {
    final headers = List<ReServeHeader>.from(request.headers);
    headers.removeWhere((h) => _headers.contains(h.key));
    return (request.copyWith(headers: headers), null);
  }

  @override
  ReServeResponse interceptResponse(
    ReServeRequest request,
    ReServeResponse response,
  ) {
    final headers = List<ReServeHeader>.from(response.headers);
    headers.removeWhere((h) => _headers.contains(h.key));
    return response.copyWith(headers: headers);
  }
}
