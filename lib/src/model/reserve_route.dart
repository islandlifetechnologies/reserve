import 'package:json_annotation/json_annotation.dart';
import 'package:reserve/reserve.dart';

part 'reserve_route.g.dart';

@JsonSerializable()
class ReServeRoute {
  ReServeRoute({
    required this.listen,
    Map<String, dynamic>? headers,
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
  final ReServeRedirector redirect;

  Map<String, dynamic> toJson() => _$ReServeRouteToJson(this);
}
