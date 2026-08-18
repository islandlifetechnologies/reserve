import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:reserve/src/exception/fatal_exception.dart';

part 'ssl_data.g.dart';

@JsonSerializable()
class SslData {
  SslData({this.privateKeyPassword, required this.type});

  factory SslData.fromJson(Map<String, dynamic> json) {
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

    return switch (sslType) {
      SslDataType.file => SslDataFile.fromJson(json),
      SslDataType.zip => SslDataZip.fromJson(json),
    };
  }

  String? privateKeyPassword;
  final String type;

  String get chainPem => throw UnimplementedError();
  String get privateKeyPem => throw UnimplementedError();

  Future<SecurityContext> getSecurityContext() async => SecurityContext()
    ..useCertificateChain(chainPem)
    ..usePrivateKey(privateKeyPem, password: privateKeyPassword);

  Map<String, dynamic> toJson() => _$SslDataToJson(this);
}

@JsonSerializable()
class SslDataFile extends SslData {
  SslDataFile({
    required this.chain,
    super.privateKeyPassword,
    required this.privateKey,
  }) : super(type: kType);

  factory SslDataFile.fromJson(Map<String, dynamic> json) =>
      _$SslDataFileFromJson(json);

  static final kType = 'file';

  final String chain;
  final String privateKey;

  late final String _chainPem;
  late final String _privateKeyPem;

  @override
  String get chainPem => _chainPem;
  @override
  String get privateKeyPem => _privateKeyPem;

  @override
  Future<SecurityContext> getSecurityContext() {
    final chainFile = File(chain);
    final privateKeyFile = File(privateKey);

    if (!chainFile.existsSync()) {
      throw FatalException('Cannot find certificate chain file: $chain');
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

  @override
  Map<String, dynamic> toJson() => _$SslDataFileToJson(this);
}

@JsonSerializable()
class SslDataZip extends SslData {
  SslDataZip({
    this.chainName = 'localhost.direct.OP.crt',
    super.privateKeyPassword,
    this.privateKeyName = 'localhost.direct.OP.key',
    this.url = 'https://aka.re/localhost',
  }) : super(type: kType);

  factory SslDataZip.fromJson(Map<String, dynamic> json) =>
      _$SslDataZipFromJson(json);

  static final kType = 'file';

  final String chainName;
  final String privateKeyName;
  final String url;

  late final String _chainPem;
  late final String _privateKeyPem;

  @override
  String get chainPem => _chainPem;
  @override
  String get privateKeyPem => _privateKeyPem;

  @override
  Future<SecurityContext> getSecurityContext() async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      throw FatalException('Cannot locate certificate ZIP file: $url');
    }

    late final Archive archive;
    try {
      final filePath = uri.toFilePath();
      final file = File(filePath);

      if (!file.existsSync()) {
        throw FatalException(
          ('Certificate ZIP file does not exist: $filePath'),
        );
      }
      archive = ZipDecoder().decodeBytes(file.readAsBytesSync());
    } catch (_) {
      // it's not a File path...

      final response = await http.get(uri);
      if (response.statusCode >= 400) {
        throw FatalException(
          'Received status code: ${response.statusCode} from URL: $uri',
        );
      }
      archive = ZipDecoder().decodeBytes(response.bodyBytes);
    }

    final chainFile = archive.files
        .where((f) => f.isFile && f.name.endsWith(chainName))
        .firstOrNull;

    if (chainFile == null) {
      throw FatalException(
        'Cannot find file named "$chainName" in ZIP file: $url',
      );
    }

    final privateKeyFile = archive.files
        .where((f) => f.isFile && f.name.endsWith(privateKeyName))
        .firstOrNull;

    if (privateKeyFile == null) {
      throw FatalException(
        'Cannot find file named "$privateKeyFile" in ZIP file: $url',
      );
    }

    _chainPem = utf8.decode(chainFile.readBytes()!);
    _privateKeyPem = utf8.decode(privateKeyFile.readBytes()!);

    return super.getSecurityContext();
  }

  @override
  Map<String, dynamic> toJson() => _$SslDataZipToJson(this);
}

enum SslDataType { file, zip }
