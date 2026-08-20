import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';
import 'package:reserve/reserve.dart';

part 'reserve_route.g.dart';

@JsonSerializable(createToJson: false)
class ReServeRoute {
  ReServeRoute({
    this.log = ReServeLoggerLevel.info,
    Map<String, dynamic>? headers,
    this.interceptors = const [],
    this.name,
    this.origin,
    String? path,
    required this.redirect,
  }) {
    if (path != null) {
      this.path = path;
    }
  }

  factory ReServeRoute.fromJson(Map<String, dynamic> json) =>
      _$ReServeRouteFromJson(json);

  final ReServeLoggerLevel log;
  final List<InterceptorData> interceptors;
  final String? name;
  final Uri? origin;
  final Uri redirect;

  @JsonKey(includeFromJson: false)
  List<Interceptor>? _interceptors;
  @JsonKey(includeFromJson: false)
  late Logger _logger;

  @JsonKey(includeFromJson: false)
  Logger get logger => _logger;

  @JsonKey(includeFromJson: false)
  late String _path;

  String get path => _path;
  set path(String path) {
    _path = path;
    _logger = Logger(path);
    _logger.level = log.level;
  }

  List<Interceptor> getInterceptors(ServerConfig config) {
    final result =
        _interceptors ??
        interceptors
            .map(
              (data) => Interceptor.create(data, config: config, route: this),
            )
            .toList();

    _interceptors = result;

    return result;
  }
}
