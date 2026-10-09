import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  group('CookieResponseInterceptor', () {
    test('builder initializes with params', () {
      final config = ServerConfig(
        host: 'myhost.com',
        path: 'test.yaml',
        routes: const {},
      );

      final interceptor = CookieResponseInterceptor.builder(
        config: config,
        params: {'allow-secure': false},
      );

      expect(interceptor.allowSecure, isFalse);
    });

    test('returns response untouched if no set-cookie header present', () {
      final config = ServerConfig(
        host: 'myhost.com',
        path: 'test.yaml',
        routes: const {},
      );

      final interceptor = CookieResponseInterceptor(config: config);
      final request = ReServeRequest.empty();
      final response = ReServeResponse(
        bytes: Uint8List(0),
        headers: [ReServeHeader(key: 'content-type', value: 'text/html')],
        statusCode: 200,
      );

      final result = interceptor.interceptResponse(request, response);
      expect(result.headers.all.length, 1);
      expect(result.headers['content-type'], 'text/html');
    });

    test(r'updates cookie domain to .$host and preserves secure flag when allowSecure is true', () {
      final config = ServerConfig(
        host: 'myhost.com',
        path: 'test.yaml',
        routes: const {},
      );

      final interceptor = CookieResponseInterceptor(
        config: config,
        allowSecure: true,
      );

      final request = ReServeRequest.empty();
      final response = ReServeResponse(
        bytes: Uint8List(0),
        headers: [
          ReServeHeader(
            key: 'set-cookie',
            value: 'session=xyz; Domain=remote.com; Secure; HttpOnly',
          ),
        ],
        statusCode: 200,
      );

      final result = interceptor.interceptResponse(request, response);
      final cookieHeader = result.headers['set-cookie']!;
      expect(cookieHeader, contains('Domain=.myhost.com'));
      expect(cookieHeader, contains('Secure'));
      expect(cookieHeader, contains('HttpOnly'));
    });

    test('disables secure flag when allowSecure is false', () {
      final config = ServerConfig(
        host: 'myhost.com',
        path: 'test.yaml',
        routes: const {},
      );

      final interceptor = CookieResponseInterceptor(
        config: config,
        allowSecure: false,
      );

      final request = ReServeRequest.empty();
      final response = ReServeResponse(
        bytes: Uint8List(0),
        headers: [
          ReServeHeader(
            key: 'set-cookie',
            value: 'session=xyz; Domain=remote.com; Secure; HttpOnly',
          ),
        ],
        statusCode: 200,
      );

      final result = interceptor.interceptResponse(request, response);
      final cookieHeader = result.headers['set-cookie']!;
      expect(cookieHeader, contains('Domain=.myhost.com'));
      expect(cookieHeader, isNot(contains('Secure')));
    });

    test('uses config.origin host when available', () {
      final config = ServerConfig(
        host: 'localhost',
        origin: Uri.parse('https://origin.example.com:8443'),
        path: 'test.yaml',
        routes: const {},
      );

      final interceptor = CookieResponseInterceptor(config: config);
      final request = ReServeRequest.empty();
      final response = ReServeResponse(
        bytes: Uint8List(0),
        headers: [
          ReServeHeader(key: 'set-cookie', value: 'auth=token123; Path=/'),
        ],
        statusCode: 200,
      );

      final result = interceptor.interceptResponse(request, response);
      final cookieHeader = result.headers['set-cookie']!;
      expect(cookieHeader, contains('Domain=.origin.example.com'));
    });

    test('formats log table when logger is loggable at finest level', () {
      hierarchicalLoggingEnabled = true;
      final config = ServerConfig(
        host: 'localhost',
        log: ReServeLoggerLevel.finest,
        path: 'test.yaml',
        routes: const {},
      );

      final interceptor = CookieResponseInterceptor(config: config);
      interceptor.logger.level = Level.FINEST;

      final request = ReServeRequest.empty();
      final response = ReServeResponse(
        bytes: Uint8List(0),
        headers: [
          ReServeHeader(
            key: 'set-cookie',
            value: 'a_very_long_cookie_name_here=a_very_long_cookie_value_here; Path=/path; HttpOnly',
          ),
        ],
        statusCode: 200,
      );

      // Should not throw when formatting table
      final result = interceptor.interceptResponse(request, response);
      expect(result.headers['set-cookie'], isNotNull);
    });
  });
}
