import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:reserve/src/exception/fatal_exception.dart';
import 'package:template_expressions/template_expressions.dart';

part 'ssl_data.g.dart';

@JsonSerializable(createToJson: false)
class SslData {
  SslData({
    this.certChainPassword,
    this.privateKeyPassword,
    required this.type,
  });

  factory SslData.fromJson(Map<String, dynamic> json) {
    json = jsonDecode(Template(jsonEncode(json)).process());
    final type = json['type']?.toString().toLowerCase();

    if (type == null) {
      throw FatalException('A SSL configuration requires a type.');
    }

    final sslType = SslDataType.values
        .where((t) => type.toLowerCase() == t.name)
        .firstOrNull;
    if (sslType == null) {
      throw FatalException(
        'Unknown SSL configuration type encountered: $type.',
      );
    }

    return sslType.builder(json);
  }

  @JsonKey(name: 'certpass')
  String? certChainPassword;
  @JsonKey(name: 'keypass')
  String? privateKeyPassword;

  final String type;

  String get chainPem => throw UnimplementedError();
  String get privateKeyPem => throw UnimplementedError();

  Future<SecurityContext> getSecurityContext() async => SecurityContext()
    ..useCertificateChainBytes(
      utf8.encode(chainPem),
      password: certChainPassword,
    )
    ..usePrivateKeyBytes(
      utf8.encode(privateKeyPem),
      password: privateKeyPassword,
    );
}

@JsonSerializable(createToJson: false)
class SslDataFile extends SslData {
  SslDataFile({
    required this.certChain,
    super.certChainPassword,
    super.privateKeyPassword,
    required this.privateKey,
  }) : super(type: kType);

  factory SslDataFile.fromJson(Map<String, dynamic> json) =>
      _$SslDataFileFromJson(json);

  static final kType = 'file';

  @JsonKey(name: 'certfile')
  final String certChain;

  @JsonKey(name: 'keyfile')
  final String privateKey;

  late final String _chainPem;
  late final String _privateKeyPem;

  @override
  String get chainPem => _chainPem;
  @override
  String get privateKeyPem => _privateKeyPem;

  @override
  Future<SecurityContext> getSecurityContext() {
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

    _chainPem = chainFile.readAsStringSync();
    _privateKeyPem = privateKeyFile.readAsStringSync();

    return super.getSecurityContext();
  }
}

@JsonSerializable(createToJson: false)
class SslDataInline extends SslData {
  SslDataInline({
    required this.certChain,
    super.certChainPassword,
    super.privateKeyPassword,
    required this.privateKey,
  }) : super(type: kType);

  factory SslDataInline.fromJson(Map<String, dynamic> json) =>
      _$SslDataInlineFromJson(json);

  static final kType = 'inline';

  @JsonKey(name: 'cert')
  final String certChain;

  @JsonKey(name: 'key')
  final String privateKey;

  @override
  String get chainPem => certChain;
  @override
  String get privateKeyPem => privateKey;
}

@JsonSerializable(createToJson: false)
class SslDataZip extends SslData {
  SslDataZip({
    this.certChainName = 'localhost.direct.OP.crt',
    super.certChainPassword,
    super.privateKeyPassword,
    required this.path,
    this.privateKeyName = 'localhost.direct.OP.key',
    this.zipPassword,
  }) : super(type: kType);

  factory SslDataZip.fromJson(Map<String, dynamic> json) =>
      _$SslDataZipFromJson(json);

  static final kType = 'zip';

  @JsonKey(name: 'certfile')
  final String certChainName;
  final String path;
  @JsonKey(name: 'keyfile')
  final String privateKeyName;

  @JsonKey(name: 'zippass')
  final String? zipPassword;

  late final String _chainPem;
  late final String _privateKeyPem;

  @override
  String get chainPem => _chainPem;
  @override
  String get privateKeyPem => _privateKeyPem;

  @override
  Future<SecurityContext> getSecurityContext() async {
    final file = File(path);

    if (!file.existsSync()) {
      throw FatalException('Cannot locate certificate ZIP file: $path');
    }

    final archive = ZipDecoder().decodeBytes(
      file.readAsBytesSync(),
      password: zipPassword,
    );

    final chainFile = archive.files
        .where((f) => f.isFile && f.name.endsWith(certChainName))
        .firstOrNull;

    if (chainFile == null) {
      throw FatalException(
        'Cannot find file named "$certChainName" in ZIP file: $path',
      );
    }

    final privateKeyFile = archive.files
        .where((f) => f.isFile && f.name.endsWith(privateKeyName))
        .firstOrNull;

    if (privateKeyFile == null) {
      throw FatalException(
        'Cannot find file named "$privateKeyFile" in ZIP file: $path',
      );
    }

    _chainPem = utf8.decode(chainFile.readBytes()!);
    _privateKeyPem = utf8.decode(privateKeyFile.readBytes()!);

    return super.getSecurityContext();
  }
}

enum SslDataType {
  file(SslDataFile.fromJson),
  inline(SslDataInline.fromJson),
  zip(SslDataZip.fromJson);

  const SslDataType(this.builder);

  final SslData Function(Map<String, dynamic> json) builder;
}
