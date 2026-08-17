import 'dart:io';

class Server {
  SecurityContext getSecurityContext() {
    // Bind with a secure HTTPS connection
    final chain = Platform.script
        .resolve('certificates/server_chain.pem')
        .toFilePath();
    final key = Platform.script
        .resolve('certificates/server_key.pem')
        .toFilePath();

    return SecurityContext()
      ..useCertificateChain(chain)
      ..usePrivateKey(key);
  }
}
