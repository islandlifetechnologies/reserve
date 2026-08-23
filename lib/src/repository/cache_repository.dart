import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:reserve/reserve.dart';

class CacheRepository {
  factory CacheRepository() => _instance;
  CacheRepository._();
  static final _instance = CacheRepository._();
  static final _logger = Logger('CacheRepository');

  final _cache = <String, CacheItem>{};

  late CacheConfig _config;
  Timer? _timer;
  TimeProvider _timeProvider = defaultTimeProvider;

  void initialize(
    CacheConfig config, {
    TimeProvider timeProvider = defaultTimeProvider,
  }) {
    _timeProvider = timeProvider;
    _cache.clear();
    _logger.level = config.log.level;
    _config = config;
    final dir = Directory(_config.path);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    dir.createSync(recursive: true);
    _timer?.cancel();
    _timer = Timer.periodic(_config.sweepTime, (_) => _sweep());
  }

  Future<ReServeResponse?> lookup(ReServeRequest request) async {
    final inm = request.headers['if-none-match'];
    try {
      if (inm == null) {
        return null;
      }
      final item = _cache[_getKey(inm, request.path)];
      return item == null
          ? null
          : ReServeResponse(
              bytes: await _getBytes(item),
              headers: ReServeHeaders.fromMap({'etag': inm}).all,
              statusCode: HttpStatus.notModified,
              timestamp: _timeProvider(),
            );
    } catch (e, stack) {
      _logger.warning(
        'Error looking up etag: [$inm], path: [${request.path}]',
        e,
        stack,
      );
    }
    return null;
  }

  Future<void> save(ReServeRequest request, ReServeResponse response) async {
    final bytes = response.bytes;
    final etag = response.headers['etag']!;
    final path = request.path;
    late final CacheItem item;

    switch (_config.persistMode) {
      case CachePersistMode.memory:
        item = CacheItem(
          created: _timeProvider(),
          data: bytes,
          etag: etag,
          path: path,
        );
        _logger.finest('Cached item: ${item.path} -- ${item.etag} to memory');
        break;
      case CachePersistMode.mixed:
        item = CacheItem(
          created: _timeProvider(),
          data: bytes.length >= _config.mixedThreshold ? null : bytes,
          etag: etag,
          path: path,
        );
        if (bytes.length >= _config.mixedThreshold) {
          await _getFile(item).writeAsBytes(bytes);
          _logger.finest('Cached item: ${item.path} -- ${item.etag} to file');
        } else {
          _logger.finest('Cached item: ${item.path} -- ${item.etag} to memory');
        }
        break;
      case CachePersistMode.file:
        item = CacheItem(
          created: _timeProvider(),
          data: null,
          etag: etag,
          path: path,
        );
        await _getFile(item).writeAsBytes(bytes);
        _logger.finest('Cached item: ${item.path} -- ${item.etag} to file');
        break;
    }

    _cache[_getKey(etag, path)] = item;
  }

  Future<Uint8List> _getBytes(CacheItem item) async {
    final bytes = item.data ?? await _getFile(item).readAsBytes();
    return bytes;
  }

  File _getFile(CacheItem item) => File('${item.path}.bin');

  String _getKey(String etag, String path) => '$etag|$path';

  void remove(CacheItem item) {
    _logger.finest('Removing cache item: ${item.path} -- ${item.etag}');
    if (item.data == null) {
      _getFile(item).deleteSync();
    }

    _cache.remove(_getKey(item.etag, item.path));
  }

  void _sweep() async {
    final expired =
        _timeProvider().millisecondsSinceEpoch -
        _config.persistTime.inMilliseconds;
    for (final item in _cache.values) {
      if (item.created.millisecondsSinceEpoch < expired) {
        _logger.finer('Expired cache item: ${item.path} -- ${item.etag}');
        remove(item);
      }
    }
  }
}
