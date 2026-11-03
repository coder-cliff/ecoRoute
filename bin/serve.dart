import 'dart:io';

void main() async {
  const port = 8080;
  final buildDir = Directory('build/web');

  if (!await buildDir.exists()) {
    stderr.writeln('build/web not found. Please run flutter build web first.');
    exit(1);
  }

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  stdout.writeln('EcoRoute Web Server running at http://localhost:$port');

  await for (HttpRequest request in server) {
    try {
      var path = request.uri.path;
      if (path == '/' || path.isEmpty) {
        path = '/index.html';
      }

      var file = File('${buildDir.path}$path');
      if (!await file.exists()) {
        file = File('${buildDir.path}/index.html');
      }

      final ext = file.path.split('.').last.toLowerCase();
      String contentType = 'application/octet-stream';
      if (ext == 'html') {
        contentType = 'text/html; charset=utf-8';
      } else if (ext == 'js') {
        contentType = 'application/javascript; charset=utf-8';
      } else if (ext == 'css') {
        contentType = 'text/css; charset=utf-8';
      } else if (ext == 'json') {
        contentType = 'application/json; charset=utf-8';
      } else if (ext == 'png') {
        contentType = 'image/png';
      } else if (ext == 'jpg' || ext == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (ext == 'svg') {
        contentType = 'image/svg+xml';
      } else if (ext == 'wasm') {
        contentType = 'application/wasm';
      } else if (ext == 'ttf') {
        contentType = 'font/ttf';
      }

      request.response.headers.contentType = ContentType.parse(contentType);
      await request.response.addStream(file.openRead());
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Server Error: $e');
      await request.response.close();
    }
  }
}
