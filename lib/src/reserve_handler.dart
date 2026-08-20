import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:reserve/reserve.dart';
import 'package:shelf/shelf.dart';

class ReServeHandler {
  ReServeHandler({required this.config, required this.route}) {
    var p = route.path;
    if (p.startsWith('/')) {
      p = p.substring(1);
    }
    if (!p.endsWith('/') && p.isNotEmpty) {
      p = '$p/';
    }
    path = p;
  }

  final ServerConfig config;
  final ReServeRoute route;

  late final String path;

  late final _logger = route.logger;

  late final _defaultInterceptors = [
    RemoveHeadersInterceptor.direct(
      config: config,
      headers: ['content-encoding', 'content-length', 'transfer-encoding'],
    ),
    SetHeadersInterceptor.direct(
      config: config,
      headers: {
        'host':
            '${route.redirect.host}${[443, 80].contains(route.redirect.port) ? '' : ':${route.redirect.port}'}',
      },
    ),
    RedirectResponseInterceptor.direct(config: config, route: route),
  ];

  /// The path to check against.  The past must not start with a '/' and if it
  /// is not empty, it must end with a '/'.
  bool handles(String path) => path.startsWith(this.path);

  Future<Response> process(Request request) async {
    try {
      _logger.finer('Request received.');
      var req = await ReServeRequest.fromShelfRequest(request);
      ReServeResponse? res;

      for (final interceptors in [
        _defaultInterceptors,
        config.interceptors,
        route.getInterceptors(config),
      ]) {
        for (final interceptor in interceptors) {
          interceptor.logger.fine('interceptRequest');
          (req, res) = interceptor.interceptRequest(req);

          if (res != null) {
            return res.toShelfResponse();
          }
        }
      }

      late final http.Response response;

      final client = config.client;

      var redirectPath = req.uri.path.replaceFirst(
        route.path.startsWith('/') ? route.path.substring(1) : route.path,
        '',
      );
      if (redirectPath.startsWith('/')) {
        redirectPath = redirectPath.substring(1);
      }
      final uri = Uri.parse(
        '${route.redirect.scheme}://${route.redirect.host}${[80, 443].contains(route.redirect.port) ? '' : ':${route.redirect.port}'}/$redirectPath',
      );
      response = await switch (req.method) {
        'DELETE' => client.delete(
          uri,
          headers: ReServeHeader.toMap(req.headers),
        ),
        'GET' => client.get(uri, headers: ReServeHeader.toMap(req.headers)),
        'HEAD' => client.head(uri, headers: ReServeHeader.toMap(req.headers)),
        'PATCH' => client.patch(
          uri,
          body: req.bytes,
          headers: ReServeHeader.toMap(req.headers),
        ),
        'POST' => client.post(
          uri,
          body: req.bytes,
          headers: ReServeHeader.toMap(req.headers),
        ),
        'PUT' => client.put(
          uri,
          body: req.bytes,
          headers: ReServeHeader.toMap(req.headers),
        ),
        _ => throw ReServeException(body: 'Unsupported method: ${req.method}'),
      };

      res = ReServeResponse.fromHttpResponse(response);
      for (final interceptors in [
        _defaultInterceptors,
        config.interceptors,
        route.getInterceptors(config),
      ]) {
        for (final interceptor in interceptors) {
          interceptor.logger.fine('interceptResponse');
          res = interceptor.interceptResponse(req, res!);
        }
      }

      if (res == null) {
        throw ReServeException();
      }

      _logger.info('${route.redirect.path} [${res.statusCode}]');
      final sRes = res.toShelfResponse();

      return sRes;
    } catch (e, stack) {
      _logger.severe('Error processing request', e, stack);
      if (e is ReServeException) {
        return Response(e.statusCode, body: utf8.encode(e.body));
      }
      return Response.internalServerError();
    }
  }
}
