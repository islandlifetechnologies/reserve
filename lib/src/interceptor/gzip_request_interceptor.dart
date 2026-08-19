import 'package:reserve/reserve.dart';

class GzipRequestInterceptor extends RequestInterceptor {
  GzipRequestInterceptor(super.data, {required super.config, super.route});

  @override
  (ReServeRequest, ReServeResponse?) interceptRequest(ReServeRequest request) {
    final gzipped = request.headers
        .where((h) => h.key == 'content-encoding' && h.value == 'gzip')
        .isNotEmpty;

    if (gzipped) {
      final rh = RemoveHeadersInterceptor(
        InterceptorData(
          type: RemoveHeadersInterceptor.kType,
          params: {
            RemoveHeadersInterceptor.kParamHeaders: [
              'content-encoding',
              'content-length',
            ],
          },
        ),
        config: config,
      );

      (request, _) = rh.interceptRequest(request);
    }

    return (request, null);
  }
}
