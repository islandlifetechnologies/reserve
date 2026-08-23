import 'package:reserve/reserve.dart';
import 'package:template_expressions/template_expressions.dart';

class SetHeadersInterceptor extends Interceptor {
  SetHeadersInterceptor({required super.config, required Map headers})
    : _headers = Map<String, String>.from(
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
  );

  static const kParamHeaders = 'headers';

  final Map<String, String> _headers;

  @override
  (ReServeRequest, ReServeResponse?) interceptRequest(ReServeRequest request) =>
      (request.copyWith(headers: _updateHeaders(request.headers.all)), null);

  @override
  ReServeResponse interceptResponse(
    ReServeRequest request,
    ReServeResponse response,
  ) => response.copyWith(headers: _updateHeaders(response.headers.all));

  List<ReServeHeader> _updateHeaders(List<ReServeHeader> headers) {
    headers = List<ReServeHeader>.from(headers);
    headers.removeWhere((h) => _headers.keys.contains(h.key));
    headers.addAll(
      _headers.entries.map(
        (e) => ReServeHeader(key: e.key, value: Template(e.value).process()),
      ),
    );

    return headers;
  }
}
