import 'dart:typed_data';

class CacheItem {
  const CacheItem({
    required this.created,
    required this.data,
    required this.etag,
    required this.path,
  });

  final DateTime created;
  final Uint8List? data;
  final String etag;
  final String path;
}
