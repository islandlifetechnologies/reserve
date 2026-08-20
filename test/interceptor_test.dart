import 'dart:typed_data';

import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  group('cookie', () {
    test('single cookie', () {
      final config = ServerConfig(host: 'example.com', port: 8080, routes: {});
      const cookieStr =
          'user=312085%3A%dfdacmzbjLtridvDFwPlNs4N; path=/bar/baz; '
          'domain=.example.org;  expires=Tue, 17-Aug-2027 23:05:55 GMT; secure;'
          ' HttpOnly';
      final interceptor = CookieResponseInterceptor(
        InterceptorData(type: CookieResponseInterceptor.kType),
        config: config,
        route: ReServeRoute(
          path: '/foo',
          redirect: Uri.parse('https://www.example.org/bar'),
        ),
      );

      final input = ReServeResponse(
        bytes: Uint8List(0),
        headers: [ReServeHeader(key: 'set-cookie', value: cookieStr)],
        statusCode: 200,
      );

      final result = interceptor.interceptResponse(
        ReServeRequest.empty(),
        input,
      );

      expect(
        result.headers.firstWhere((h) => h.key == 'set-cookie').value,
        ReServeCookie(
          domain: '.example.com',
          expires: DateTime.utc(2027, 8, 17, 23, 05, 55),
          httpOnly: true,
          name: 'user',
          path: '/foo',
          secure: true,
          value: '312085%3A%dfdacmzbjLtridvDFwPlNs4N',
        ).toString(),
      );
    });

    test('disallow secure', () {
      final config = ServerConfig(host: 'example.com', port: 8080, routes: {});
      const cookieStr =
          'user=312085%3A%dfdacmzbjLtridvDFwPlNs4N; path=/bar/baz; '
          'domain=.example.org;  expires=Tue, 17-Aug-2027 23:05:55 GMT; secure;'
          ' HttpOnly';
      final interceptor = CookieResponseInterceptor(
        InterceptorData(
          params: {CookieResponseInterceptor.kParamAllowSecure: false},
          type: CookieResponseInterceptor.kType,
        ),
        config: config,
        route: ReServeRoute(
          path: '/foo',
          redirect: Uri.parse('https://www.example.org/bar'),
        ),
      );

      final input = ReServeResponse(
        bytes: Uint8List(0),
        headers: [ReServeHeader(key: 'set-cookie', value: cookieStr)],
        statusCode: 200,
      );

      final result = interceptor.interceptResponse(
        ReServeRequest.empty(),
        input,
      );

      expect(
        result.headers.firstWhere((h) => h.key == 'set-cookie').value,
        ReServeCookie(
          domain: '.example.com',
          expires: DateTime.utc(2027, 8, 17, 23, 05, 55),
          httpOnly: true,
          name: 'user',
          path: '/foo',
          secure: false,
          value: '312085%3A%dfdacmzbjLtridvDFwPlNs4N',
        ).toString(),
      );
    });

    test('multiple cookies', () {
      final config = ServerConfig(host: 'example.com', port: 8080, routes: {});
      const cookieStrs = [
        'user=312085%3A%dfdacmzbjLtridvDFwPlNs4N; path=/bar/baz; '
            'domain=.example.org;  expires=Tue, 17-Aug-2027 23:05:55 GMT; secure;'
            ' HttpOnly',
        'ad-id=this-user-accepted-all-cookies-ha-ha-ha-ha; '
            'path=/foo/annoying/ads; domain=www.example.org;  expires=Tue, '
            '17-Aug-2027 23:05:55 GMT',
      ];
      final interceptor = CookieResponseInterceptor(
        InterceptorData(type: CookieResponseInterceptor.kType),
        config: config,
        route: ReServeRoute(
          path: '/foo',
          redirect: Uri.parse('https://www.example.org/bar'),
        ),
      );

      final input = ReServeResponse(
        bytes: Uint8List(0),
        headers: [
          ...cookieStrs.map((c) => ReServeHeader(key: 'set-cookie', value: c)),
        ],
        statusCode: 200,
      );

      final result = interceptor.interceptResponse(
        ReServeRequest.empty(),
        input,
      );

      expect(
        result.headers.where((h) => h.key == 'set-cookie').map((c) => c.value),
        [
          ReServeCookie(
            domain: '.example.com',
            expires: DateTime.utc(2027, 8, 17, 23, 05, 55),
            httpOnly: true,
            name: 'user',
            path: '/foo',
            secure: true,
            value: '312085%3A%dfdacmzbjLtridvDFwPlNs4N',
          ).toString(),
          ReServeCookie(
            domain: '.example.com',
            expires: DateTime.utc(2027, 8, 17, 23, 05, 55),
            httpOnly: false,
            name: 'ad-id',
            path: '/foo',
            secure: false,
            value: 'this-user-accepted-all-cookies-ha-ha-ha-ha',
          ).toString(),
        ],
      );
    });
  });
  group('redirect', () {
    test('Check redirect', () {
      final config = ServerConfig(host: 'example.com', port: 8080, routes: {});
      final interceptor = RedirectResponseInterceptor(
        InterceptorData(type: RedirectResponseInterceptor.kType),
        config: config,
        route: ReServeRoute(
          path: '/foo',
          redirect: Uri.parse('https://www.example.com/foo'),
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

      final result = interceptor.interceptResponse(
        ReServeRequest.empty(),
        input,
      );

      expect(
        result.headers.firstWhere((h) => h.key == 'location').value,
        'http://example.com:8080/foo/bar',
      );
    });

    test('SSL', () {
      final config = ServerConfig(
        host: 'localhost.direct',
        https: SslData(type: ''),
        port: 443,
        routes: {},
      );
      final interceptor = RedirectResponseInterceptor(
        InterceptorData(type: RedirectResponseInterceptor.kType),
        config: config,
        route: ReServeRoute(
          path: '/foo',
          redirect: Uri.parse('https://www.example.com/foo'),
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

      final result = interceptor.interceptResponse(
        ReServeRequest.empty(),
        input,
      );

      expect(
        result.headers.firstWhere((h) => h.key == 'location').value,
        'https://localhost.direct/foo/bar',
      );
    });
  });
}
