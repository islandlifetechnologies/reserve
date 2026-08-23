import 'dart:typed_data';

import 'package:reserve/reserve.dart';

const _kAccessControlAllowCredentials = 'access-control-allow-credentials';
const _kAccessControlAllowHeaders = 'access-control-allow-headers';
const _kAccessControlAllowMethods = 'access-control-allow-methods';
const _kAccessControlAllowOrigin = 'access-control-allow-origin';
const _kAccessControlExposeHeaders = 'access-control-expose-headers';
const _kAccessControlMaxAge = 'access-control-max-age';

class CorsInterceptor extends Interceptor {
  CorsInterceptor({
    required this.additionalHeaders,
    required super.config,
    required this.credentials,
    required this.exposeHeaders,
    required this.headers,
    required this.maxAge,
    required this.methods,
  }) : super(InterceptorType.cors);

  factory CorsInterceptor.builder({
    required ServerConfig config,
    Map<String, dynamic>? params,
    ReServeRoute? route,
  }) => CorsInterceptor(
    additionalHeaders: params?[kParamAdditionalHeaders] ?? const [],
    config: config,
    credentials: Interceptor.parseBool(
      params?[kParamCredentials],
      defaultsTo: false,
    ),
    exposeHeaders: params?[kParamExposeHeaders] ?? const [],
    headers: params?[kParamExposeHeaders] ?? _kDefaultHeaders,
    maxAge:
        Interceptor.maybeParseNum<int>(params?[kParamMaxAge]) ??
        const Duration(hours: 24).inSeconds,
    methods: params?[kParamMethods],
  );

  static const kParamAdditionalHeaders = 'additional-headers';
  static const kParamCredentials = 'allow-credentials';
  static const kParamExposeHeaders = 'expose-headers';
  static const kParamHeaders = 'allow-headers';
  static const kParamMaxAge = 'max-age';
  static const kParamMethods = 'allow-methods';

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

  final List<String> additionalHeaders;
  final bool credentials;
  final List<String> exposeHeaders;
  final List<String> headers;
  final int maxAge;
  final List<String> methods;

  @override
  (ReServeRequest, ReServeResponse?) interceptRequest(ReServeRequest request) {
    ReServeResponse? response;

    final origin = request.headers['origin'];
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

    final origin = request.headers['origin'];
    if (origin != null) {
      final rh = RemoveHeadersInterceptor(
        config: config,
        headers: [
          _kAccessControlAllowCredentials,
          _kAccessControlAllowHeaders,
          _kAccessControlAllowMethods,
          _kAccessControlAllowOrigin,
          _kAccessControlExposeHeaders,
          _kAccessControlMaxAge,
        ],
      );
      response = rh.interceptResponse(request, response);

      final headers = List<ReServeHeader>.from(response.headers.all);
      headers.addAll([
        ReServeHeader(
          key: _kAccessControlAllowCredentials,
          value: credentials.toString(),
        ),
        for (final h in [...this.headers, ...additionalHeaders])
          ReServeHeader(
            key: _kAccessControlAllowHeaders,
            value: h.toLowerCase(),
          ),
        for (final m in methods)
          ReServeHeader(
            key: _kAccessControlAllowMethods,
            value: m.toLowerCase(),
          ),
        for (final h in exposeHeaders)
          ReServeHeader(
            key: _kAccessControlExposeHeaders,
            value: h.toLowerCase(),
          ),
        ReServeHeader(key: _kAccessControlMaxAge, value: maxAge.toString()),
      ]);

      response = response.copyWith(headers: headers);
    }
    return response;
  }
}
