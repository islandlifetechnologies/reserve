import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';
import 'package:reserve/reserve.dart';

part 'server_config.g.dart';

@JsonSerializable(createToJson: false)
class ServerConfig {
  ServerConfig({
    this.host = 'localhost',
    Map<String, dynamic>? headers,
    List<InterceptorData> interceptors = const [],
    this.https,
    this.log = ReServeLoggerLevel.config,
    this.origin,
    this.port = 5433,
    this.proxy,
    required this.routes,
  }) {
    this.interceptors = interceptors
        .map((data) => Interceptor.create(data, config: this))
        .toList();
    logger = Logger('Server');
    logger.level = log.level;

    for (final entry in routes.entries) {
      entry.value.path = entry.key;
    }
  }
  factory ServerConfig.fromJson(Map<String, dynamic> json) =>
      _$ServerConfigFromJson(json);

  final String host;
  final SslData? https;
  late final List<Interceptor> interceptors;
  final Uri? origin;
  final ReServeLoggerLevel log;

  @JsonKey(includeFromJson: false)
  late final Logger logger;

  final int port;
  final String? proxy;
  final Map<String, ReServeRoute> routes;

  http.Client get client {
    final httpClient = HttpClient();
    if (proxy != null) {
      httpClient.findProxy = (uri) => 'PROXY $proxy';
      httpClient.badCertificateCallback = (_, _, _) => true;
    }

    return IOClient(httpClient);
  }

  String get entrypoint => origin == null
      ? ('${https == null ? 'http' : 'https'}://$host${[80, 443].contains(port) ? '' : ':$port'}')
      : origin!.toString();
}
