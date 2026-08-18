import 'dart:io';

class ReServeCookie {
  ReServeCookie({
    this.domain,
    this.expires,
    this.httpOnly = false,
    this.maxAge,
    required this.name,
    this.path,
    this.sameSite,
    this.secure = false,
    required this.value,
  });

  factory ReServeCookie.fromCookie(Cookie cookie) => ReServeCookie(
    domain: cookie.domain,
    expires: cookie.expires,
    httpOnly: cookie.httpOnly,
    maxAge: cookie.maxAge,
    name: cookie.name,
    path: cookie.path,
    sameSite: cookie.sameSite,
    secure: cookie.secure,
    value: cookie.value,
  );

  final String? domain;
  final DateTime? expires;
  final bool httpOnly;
  final int? maxAge;
  final String name;
  final String? path;
  final SameSite? sameSite;
  final bool secure;
  final String value;

  ReServeCookie copyWith({
    String? domain,
    DateTime? expires,
    bool? httpOnly,
    int? maxAge,
    String? name,
    String? path,
    SameSite? sameSite,
    bool? secure,
    String? value,
  }) => ReServeCookie(
    domain: domain ?? this.domain,
    expires: expires ?? this.expires,
    httpOnly: httpOnly ?? this.httpOnly,
    maxAge: maxAge ?? this.maxAge,
    name: name ?? this.name,
    path: path ?? this.path,
    sameSite: sameSite ?? this.sameSite,
    secure: secure ?? this.secure,
    value: value ?? this.value,
  );

  @override
  String toString() {
    final out = StringBuffer();
    out
      ..write(name)
      ..write('=')
      ..write(value);

    void writeParameter(String name, Object? value) {
      out
        ..write('; ')
        ..write(name);
      if (value != null) {
        out
          ..write('=')
          ..write(value);
      }
    }

    final expires = this.expires;
    if (expires != null) {
      writeParameter('Expires', ''); // Writes empty value.
      _formatTo(expires, out);
    }
    if (maxAge != null) {
      writeParameter('Max-Age', maxAge);
    }
    final domain = this.domain;
    if (domain != null) {
      writeParameter('Domain', domain.trim());
    }
    final path = this.path;
    if (path != null) {
      writeParameter('Path', path.trim());
    }
    if (secure) writeParameter('Secure', null);
    if (httpOnly) writeParameter('HttpOnly', null);
    final sameSite = this.sameSite;
    if (sameSite != null) {
      writeParameter('SameSite', sameSite.name);
    }
    return out.toString();
  }

  String _formatTo(DateTime date, StringSink sb) {
    const weekdayAbbreviations = <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    const monthAbbreviations = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = date.toUtc();
    sb
      ..write(weekdayAbbreviations[d.weekday - 1])
      ..write(', ')
      ..write(d.day <= 9 ? '0' : '')
      ..write(d.day.toString())
      ..write(' ')
      ..write(monthAbbreviations[d.month - 1])
      ..write(' ')
      ..write(d.year.toString())
      ..write(d.hour <= 9 ? ' 0' : ' ')
      ..write(d.hour.toString())
      ..write(d.minute <= 9 ? ':0' : ':')
      ..write(d.minute.toString())
      ..write(d.second <= 9 ? ':0' : ':')
      ..write(d.second.toString())
      ..write(' GMT');
    return sb.toString();
  }
}
