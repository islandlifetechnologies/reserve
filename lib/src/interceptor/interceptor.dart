import 'dart:io';

import 'package:reserve/reserve.dart';

typedef InterceptorBuilder =
    Interceptor Function(
      InterceptorData data, {
      required ServerConfig config,
      ReServeRoute? route,
    });

abstract class Interceptor {
  Interceptor(this.data, {required this.config, this.route});

  static final Map<String, InterceptorBuilder> registry = {
    CookieResponseInterceptor.kType: CookieResponseInterceptor.new,
    RedirectResponseInterceptor.kType: RedirectResponseInterceptor.new,
  };

  final ServerConfig config;
  final InterceptorData data;
  final ReServeRoute? route;

  static Interceptor create(
    InterceptorData data, {
    required ServerConfig config,
    ReServeRoute? route,
  }) {
    final builder = registry[data.type];
    if (builder == null) {
      throw FatalException('''
Interceptor not found for type: [${data.type}]

If this is a custom interceptor, be sure to register the interceptor on the
registry.  For example:

// Register a custom interceptor
Interceptor.registry['${data.type}'] = MyCustomInterceptor.new;
''');
    }

    return builder(data, config: config, route: route);
  }

  static bool parseBool(dynamic input, {bool defaultsTo = false}) {
    var result = defaultsTo;

    if (input is bool) {
      result = input;
    } else if (input is String) {
      result = 'true' == input.toLowerCase().toString();
    }

    return result;
  }

  ReServeRequest interceptRequest(ReServeRequest request);
  ReServeResponse interceptResponse(ReServeResponse response);

  String replaceUrl(String url, {required ReServeRoute route}) {
    final input = Uri.parse(url);
    final routeTo = route.redirect.uri;

    var path = input.path.replaceFirst(
      route.redirect.uri.path,
      route.listen.path,
    );
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    final result = Uri.parse(
      '${routeTo.scheme}://$route${[80, 443].contains(config.port) ? '' : ':${config.port}$path'}',
    );

    return result.toString();
  }
}

abstract class RequestInterceptor extends Interceptor {
  RequestInterceptor(super.data, {required super.config, super.route});

  @override
  ReServeResponse interceptResponse(ReServeResponse response) => response;
}

abstract class ResponseInterceptor extends Interceptor {
  ResponseInterceptor(super.data, {required super.config, super.route});

  @override
  ReServeRequest interceptRequest(ReServeRequest request) => request;
}

class CookieResponseInterceptor extends ResponseInterceptor {
  CookieResponseInterceptor(super.data, {required super.config, super.route})
    : allowSecure = Interceptor.parseBool(data.params[_kParamAllowSecure]);

  static const kType = 'cookie';
  static const _kHeaderName = 'set-cookie';
  static const _kParamAllowSecure = 'allow-secure';

  final bool allowSecure;

  @override
  ReServeResponse interceptResponse(ReServeResponse response) {
    final headers = response.headers.where((h) => h.key == _kHeaderName);

    final cookies = <Cookie>[];

    for (final header in headers) {
      cookies.add(Cookie.fromSetCookieValue(header.value));
    }

    final result = List<ReServeHeader>.from(response.headers)
      ..removeWhere((h) => h.key == _kHeaderName)
      ..addAll(
        cookies.map(
          (c) => ReServeHeader(key: _kHeaderName, value: c.toString()),
        ),
      );

    return response.copyWith(headers: result);
  }
}

class RedirectResponseInterceptor extends ResponseInterceptor {
  RedirectResponseInterceptor(super.data, {required super.config, super.route})
    : assert(route != null),
      _route = route!;

  static const kType = 'redirect';
  static const _kHeaderName = 'location';

  final ReServeRoute _route;

  @override
  ReServeResponse interceptResponse(ReServeResponse response) {
    final headers = response.headers.where((h) => h.key == _kHeaderName);

    final result = List<ReServeHeader>.from(response.headers)
      ..removeWhere((h) => h.key == _kHeaderName)
      ..addAll(
        headers.map(
          (h) => ReServeHeader(
            key: _kHeaderName,
            value: replaceUrl(h.value, route: _route),
          ),
        ),
      );

    return response.copyWith(headers: result);
  }
}
