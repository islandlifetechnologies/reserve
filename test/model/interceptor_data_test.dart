import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  group('InterceptorData', () {
    test('constructs with defaults', () {
      final data = InterceptorData(type: InterceptorType.cors);
      expect(data.type, InterceptorType.cors);
      expect(data.params, isEmpty);
    });

    test('fromJson and toJson round-trip', () {
      final json = {
        'type': 'replace-body',
        'with': {'from': 'foo', 'replace': 'bar'},
      };

      final data = InterceptorData.fromJson(json);
      expect(data.type, InterceptorType.replaceBody);
      expect(data.params['from'], 'foo');
      expect(data.params['replace'], 'bar');

      final serialized = data.toJson();
      expect(serialized['type'], 'replace-body');
      expect(serialized['with'], {'from': 'foo', 'replace': 'bar'});
    });
  });
}
