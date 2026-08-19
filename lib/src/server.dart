import 'dart:async';
import 'dart:io';

import 'package:reserve/reserve.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class Server {
  Server({required this.config});

  final ServerConfig config;

  Future<HttpServer> serve() async {
    SecurityContext? security;

    final https = config.https;
    if (https != null) {
      security = await https.getSecurityContext();
    }
    final server = await shelf_io.serve(
      _processRequest,
      config.host,
      config.port,
      securityContext: security,
    );

    return server;
  }
}
