import 'package:json_annotation/json_annotation.dart';
import 'package:reserve/reserve.dart';

part 'reserve_redirector.g.dart';

@JsonSerializable()
class ReServeRedirector {
  ReServeRedirector({List<InterceptorData>? interceptors, required this.uri})
    : interceptors = List.unmodifiable(interceptors ?? []);

  factory ReServeRedirector.fromJson(Map<String, dynamic> json) =>
      _$ReServeRedirectorFromJson(json);

  final List<InterceptorData> interceptors;
  final Uri uri;

  Map<String, dynamic> toJson() => _$ReServeRedirectorToJson(this);
}
