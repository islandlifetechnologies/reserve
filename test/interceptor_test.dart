import 'dart:typed_data';

import 'package:reserve/reserve.dart';
import 'package:reserve/src/interceptor/interceptor.dart';
import 'package:test/test.dart';

void main() {
  final config = ServerConfig(host: 'example.com', port: 5433);

  group(RedirectResponseInterceptor.kType, () {
    final interceptor = RedirectResponseInterceptor(
      InterceptorData(type: RedirectResponseInterceptor.kType),
      config: config,
      route: ReServeRoute(
        listen: ReServeListener(path: '/baz'),
        redirect: ReServeRedirector(uri: Uri.parse('')),
      ),
    );

    final input = ReServeResponse(
      bytes: Uint8List(0),
      headers: [
        ReServeHeader(
          key: 'location',
          value: 'https://www.example.com:443/foo/bar',
        ),
      ],
      statusCode: 200,
    );

    final result = interceptor.interceptResponse(input);

    expect(
      result.headers.firstWhere((h) => h.key == 'location'),
      'http://example.com',
    );
  });
}
