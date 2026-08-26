import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';
import 'package:reserve/reserve.dart';
import 'package:template_expressions/template_expressions.dart';
import 'package:yaon/yaon.dart';

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
    this.vars = const {},
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
  factory ServerConfig.fromJson(
    Map<String, dynamic> json, {
    required Map<String, dynamic> vars,
  }) => _$ServerConfigFromJson({...json, 'vars': vars});

  factory ServerConfig.fromString(String input) {
    final parsed = yaon.parse(input);
    final syntax = TemplateSyntax.lookup(parsed['template-syntax']).syntax;

    final vars =
        (parsed['vars'] as Map<String, dynamic>? ?? const <String, dynamic>{})
            .map(
              (key, value) => MapEntry<String, dynamic>(
                key,
                Template(value.toString(), syntax: [syntax]).evaluate(),
              ),
            );

    final result = Template(input).process(context: {'vars': vars});
    return ServerConfig.fromJson(yaon.parse(result), vars: vars);
  }

  final String host;
  final SslData? https;
  late final List<Interceptor> interceptors;
  final Uri? origin;
  final ReServeLoggerLevel log;

  @JsonKey(includeFromJson: false)
  late final Logger logger;

  @JsonKey(fromJson: _fromInt)
  final int port;
  final String? proxy;
  final Map<String, ReServeRoute> routes;
  final Map<String, dynamic> vars;

  static int _fromInt(dynamic value) =>
      value is num ? value.toInt() : (int.tryParse(value) ?? 5433);

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
