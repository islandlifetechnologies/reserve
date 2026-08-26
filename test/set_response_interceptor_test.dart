import 'dart:convert';

import 'package:file/memory.dart';
import 'package:logging/logging.dart';
import 'package:reserve/reserve.dart';
import 'package:template_expressions/template_expressions.dart';
import 'package:test/test.dart';

void main() {
  hierarchicalLoggingEnabled = true;
  setUpAll(() {
    final fs = MemoryFileSystem();
    fs.file('output.html')
      ..createSync(recursive: true)
      ..writeAsString(
        r'${vars.greeting}: ${vars.config.firstName} ${vars.config.lastName}!',
      );
    FileSystemFunctions.fileSystemOverride = fs;
  });

  tearDownAll(() {
    FileSystemFunctions.fileSystemOverride = null;
  });

  test('set-response', () async {
    final config = ServerConfig(
      routes: const {},
      vars: {
        'greeting': 'Hello',
        'config': {'firstName': 'Mickey', 'lastName': 'Mouse'},
      },
    );

    final interceptor = SetResponseRequestInterceptor(
      body: 'output.html',
      config: config,
      headers: {'content-type': 'text/html'},
    );

    final (_, response) = await interceptor.interceptRequest(
      ReServeRequest.empty(),
    );

    expect(utf8.decode(response!.bytes), 'Hello: Mickey Mouse!');
    expect(response.headers, {'content-type': 'text/html'});
    expect(response.statusCode, 200);
  });
}
