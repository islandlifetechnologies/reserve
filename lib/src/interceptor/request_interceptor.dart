import 'dart:async';

import 'package:reserve/reserve.dart';

abstract class RequestInterceptor extends Interceptor {
  RequestInterceptor(super.data, {required super.config, super.route});

  @override
  FutureOr<ReServeResponse> interceptResponse(
    ReServeRequest request,
    ReServeResponse response,
  ) => response;
}
