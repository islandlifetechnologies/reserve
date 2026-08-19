import 'package:json_annotation/json_annotation.dart';
import 'package:reserve/reserve.dart';

part 'reserve_listener.g.dart';

@JsonSerializable(createToJson: false)
class ReServeListener {
  ReServeListener({List<InterceptorData>? interceptors, required this.path})
    : interceptors = interceptors ?? const [];

  factory ReServeListener.fromJson(Map<String, dynamic> json) =>
      _$ReServeListenerFromJson(json);

  final List<InterceptorData> interceptors;
  final String path;

  @JsonKey(includeFromJson: false)
  List<Interceptor>? _interceptors;

  List<Interceptor> getInterceptors(ServerConfig config, ReServeRoute route) {
    final result =
        _interceptors ??
        interceptors
            .map(
              (data) => Interceptor.create(data, config: config, route: route),
            )
            .toList();

    _interceptors = result;

    return result;
  }
}
