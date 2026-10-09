import 'dart:io';

import 'package:reserve/reserve.dart';
import 'package:test/test.dart';

void main() {
  group('ReServeCookie', () {
    test('constructs and converts to string properly', () {
      final cookie = ReServeCookie(name: 'session', value: 'abc123xyz');

      expect(cookie.name, 'session');
      expect(cookie.value, 'abc123xyz');
      expect(cookie.httpOnly, isFalse);
      expect(cookie.secure, isFalse);
      expect(cookie.toString(), 'session=abc123xyz');
    });

    test('fromCookie parses dart:io Cookie', () {
      final ioCookie = Cookie('auth', 'token456')
        ..domain = 'example.com'
        ..httpOnly = true
        ..maxAge = 3600
        ..path = '/api'
        ..secure = true
        ..sameSite = SameSite.lax;

      final cookie = ReServeCookie.fromCookie(ioCookie);

      expect(cookie.name, 'auth');
      expect(cookie.value, 'token456');
      expect(cookie.domain, 'example.com');
      expect(cookie.httpOnly, isTrue);
      expect(cookie.maxAge, 3600);
      expect(cookie.path, '/api');
      expect(cookie.secure, isTrue);
      expect(cookie.sameSite, SameSite.lax);
    });

    test('copyWith copies or overrides all properties', () {
      final cookie = ReServeCookie(
        name: 'test',
        value: '1',
        domain: 'foo.com',
        httpOnly: false,
        secure: false,
      );

      final updated = cookie.copyWith(
        name: 'test2',
        value: '2',
        domain: 'bar.com',
        httpOnly: true,
        secure: true,
        maxAge: 120,
        path: '/sub',
        sameSite: SameSite.strict,
        expires: DateTime.utc(2030, 1, 1),
      );

      expect(updated.name, 'test2');
      expect(updated.value, '2');
      expect(updated.domain, 'bar.com');
      expect(updated.httpOnly, isTrue);
      expect(updated.secure, isTrue);
      expect(updated.maxAge, 120);
      expect(updated.path, '/sub');
      expect(updated.sameSite, SameSite.strict);
      expect(updated.expires, DateTime.utc(2030, 1, 1));
    });

    test('toString formats all attributes correctly', () {
      // Thursday, 19 Aug 2027 21:06:54 GMT
      final expires = DateTime.utc(2027, 8, 19, 21, 6, 54);
      final cookie = ReServeCookie(
        name: 'user_id',
        value: '42',
        domain: ' .example.com ',
        expires: expires,
        httpOnly: true,
        maxAge: 7200,
        path: ' /app ',
        sameSite: SameSite.strict,
        secure: true,
      );

      final str = cookie.toString();
      expect(str, startsWith('user_id=42; '));
      expect(str, contains('Expires=Thu, 19 Aug 2027 21:06:54 GMT'));
      expect(str, contains('Max-Age=7200'));
      expect(str, contains('Domain=.example.com'));
      expect(str, contains('Path=/app'));
      expect(str, contains('Secure'));
      expect(str, contains('HttpOnly'));
      expect(str, contains('SameSite=Strict'));
    });

    test(
      'toString formats single digit day, hour, minute, second in Expires',
      () {
        // Monday, 5 Jan 2026 03:04:05 GMT
        final expires = DateTime.utc(2026, 1, 5, 3, 4, 5);
        final cookie = ReServeCookie(name: 'c', value: 'v', expires: expires);

        final str = cookie.toString();
        expect(str, contains('Expires=Mon, 05 Jan 2026 03:04:05 GMT'));
      },
    );
  });
}
