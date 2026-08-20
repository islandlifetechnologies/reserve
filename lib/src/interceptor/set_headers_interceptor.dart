import 'package:reserve/reserve.dart';

class SetHeadersInterceptor extends Interceptor {
  SetHeadersInterceptor(super.data, {required super.config, super.route})
    : _headers = Map<String, String>.from(
        (data.params[kParamHeaders] as Map? ?? const {}).map(
          (key, value) => MapEntry<String, String>(
            key.toString().toLowerCase(),
            value.toString(),
          ),
        ),
      );

  factory SetHeadersInterceptor.direct({
    required ServerConfig config,
    required Map<String, String> headers,
  }) => SetHeadersInterceptor(
    InterceptorData(type: kType, params: {kParamHeaders: headers}),
    config: config,
  );

  static const kParamHeaders = 'headers';
  static const kType = 'set-headers';

  final Map<String, String> _headers;

  @override
  (ReServeRequest, ReServeResponse?) interceptRequest(ReServeRequest request) =>
      (request.copyWith(headers: _updateHeaders(request.headers)), null);

  @override
  ReServeResponse interceptResponse(
    ReServeRequest request,
    ReServeResponse response,
  ) => response.copyWith(headers: _updateHeaders(response.headers));

  List<ReServeHeader> _updateHeaders(List<ReServeHeader> headers) {
    headers = List<ReServeHeader>.from(headers);
    headers.removeWhere((h) => _headers.keys.contains(h.key));
    headers.addAll(
      _headers.entries.map((e) => ReServeHeader(key: e.key, value: e.value)),
    );

    return headers;
  }
}
