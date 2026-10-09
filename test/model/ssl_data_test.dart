import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  group('SslData', () {
    test('fromJson deserializes correctly', () {
      final json = {
        'certfile': 'path/to/cert.pem',
        'certpass': 'certsecret',
        'keyfile': 'path/to/key.pem',
        'keypass': 'keysecret',
      };

      final ssl = SslData.fromJson(json);
      expect(ssl.certChain, 'path/to/cert.pem');
      expect(ssl.certChainPassword, 'certsecret');
      expect(ssl.privateKey, 'path/to/key.pem');
      expect(ssl.privateKeyPassword, 'keysecret');
    });

    test('getSecurityContext throws FatalException if certfile missing', () {
      final ssl = SslData(
        certChain: 'non_existent_cert.pem',
        privateKey: 'non_existent_key.pem',
      );

      expect(
        () => ssl.getSecurityContext(),
        throwsA(
          isA<FatalException>().having(
            (e) => e.message,
            'message',
            contains('Cannot find certificate chain file'),
          ),
        ),
      );
    });
  });
}
