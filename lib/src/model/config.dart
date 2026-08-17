import 'package:json_annotation/json_annotation.dart';
import 'package:reserve/src/model/reserve_route.dart';

part 'config.g.dart';

@JsonSerializable()
class Config {
  Config({required this.routes});

  final List<ReServeRoute> routes;
}
