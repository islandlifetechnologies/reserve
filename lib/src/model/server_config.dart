import 'package:json_annotation/json_annotation.dart';
import 'package:reserve/reserve.dart';

part 'server_config.g.dart';

@JsonSerializable()
class ServerConfig {
  ServerConfig({
    this.host = 'localhost',
    Map<String, dynamic>? headers,
    this.https,
    this.port = 5433,
  }) : headers = Map.unmodifiable(
         (headers ?? const {}).map(
           (key, value) => MapEntry<String, String>(key, value.toString()),
         ),
       );
  factory ServerConfig.fromJson(Map<String, dynamic> json) =>
      _$ServerConfigFromJson(json);

  final String host;
  final Map<String, String> headers;
  final SslData? https;
  final int port;

  Map<String, dynamic> toJson() => _$ServerConfigToJson(this);
}
