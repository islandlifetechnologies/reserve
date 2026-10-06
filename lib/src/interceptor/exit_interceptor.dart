import 'dart:async';
import 'dart:io';

import 'package:reserve/reserve.dart';

/// Interceptor that exits the application with the given exit code.
class ExitInterceptor({required super.config, final int exitCode = 0})
    extends Interceptor {
  this : super(InterceptorType.exit);

  factory builder({
    required ServerConfig config,
    Map<String, dynamic>? params,
    ReServeRoute? route,
  }) => ExitInterceptor(
    config: config,
    exitCode: int.tryParse(params?['code'] ?? '') ?? 0,
  );

  @override
  FutureOr<(ReServeRequest, ReServeResponse?)> interceptRequest(
    ReServeRequest request,
  ) => exit(exitCode);

  @override
  FutureOr<ReServeResponse> interceptResponse(
    ReServeRequest request,
    ReServeResponse response,
  ) => exit(exitCode);
}
