import 'dart:convert';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:reserve/src/exception/fatal_exception.dart';

part 'ssl_data.g.dart';

@JsonSerializable(createToJson: false)
class SslData {
  SslData({
    required this.certChain,
    this.certChainPassword,
    required this.privateKey,
    this.privateKeyPassword,
  });

  factory SslData.fromJson(Map<String, String> json) => _$SslDataFromJson(json);

  @JsonKey(name: 'certfile')
  final String certChain;

  @JsonKey(name: 'certpass')
  final String? certChainPassword;

  @JsonKey(name: 'keyfile')
  final String privateKey;

  @JsonKey(name: 'keypass')
  final String? privateKeyPassword;

  SecurityContext getSecurityContext() {
    final chainFile = File(certChain);
    final privateKeyFile = File(privateKey);

    if (!chainFile.existsSync()) {
      throw FatalException('Cannot find certificate chain file: $certChain');
    }
    if (!privateKeyFile.existsSync()) {
      throw FatalException(
        'Cannot find certificate private key file: $privateKey',
      );
    }

    final chainPem = chainFile.readAsStringSync();
    final privateKeyPem = privateKeyFile.readAsStringSync();

    return SecurityContext()
      ..useCertificateChainBytes(
        utf8.encode(chainPem),
        password: certChainPassword,
      )
      ..usePrivateKeyBytes(
        utf8.encode(privateKeyPem),
        password: privateKeyPassword,
      );
  }
}
