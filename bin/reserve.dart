// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:embed_annotation/embed_annotation.dart';
import 'package:logging/logging.dart';
import 'package:reserve/reserve.dart';
import 'package:reserve/src/server.dart';
import 'package:yaon/yaon.dart';

part 'reserve.g.dart';

@EmbedLiteral('../pubspec.yaml')
const pubspec = _$pubspec;

void main(List<String> args) async {
  hierarchicalLoggingEnabled = true;
  try {
    Logger.root.onRecord.listen((record) {
      print('${record.time}: ${record.level}: ${record.message}');
      for (final o in [record.error, record.stackTrace]) {
        if (o != null) {
          print(o.toString());
        }
      }
    });
    Logger.root.level = Level.ALL;
    final logger = Logger('main');

    final parser = ArgParser()
      ..addOption('config', abbr: 'c', help: 'Path to the configuration file.')
      ..addOption(
        'log',
        abbr: 'l',
        allowed: Level.LEVELS.map((l) => l.name.toLowerCase()),
        defaultsTo: Level.INFO.name,
        help: 'The log level for the startup portion of the server.',
      )
      ..addOption(
        'root',
        abbr: 'r',
        help: 'Root key for the configuration data in the file.',
      )
      ..addFlag(
        'help',
        abbr: 'h',
        negatable: false,
        help: 'Print the usage information and exit.',
      )
      ..addFlag(
        'version',
        negatable: false,
        help: 'Print the current version and exit.',
      )
      ..addFlag(
        'watch',
        defaultsTo: true,
        help: 'Watch the config file for changes and auto-reload when it does.',
      );

    final parsed = parser.parse(args);

    final level =
        Level.LEVELS
            .where((l) => l.name.toLowerCase() == parsed['log']?.toLowerCase())
            .firstOrNull ??
        Level.INFO;

    logger.level = level;
    final root = parsed['root']?.toString();
    final watch = parsed['watch'] == true;
    final isHelp = parsed['help'] == true;
    final isVersion = parsed['version'] == true;

    if (isHelp || isVersion) {
      print('reserve: ${pubspec.version}');
      if (isHelp) {
        print('\nUsage:');
        print(parser.usage);
      }
      exit(0);
    }

    final searchPath = [
      ('reserve.yaml', root),
      ('web_dev_config.yaml', root ?? 'reserve'),
      ('pubspec_overrides.yaml', root ?? 'reserve'),
      ('pubspec.yaml', root ?? 'reserve'),
    ];
    final configArg = parsed['config']?.toString();
    if (configArg != null) {
      searchPath.insert(0, (configArg, root));
    }

    (File, String?)? found;

    for (final (path, prefix) in searchPath) {
      final file = File(path);
      if (file.existsSync()) {
        logger.fine('Looking for configuration in file: ${file.path}');
        try {
          var contents = yaon.parse(file.readAsStringSync());
          if (prefix != null) {
            contents = contents[prefix];
          }
          logger.finest(const JsonEncoder.withIndent('  ').convert(contents));

          // The "routes" key is required for a configuration to be valid.  So,
          // look for it and if it doesn't exist, move on to the next item.
          if (contents['routes'] != null) {
            found = (file, prefix);
            logger.config(
              'Found ReServe configuration: @ ${file.path}; root: [${prefix ?? ''}]',
            );
            break;
          }
        } catch (_) {
          // no op, try next file
        }
      }
    }

    if (found == null) {
      print(
        'Unable to find valid configuration in search path: ${searchPath.map((entry) => entry.$1)}',
      );
      exit(1);
    }

    final (configFile, prefix) = found;

    Server? server;
    Future<void> restart() async {
      try {
        logger.config('File change detected, shutting down server.');
        await server?.stop();
        final contents = yaon.parse(configFile.readAsStringSync());
        final config = ServerConfig.fromString(
          json.encode(prefix == null ? contents : contents[prefix]),
        );
        logger.config('Configuration successfully reloaded.');

        server = Server(config: config);
        await server!.start();
      } catch (e, stack) {
        print('Error starting server\n$e\n$stack');
      }
    }

    if (watch) {
      configFile.watch().listen((_) => restart());
    }

    await restart();
  } catch (e, stack) {
    print('Error starting server.\n$e\n$stack');
    exit(1);
  }
}
