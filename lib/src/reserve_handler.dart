import 'package:http/http.dart' as http;
import 'package:reserve/reserve.dart';
import 'package:shelf/shelf.dart';

class ReServeHandler {
  ReServeHandler({required this.config, required this.route});

  final ServerConfig config;
  final ReServeRoute route;

  late final _defaultInterceptors = [
    RemoveHeadersInterceptor(
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
    ),
    RedirectResponseInterceptor(
      InterceptorData(type: RedirectResponseInterceptor.kType),
      config: config,
      route: route,
    ),
  ];

  Future<Response> process(Request request) async {
    var req = await ReServeRequest.fromShelfRequest(request);
    ReServeResponse? res;

    for (final interceptors in [
      _defaultInterceptors,
      config.interceptors,
      config.request.getInterceptors(config),
      route.getInterceptors(config),
      route.listen.getInterceptors(config, route),
    ]) {
      for (final interceptor in interceptors) {
        (req, res) = interceptor.interceptRequest(req);

        if (res != null) {
          return res.toShelfResponse();
        }
      }
    }

    late final http.Response response;

    final client = config.client;
    switch (req.method) {
      case 'DELETE':
        response = await client.delete(
          req.uri,
          headers: ReServeHeader.toMap(req.headers),
        );
        break;
      case 'GET':
        response = await client.get(
          req.uri,
          headers: ReServeHeader.toMap(req.headers),
        );
        break;
      case 'HEAD':
        response = await client.head(
          req.uri,
          headers: ReServeHeader.toMap(req.headers),
        );
        break;
      case 'PATCH':
        response = await client.patch(
          req.uri,
          body: req.bytes,
          headers: ReServeHeader.toMap(req.headers),
        );
        break;
      case 'POST':
        response = await client.post(
          req.uri,
          body: req.bytes,
          headers: ReServeHeader.toMap(req.headers),
        );
        break;
      case 'PUT':
        response = await client.put(
          req.uri,
          body: req.bytes,
          headers: ReServeHeader.toMap(req.headers),
        );
        break;
      default:
        throw Exception('Unsupported method: ${req.method}');
    }

    res = ReServeResponse.fromHttpResponse(response);
    for (final interceptors in [
      _defaultInterceptors,
      config.interceptors,
      config.response.getInterceptors(config),
      route.getInterceptors(config),
      route.redirect.getInterceptors(config, route),
    ]) {
      for (final interceptor in interceptors) {
        res = interceptor.interceptResponse(req, res!);
      }
    }

    return res!.toShelfResponse();
  }
}
