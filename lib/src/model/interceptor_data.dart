import 'package:json_annotation/json_annotation.dart';

part 'interceptor_data.g.dart';

@JsonSerializable()
class InterceptorData {
  InterceptorData({required this.type, Map<String, dynamic>? params})
    : params = params ?? {};
  factory InterceptorData.fromJson(Map<String, dynamic> json) =>
      _$InterceptorDataFromJson(json);

  final String type;

  @JsonKey(name: 'with')
  final Map<String, dynamic> params;

  Map<String, dynamic> toJson() => _$InterceptorDataToJson(this);
}
