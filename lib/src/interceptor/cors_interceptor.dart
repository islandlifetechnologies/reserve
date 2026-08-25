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

  static const kDefaultMethods = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
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
  ) => _alterResponse(request, response: response);

  ReServeResponse _alterResponse(
    ReServeRequest request, {
    ReServeResponse? response,
  }) {
    response ??= ReServeResponse.empty();

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
        ReServeHeader(
          key: _kAccessControlAllowHeaders,
          value: <String>{...this.headers, ...additionalHeaders}.join(','),
        ),
        ReServeHeader(
          key: _kAccessControlAllowMethods,
          value: methods.join(','),
        ),
        ReServeHeader(key: _kAccessControlAllowOrigin, value: origin),
        ReServeHeader(
          key: _kAccessControlExposeHeaders,
          value: exposeHeaders.join(','),
        ),
        ReServeHeader(key: _kAccessControlMaxAge, value: maxAge.toString()),
      ]);

      response = response.copyWith(headers: headers);
    }
    return response;
  }
}
