import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:reserve/reserve.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:test/test.dart';

void main() {
  final testCerts = Directory('cert').existsSync();

  test('file', () async {
    final https = SslData.fromJson({
      'type': SslDataFile.kType,
      'cert-chain': 'cert/localhost.direct.SS.crt',
      'private-key': 'cert/localhost.direct.SS.key',
    });

    expect(https is SslDataFile, true);
    final context = await https.getSecurityContext();

    expect(context, isNotNull);
  }, skip: !testCerts);

  test('zip', () async {
    final https = SslData.fromJson({
      'type': SslDataZip.kType,
      'path': 'cert/localhost.direct.SS.zip',
      'zip-password': r'${env.LOCALHOST_CERT_PW}',
    });

    expect(https is SslDataZip, true);
    final context = await https.getSecurityContext();

    expect(context, isNotNull);
  }, skip: !testCerts);

  test('cert valid', () async {
    final https = SslData.fromJson({
      'type': SslDataFile.kType,
      'cert-chain': 'cert/localhost.ilt.run.cer',
      'private-key': 'cert/localhost.ilt.run.key',
    });

    HttpServer? server;
    try {
      server = await serve(
        (req) => Response.ok('OK'),
        'localhost.direct',
        8443,
        securityContext: await https.getSecurityContext(),
      );
      final response = await http.get(
        Uri.parse('https://localhost.ilt.run:8443'),
      );
      expect(response.statusCode, 200);
      expect(response.body, 'OK');
    } finally {
      // ignore: unawaited_futures
      server?.close();
    }
  }, skip: !testCerts);
}
