import 'package:logging/logging.dart';
import 'package:reserve/reserve.dart';

typedef InterceptorBuilder =
    Interceptor Function(
      InterceptorData data, {
      required ServerConfig config,
      ReServeRoute? route,
    });

abstract class Interceptor {
  Interceptor(this.data, {required this.config, this.route})
    : logger = Logger(
        '${(route?.logger ?? config.logger).name} [${data.type}]',
      ),
      type = data.type;

  static final Map<String, InterceptorBuilder> registry = {
    CookieResponseInterceptor.kType: CookieResponseInterceptor.new,
    CorsInterceptor.kType: CorsInterceptor.new,
    RedirectResponseInterceptor.kType: RedirectResponseInterceptor.new,
    RemoveHeadersInterceptor.kType: RemoveHeadersInterceptor.new,
    SetHeadersInterceptor.kType: SetHeadersInterceptor.new,
  };

  final ServerConfig config;
  final InterceptorData data;
  final Logger logger;
  final ReServeRoute? route;
  final String type;

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

  (ReServeRequest, ReServeResponse?) interceptRequest(ReServeRequest request);

  ReServeResponse interceptResponse(
    ReServeRequest request,
    ReServeResponse response,
  );

  String replaceUrl(String url, {required ReServeRoute route}) {
    final routeTo = route.redirect;

    var path = routeTo.path;
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    final result = Uri.parse(
      '${config.https == null ? 'http' : 'https'}://${config.host}${[80, 443].contains(config.port) ? '' : ':${config.port}'}$path',
    );

    return result.toString();
  }
}
