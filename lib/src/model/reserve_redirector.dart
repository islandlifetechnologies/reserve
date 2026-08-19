import 'package:json_annotation/json_annotation.dart';
import 'package:reserve/reserve.dart';

part 'reserve_redirector.g.dart';

@JsonSerializable(createToJson: false)
class ReServeRedirector {
  ReServeRedirector({List<InterceptorData>? interceptors, required this.uri})
    : interceptors = interceptors ?? const [];

  factory ReServeRedirector.fromJson(Map<String, dynamic> json) =>
      _$ReServeRedirectorFromJson(json);

  final List<InterceptorData> interceptors;
  final Uri uri;

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
