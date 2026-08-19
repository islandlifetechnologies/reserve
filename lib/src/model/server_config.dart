import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:reserve/reserve.dart';

part 'server_config.g.dart';

@JsonSerializable(createToJson: false)
class ServerConfig {
  ServerConfig({
    this.host = 'localhost',
    Map<String, dynamic>? headers,
    List<InterceptorData> interceptors = const [],
    this.https,
    this.port = 5433,
    this.proxy,
    InterceptorContainer? request,
    InterceptorContainer? response,
    required this.routes,
  }) : request = request ?? InterceptorContainer(),
       response = response ?? InterceptorContainer() {
    this.interceptors = interceptors
        .map((data) => Interceptor.create(data, config: this))
        .toList();
  }
  factory ServerConfig.fromJson(Map<String, dynamic> json) =>
      _$ServerConfigFromJson(json);

  final String host;
  final SslData? https;
  late final List<Interceptor> interceptors;
  final int port;
  final String? proxy;
  final InterceptorContainer request;
  final InterceptorContainer response;
  final List<ReServeRoute> routes;

  http.Client get client {
    final httpClient = HttpClient();
    if (proxy != null) {
      httpClient.findProxy = (uri) => 'PROXY $proxy';
      httpClient.badCertificateCallback = (_, _, _) => true;
    }

    return IOClient(httpClient);
  }
}

@JsonSerializable(createToJson: false)
class InterceptorContainer {
  InterceptorContainer({this.interceptors = const []});
  factory InterceptorContainer.fromJson(Map<String, dynamic> json) =>
      _$InterceptorContainerFromJson(json);

  final List<InterceptorData> interceptors;

  @JsonKey(includeFromJson: false)
  List<Interceptor>? _interceptors;

  List<Interceptor> getInterceptors(ServerConfig config) {
    final result =
        _interceptors ??
        interceptors
            .map((data) => Interceptor.create(data, config: config))
            .toList();

    _interceptors = result;

    return result;
  }
}
