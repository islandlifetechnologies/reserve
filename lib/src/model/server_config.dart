import 'dart:convert';
import 'dart:io';

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';
import 'package:reserve/reserve.dart';
import 'package:template_expressions/template_expressions.dart';
import 'package:yaon/yaon.dart';

part 'server_config.g.dart';

@JsonSerializable(createToJson: false)
class ServerConfig({
  final String host = 'localhost',
  @JsonKey(fromJson: _fromFs, includeToJson: false)
  final FileSystem fileSystem = const LocalFileSystem(),
  List<InterceptorData> interceptors = const [],
  final SslData? https,
  final ReServeLoggerLevel log = ReServeLoggerLevel.config,
  final Uri? origin,
  required final String path,
  @JsonKey(fromJson: _fromInt) final int port = 5433,
  final String? proxy,
  required final Map<String, ReServeRoute> routes,
  final Map<String, dynamic> vars = const {},
}) {
  this {
    this.interceptors = interceptors
        .map((data) => Interceptor.create(data, config: this))
        .toList();
    hierarchicalLoggingEnabled = true;
    logger = Logger('Server');
    logger.level = log.level;

    for (final entry in routes.entries) {
      entry.value.path = entry.key;
    }
  }

  factory fromFile(File file, {String? prefix}) {
    final contents = yaon.parse(file.readAsStringSync());
    return ServerConfig.fromString(
      json.encode(prefix == null ? contents : contents[prefix]),
      fileSystem: file.fileSystem,
      path: file.absolute.path,
    );
  }

  factory fromJson(
    Map<String, dynamic> json, {
    FileSystem? fileSystem,
    required String path,
    required Map<String, dynamic> vars,
  }) => _$ServerConfigFromJson({
    ...json,
    'fileSystem': ?fileSystem,
    'path': path,
    'vars': vars,
  });

  factory fromString(
    String input, {
    FileSystem fileSystem = const LocalFileSystem(),
    required String path,
  }) {
    final parsed = yaon.parse(input);
    final syntax = TemplateSyntax.lookup(parsed['template-syntax']).syntax;
    final fsContext = FileSystemFunctions(fs: fileSystem).functions;

    final vars =
        (parsed['vars'] as Map<String, dynamic>? ?? const <String, dynamic>{})
            .map(
              (key, value) => MapEntry<String, dynamic>(
                key,
                Template(
                  value.toString(),
                  context: fsContext,
                  syntax: [syntax],
                ).evaluate(),
              ),
            );

    final result = Template(
      input,
      context: fsContext,
    ).process(context: {'vars': vars});
    return ServerConfig.fromJson(
      yaon.parse(result),
      fileSystem: fileSystem,
      path: path,
      vars: vars,
    );
  }

  late final List<Interceptor> interceptors;

  @JsonKey(includeFromJson: false)
  late final Logger logger;

  static FileSystem _fromFs(dynamic value) =>
      value is FileSystem ? value : const LocalFileSystem();

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
