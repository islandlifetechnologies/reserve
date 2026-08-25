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
    RemoveHeadersInterceptor(
      config: config,
      headers: [
        'content-encoding',
        'content-length',
        'referer',
        'transfer-encoding',
      ],
    ),
    SetHeadersInterceptor(
      config: config,
      headers: {
        'host':
            '${route.redirect.host}${[443, 80].contains(route.redirect.port) ? '' : ':${route.redirect.port}'}',
      },
      response: false,
    ),
  ];

  /// The path to check against.  The past must not start with a '/' and if it
  /// is not empty, it must end with a '/'.
  bool handles(String path) => path.startsWith(this.path);

  Future<Response> process(Request request) async {
    try {
      var req = await ReServeRequest.fromShelfRequest(request);
      ReServeResponse? res;

      for (final interceptors in [
        _defaultInterceptors,
        config.interceptors,
        route.getInterceptors(config),
      ]) {
        for (final interceptor in interceptors) {
          interceptor.logger.config(
            'interceptRequest: ${interceptor.type.name}',
          );
          (req, res) = await interceptor.interceptRequest(req);

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
      redirectPath = '${route.redirect.path}/$redirectPath';
      if (redirectPath.startsWith('/')) {
        redirectPath = redirectPath.substring(1);
      }

      final query = req.uri.hasQuery ? '?${req.uri.query}' : '';
      final uri = Uri.parse(
        '${route.redirect.scheme}://${route.redirect.host}${[80, 443].contains(route.redirect.port) ? '' : ':${route.redirect.port}'}/$redirectPath$query',
      );
      response = await switch (req.method) {
        'DELETE' => client.delete(uri, headers: req.headers.toMap()),
        'GET' => client.get(uri, headers: req.headers.toMap()),
        'HEAD' => client.head(uri, headers: req.headers.toMap()),
        'PATCH' => client.patch(
          uri,
          body: req.bytes,
          headers: req.headers.toMap(),
        ),
        'POST' => client.post(
          uri,
          body: req.bytes,
          headers: req.headers.toMap(),
        ),
        'PUT' => client.put(uri, body: req.bytes, headers: req.headers.toMap()),
        _ => throw ReServeException(body: 'Unsupported method: ${req.method}'),
      };

      res = ReServeResponse.fromHttpResponse(response);
      for (final interceptors in [
        _defaultInterceptors,
        config.interceptors,
        route.getInterceptors(config),
      ]) {
        for (final interceptor in interceptors) {
          interceptor.logger.config(
            'interceptResponse: ${interceptor.type.name}',
          );
          res = await interceptor.interceptResponse(req, res!);
        }
      }

      if (res == null) {
        throw ReServeException();
      }

      _logger.info(
        '[${res.statusCode}] ${req.path} -- ${(res.timestamp.millisecondsSinceEpoch - req.timestamp.millisecondsSinceEpoch) / 1000.0}s',
      );
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
