import 'dart:async';
import 'dart:io';

import 'package:reserve/reserve.dart';
import 'package:reserve/src/reserve_handler.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class Server {
  Server({required this.config});

  late final _logger = config.logger;

  final ServerConfig config;
  late final HttpServer _server;

  Future<HttpServer> start() async {
    SecurityContext? security;

    final https = config.https;
    if (https != null) {
      security = await https.getSecurityContext();
      _logger.info('Utilizing HTTPS.');
    }

    final handlers = <ReServeHandler>[];
    for (final entry in config.routes.entries) {
      final handler = ReServeHandler(config: config, route: entry.value);
      handlers.add(handler);
    }

    final server = await shelf_io.serve(
      (request) {
        var path = request.requestedUri.path;
        if (path.startsWith('/')) {
          path = path.substring(1);
        }
        if (!path.endsWith('/') && path.isNotEmpty) {
          path = '$path/';
        }
        for (final handler in handlers) {
          if (handler.handles(path)) {
            return handler.process(request);
          }
        }

        return Response.notFound('No route exists for: $path');
      },
      (await InternetAddress.lookup(config.host)).first,
      config.port,
      securityContext: security,
      poweredByHeader: null,
    );
    _server = server;

    _logger.info(
      'Re-Serve listening on: ${config.https == null ? 'http' : 'https'}://${server.address.host}:${server.port}',
    );

    return server;
  }

  Future<void> stop() async {
    await _server.close();
    _logger.info('Shut down server');
  }
}
