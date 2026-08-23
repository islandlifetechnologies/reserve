import 'dart:async';

import 'package:reserve/reserve.dart';

abstract class ResponseInterceptor extends Interceptor {
  ResponseInterceptor(super.data, {required super.config, super.route});

  @override
  FutureOr<(ReServeRequest, ReServeResponse?)> interceptRequest(
    ReServeRequest request,
  ) => (request, null);
}
