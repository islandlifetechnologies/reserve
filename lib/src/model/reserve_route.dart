import 'package:json_annotation/json_annotation.dart';
import 'package:reserve/reserve.dart';

part 'reserve_route.g.dart';

@JsonSerializable(createToJson: false)
class ReServeRoute {
  ReServeRoute({
    required this.listen,
    Map<String, dynamic>? headers,
    this.interceptors = const [],
    required this.redirect,
  }) : headers = Map.unmodifiable(
         (headers ?? const {}).map(
           (key, value) => MapEntry<String, String>(key, value.toString()),
         ),
       );

  factory ReServeRoute.fromJson(Map<String, dynamic> json) =>
      _$ReServeRouteFromJson(json);

  final ReServeListener listen;
  final Map<String, String> headers;
  final List<InterceptorData> interceptors;
  final ReServeRedirector redirect;

  @JsonKey(includeFromJson: false)
  List<Interceptor>? _interceptors;

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
