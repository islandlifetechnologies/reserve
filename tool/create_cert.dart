// ignore_for_file: avoid_print

import 'dart:io';

import 'package:args/args.dart';

void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('common-name', abbr: 'c', defaultsTo: 'localhost')
    ..addOption('expires', abbr: 'e', defaultsTo: '30y')
    ..addOption('locality', abbr: 'l', defaultsTo: 'Woonsocket')
    ..addOption('organization', abbr: 'o', defaultsTo: 'CVS Health')
    ..addOption('ou', abbr: 'u', defaultsTo: 'https://cvs.com')
    ..addOption('path', abbr: 'p', defaultsTo: 'cert')
    ..addOption('state', abbr: 's', defaultsTo: 'RI')
    ..addFlag('dry-run');
  final parsed = parser.parse(args);

  final dryRun = parsed['dry-run'] == true;

  int days;
  final dayStr = parsed['expires'] as String;
  if (dayStr.endsWith('y')) {
    days = int.parse(dayStr.substring(0, dayStr.length - 1)) * 365;
  } else if (dayStr.endsWith('m')) {
    days = int.parse(dayStr.substring(0, dayStr.length - 1)) * 30;
  } else if (dayStr.endsWith('d')) {
    days = int.parse(dayStr.substring(0, dayStr.length - 1));
  } else {
    days = int.parse(dayStr);
  }

  final command = [
    'openssl',
    'req',
    '-x509',
    '-newkey',
    'rsa:4096',
    '-keyout',
    '${parsed['path']}/${parsed['common-name']}.key',
    '-out',
    '${parsed['path']}/${parsed['common-name']}.crt',
    '-days',
    '$days',
    '-noenc',
    '-subj',
    '/C=US/ST=${parsed['state']}/L=${parsed['locality']}/O=${parsed['organization']}/OU=${parsed['ou']}/CN=${parsed['common-name']}',
    '-addext',
    'subjectAltName=DNS:${parsed['common-name']},IP:127.0.0.1"',
  ];

  print('Running command:\n  ${command.join(' ')}');

  if (dryRun) {
    print('Dry run encountered; exiting');
    exit(0);
  } else {
    final result = Process.runSync(command[0], command.skip(1).toList());
    if (result.exitCode == 0) {
      print('Certificate and Private Key created');
    } else {
      print(result.stdout);
      print(result.stderr);
    }

    exit(result.exitCode);
  }
  // openssl req -x509 -newkey rsa:4096 -keyout server.key -out server.crt -days 365 -noenc -subj "/C=US/ST=California/L=SanFrancisco/O=MyCompany/CN=localhost"
}
