import 'dart:async';

import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';
import 'package:reserve/reserve.dart';

typedef InterceptorBuilder =
    Interceptor Function({
      required ServerConfig config,
      Map<String, dynamic>? params,
      ReServeRoute? route,
    });

enum InterceptorType {
  cookie('cookie', CookieResponseInterceptor.builder),
  cors('cors', CorsInterceptor.builder),

  @JsonValue('remove-headers')
  removeHeaders('remove-headers', RemoveHeadersInterceptor.builder),

  @JsonValue('replace-body')
  replaceBody('replace-body', ReplaceBodyResponseInterceptor.builder),

  @JsonValue('replace-headers')
  replaceHeaders('replace-headers', ReplaceHeadersInterceptor.builder),

  @JsonValue('set-headers')
  setHeaders('set-headers', SetHeadersInterceptor.builder),

  @JsonValue('set-response')
  setResponse('set-response', SetResponseRequestInterceptor.builder);

  const InterceptorType(this.key, this.builder);

  final InterceptorBuilder builder;
  final String key;
}

abstract class Interceptor {
  Interceptor(
    this.type, {
    required this.config,
    this.params = const {},
    this.route,
  }) : logger = Logger(
         '${(route?.logger ?? config.logger).name} [${type.key}]',
       );

  final ServerConfig config;
  final Logger logger;
  final Map<String, dynamic> params;
  final ReServeRoute? route;
  final InterceptorType type;

  static Interceptor create(
    InterceptorData data, {
    required ServerConfig config,
    ReServeRoute? route,
  }) => data.type.builder(config: config, params: data.params, route: route);

  static T? maybeParseNum<T>(dynamic input) {
    dynamic result;

    if (input is String) {
      result = double.tryParse(input);
    } else if (input is num) {
      result = input;
    }

    if (result is num) {
      if (T == int) {
        result = result.toInt();
      } else if (T is double) {
        result = result.toDouble();
      }
    }

    return result;
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

  FutureOr<(ReServeRequest, ReServeResponse?)> interceptRequest(
    ReServeRequest request,
  );

  FutureOr<ReServeResponse> interceptResponse(
    ReServeRequest request,
    ReServeResponse response,
  );

  String replaceUrl(String url, {required ReServeRoute route}) {
    final routeTo = route.redirect;

    var path = routeTo.path;
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    final result = Uri.parse('${config.entrypoint}$path');

    return result.toString();
  }
}
