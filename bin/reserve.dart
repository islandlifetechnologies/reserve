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
    Logger.root.level = Level.ALL;

    final parser = ArgParser()
      ..addOption('config', abbr: 'c', help: 'Path to the configuration file.')
      ..addFlag('watch', defaultsTo: true);

    final parsed = parser.parse(args);

    final searchPath = [
      ('config.yaml', null),
      ('pubspec_overrides.yaml', 'reserve'),
      ('pubspec.yaml', 'reserve'),
    ];
    final configArg = parsed['config']?.toString();
    if (configArg != null) {
      searchPath.insert(0, (configArg, null));
    }

    (File, String?)? found;

    for (final (path, prefix) in searchPath) {
      final file = File(path);
      if (file.existsSync()) {
        try {
          final contents = yaon.parse(file.readAsStringSync());
          if (prefix == null || contents[prefix] != null) {
            found = (file, prefix);
          }
        } catch (_) {
          // no op, try next file
        }
        break;
      }
    }

    if (found == null) {
      // ignore: avoid_print
      print(
        'Unable to find configuration file in search path: ${searchPath.map((entry) => entry.$1)}',
      );
      exit(1);
    }

    final (configFile, prefix) = found;

    Server? server;
    Future<void> restart() async {
      try {
        await server?.stop();
        final contents = yaon.parse(configFile.readAsStringSync());

        final config = ServerConfig.fromJson(
          prefix == null ? contents : contents[prefix],
        );

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
