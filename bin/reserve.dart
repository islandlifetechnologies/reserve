import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:reserve/reserve.dart';
import 'package:reserve/src/server.dart';
import 'package:yaon/yaon.dart';

void main(List<String> args) async {
  hierarchicalLoggingEnabled = true;
  try {
    Logger.root.onRecord.listen((record) {
      // ignore: avoid_print
      print('${record.time}: ${record.level}: ${record.message}');
      for (final o in [record.error, record.stackTrace]) {
        if (o != null) {
          // ignore: avoid_print
          print(o.toString());
        }
      }
    });

    final parser = ArgParser()
      ..addOption(
        'config',
        abbr: 'c',
        help: 'Path to the configuration file.',
        defaultsTo: 'pubspec.yaml',
      )
      ..addFlag('watch', defaultsTo: true);

    final parsed = parser.parse(args);

    final configFile = File(parsed['config']);
    if (!configFile.existsSync()) {
      // ignore: avoid_print
      print('Unable to load configuration file: ${configFile.path}');
      exit(1);
    }

    Server? server;
    Future<void> restart() async {
      try {
        await server?.stop();
        final contents = yaon.parse(configFile.readAsStringSync());

        final config = ServerConfig.fromJson(contents['reserve'] ?? contents);

        server = Server(config: config);
        await server!.start();
      } catch (e, stack) {
        // ignore: avoid_print
        print('Error starting server\n$e\n$stack');
      }
    }

    configFile.watch().listen((_) => restart());

    await restart();
  } catch (e, stack) {
    // ignore: avoid_print
    print('Error starting server.\n$e\n$stack');
    exit(1);
  }
}
