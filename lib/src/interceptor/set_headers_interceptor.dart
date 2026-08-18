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

  static const kParamHeaders = 'headers';
  static const kType = 'set-headers';

  final Map<String, String> _headers;

  @override
  ReServeRequest interceptRequest(ReServeRequest request) =>
      request.copyWith(headers: _updateHeaders(request.headers));

  @override
  ReServeResponse interceptResponse(ReServeResponse response) =>
      response.copyWith(headers: _updateHeaders(response.headers));

  List<ReServeHeader> _updateHeaders(List<ReServeHeader> headers) {
    headers = List<ReServeHeader>.from(headers);
    headers.removeWhere((h) => _headers.keys.contains(h.key));
    headers.addAll(
      _headers.entries.map((e) => ReServeHeader(key: e.key, value: e.value)),
    );

    return headers;
  }
}
