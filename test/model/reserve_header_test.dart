import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  group('ReServeHeader', () {
    test('lowercases key automatically', () {
      final header = ReServeHeader(
        key: 'Content-Type',
        value: 'application/json',
      );
      expect(header.key, 'content-type');
      expect(header.value, 'application/json');
    });

    test('copyWith preserves or updates properties', () {
      final h = ReServeHeader(key: 'X-Original', value: 'orig');
      final c1 = h.copyWith(key: 'X-New', value: 'new');
      expect(c1.key, 'x-new');
      expect(c1.value, 'new');

      final c2 = h.copyWith();
      expect(c2.key, 'x-original');
      expect(c2.value, 'orig');
    });
  });

  group('ReServeHeaders', () {
    test('fromHeaders creates list of headers preserving multiples', () {
      final headers = ReServeHeaders.fromHeaders({
        'Accept': ['text/html', 'application/json'],
        'Host': ['localhost'],
      });

      expect(headers.all.length, 3);
      expect(headers['accept'], 'text/html');
      expect(headers['host'], 'localhost');
    });

    test('fromMap creates single header per map entry', () {
      final headers = ReServeHeaders.fromMap({'X-First': '1', 'X-Second': '2'});

      expect(headers.all.length, 2);
      expect(headers['x-first'], '1');
      expect(headers['x-second'], '2');
    });

    test('keys returns unique keys', () {
      final headers = ReServeHeaders([
        ReServeHeader(key: 'accept', value: 'text/html'),
        ReServeHeader(key: 'accept', value: 'application/json'),
        ReServeHeader(key: 'host', value: 'localhost'),
      ]);

      expect(headers.keys, unorderedEquals(['accept', 'host']));
    });

    test('operator [] returns null for missing key', () {
      final headers = ReServeHeaders([]);
      expect(headers['non-existent'], isNull);
    });

    test('immutability: []=, clear, and remove throw UnsupportedError', () {
      final headers = ReServeHeaders([ReServeHeader(key: 'foo', value: 'bar')]);

      expect(() => headers['foo'] = 'baz', throwsUnsupportedError);
      expect(() => headers.clear(), throwsUnsupportedError);
      expect(() => headers.remove('foo'), throwsUnsupportedError);
    });

    test('toMap joins multiple header values with comma', () {
      final headers = ReServeHeaders([
        ReServeHeader(key: 'accept', value: 'text/html'),
        ReServeHeader(key: 'accept', value: 'application/json'),
        ReServeHeader(key: 'host', value: 'localhost'),
      ]);

      final map = headers.toMap();
      expect(map['accept'], 'text/html,application/json');
      expect(map['host'], 'localhost');
    });

    test('toMapList collects all values per header into list', () {
      final headers = ReServeHeaders([
        ReServeHeader(key: 'accept', value: 'text/html'),
        ReServeHeader(key: 'accept', value: 'application/json'),
        ReServeHeader(key: 'host', value: 'localhost'),
      ]);

      final mapList = headers.toMapList();
      expect(mapList['accept'], ['text/html', 'application/json']);
      expect(mapList['host'], ['localhost']);
    });
  });
}
