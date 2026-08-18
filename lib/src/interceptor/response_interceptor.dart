import 'package:reserve/reserve.dart';

abstract class ResponseInterceptor extends Interceptor {
  ResponseInterceptor(super.data, {required super.config, super.route});

  @override
  ReServeRequest interceptRequest(ReServeRequest request) => request;
}
