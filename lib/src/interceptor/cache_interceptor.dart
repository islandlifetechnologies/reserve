import 'package:reserve/reserve.dart';

class CacheInterceptor extends Interceptor {
  CacheInterceptor({required super.config}) : super(InterceptorType.cache);

  factory CacheInterceptor.builder({
    required ServerConfig config,
    Map<String, dynamic>? params,
    ReServeRoute? route,
  }) => CacheInterceptor(config: config);

  static final kParamPersistMode = 'persist-mode';

  final _repository = CacheRepository();

  @override
  Future<(ReServeRequest, ReServeResponse?)> interceptRequest(
    ReServeRequest request,
  ) async {
    final response = await _repository.lookup(request);

    if (response != null) {
      logger.finer('Returning cached item for path: ${request.uri.path}');
    }

    return (request, response);
  }

  @override
  Future<ReServeResponse> interceptResponse(
    ReServeRequest request,
    ReServeResponse response,
  ) async {
    final etag = response.headers['etag'];
    if (etag != null) {
      await _repository.save(request, response);
    }

    return response;
  }
}
