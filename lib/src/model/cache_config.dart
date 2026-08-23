import 'package:json_annotation/json_annotation.dart';
import 'package:reserve/src/model/reserve_logger_level.dart';

part 'cache_config.g.dart';

@JsonSerializable(createToJson: false)
class CacheConfig {
  const CacheConfig({
    this.log = ReServeLoggerLevel.info,
    this.mixedThreshold = 1000000,
    this.path = 'cache',
    required this.persistMode,
    this.persistTime = const Duration(hours: 1),
    this.sweepTime = const Duration(minutes: 1),
  });
  factory CacheConfig.fromJson(Map<String, dynamic> json) =>
      _$CacheConfigFromJson(json);

  final ReServeLoggerLevel log;
  final int mixedThreshold;
  final String path;
  final CachePersistMode persistMode;

  @JsonKey(fromJson: _durationFromJson)
  final Duration persistTime;
  @JsonKey(fromJson: _durationFromJson)
  final Duration sweepTime;
}

enum CachePersistMode {
  memory,
  mixed,
  file;

  static CachePersistMode lookup(String? key) =>
      CachePersistMode.values
          .where((e) => e.name == key?.toLowerCase())
          .firstOrNull ??
      CachePersistMode.memory;
}

Duration _durationFromJson(dynamic value) {
  Duration result;
  if (value is Duration) {
    result = value;
  } else if (value is num) {
    result = Duration(seconds: value.toInt());
  } else {
    result = Duration(seconds: int.parse(value.toString()));
  }

  return result;
}
