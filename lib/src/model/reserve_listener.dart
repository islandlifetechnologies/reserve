import 'package:json_annotation/json_annotation.dart';
import 'package:reserve/reserve.dart';

part 'reserve_listener.g.dart';

@JsonSerializable()
class ReServeListener {
  ReServeListener({List<InterceptorData>? interceptors, required this.path})
    : interceptors = List.unmodifiable(interceptors ?? []);

  factory ReServeListener.fromJson(Map<String, dynamic> json) =>
      _$ReServeListenerFromJson(json);

  final List<InterceptorData> interceptors;
  final String path;

  Map<String, dynamic> toJson() => _$ReServeListenerToJson(this);
}
