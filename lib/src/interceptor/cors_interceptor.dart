import 'dart:typed_data';

import 'package:reserve/reserve.dart';

const _kAccessControlAllowCredentials = 'access-control-allow-credentials';
const _kAccessControlAllowHeaders = 'access-control-allow-headers';
const _kAccessControlAllowMethods = 'access-control-allow-methods';
const _kAccessControlAllowOrigin = 'access-control-allow-origin';
const _kAccessControlExposeHeaders = 'access-control-expose-headers';
const _kAccessControlMaxAge = 'access-control-max-age';

class CorsInterceptor extends Interceptor {
  CorsInterceptor(super.data, {required super.config, super.route})
    : _additionalHeaders = data.params[kParamAdditionalHeaders] ?? const [],
      _credentials = Interceptor.parseBool(
        data.params[kParamCredentials],
        defaultsTo: false,
      ),
      _exposeHeaders = data.params[kParamExposeHeaders] ?? const [],
      _headers = data.params[kParamExposeHeaders] ?? _kDefaultHeaders,
      _maxAge =
          Interceptor.maybeParseNum<int>(data.params[kParamMaxAge]) ??
          const Duration(hours: 24).inSeconds,
      _methods = data.params[kParamMethods];

  static const kParamAdditionalHeaders = 'additional-headers';
  static const kParamCredentials = 'allow-credentials';
  static const kParamExposeHeaders = 'expose-headers';
  static const kParamHeaders = 'allow-headers';
  static const kParamMaxAge = 'max-age';
  static const kParamMethods = 'allow-methods';
  static const kType = 'cors';

  static const _kDefaultHeaders = [
    'accept',
    'accept-encoding',
    'accept-language',
    'content-type',
    'dnt',
    'if-none-match',
    'origin',
    'user-agent',
  ];

  final List<String> _additionalHeaders;
  final bool _credentials;
  final List<String> _exposeHeaders;
  final List<String> _headers;
  final int _maxAge;
  final List<String> _methods;

  @override
  (ReServeRequest, ReServeResponse?) interceptRequest(ReServeRequest request) {
    ReServeResponse? response;

    final origin = request.headers.where((h) => h.key == 'origin').firstOrNull;
    if (origin != null && request.method == 'OPTIONS') {
      response = _alterResponse(request);
    }

    return (request, response);
  }

  @override
  ReServeResponse interceptResponse(
    ReServeRequest request,
    ReServeResponse response,
  ) => _alterResponse(request);

  ReServeResponse _alterResponse(
    ReServeRequest request, [
    ReServeResponse? response,
  ]) {
    response ??= ReServeResponse(
      bytes: Uint8List(0),
      headers: [],
      statusCode: 200,
    );

    final origin = request.headers.where((h) => h.key == 'origin').firstOrNull;
    if (origin != null) {
      final rh = RemoveHeadersInterceptor(
        InterceptorData(
          type: RemoveHeadersInterceptor.kType,
          params: {
            RemoveHeadersInterceptor.kParamHeaders: [
              _kAccessControlAllowCredentials,
              _kAccessControlAllowHeaders,
              _kAccessControlAllowMethods,
              _kAccessControlAllowOrigin,
              _kAccessControlExposeHeaders,
              _kAccessControlMaxAge,
            ],
          },
        ),
        config: config,
      );
      response = rh.interceptResponse(request, response);

      response.headers.addAll([
        ReServeHeader(
          key: _kAccessControlAllowCredentials,
          value: _credentials.toString(),
        ),
        for (final h in [..._headers, ..._additionalHeaders])
          ReServeHeader(
            key: _kAccessControlAllowHeaders,
            value: h.toLowerCase(),
          ),
        for (final m in _methods)
          ReServeHeader(
            key: _kAccessControlAllowMethods,
            value: m.toLowerCase(),
          ),
        for (final h in _exposeHeaders)
          ReServeHeader(
            key: _kAccessControlExposeHeaders,
            value: h.toLowerCase(),
          ),
        ReServeHeader(key: _kAccessControlMaxAge, value: _maxAge.toString()),
      ]);
    }
    return response;
  }
}
