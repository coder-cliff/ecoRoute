// Dart script to remove non‑ASCII characters (including emojis) from all Dart source files in the repo.
import 'dart:io';

final RegExp nonAscii = RegExp(r'[^\x00-\x7F]');

Future<void> main() async {
  final libDir = Directory('lib');
  if (!await libDir.exists()) {
    print('lib directory not found');
    exit(1);
  }
  final dartFiles = await libDir
      .list(recursive: true)
      .where((e) => e is File && e.path.endsWith('.dart'))
      .cast<File>()
      .toList();
  for (final file in dartFiles) {
    final original = await file.readAsString();
    final cleaned = original.replaceAll(nonAscii, '');
    if (original != cleaned) {
      await file.writeAsString(cleaned);
      print('Cleaned ${file.path}');
    }
  }
  print('Emoji removal complete (${dartFiles.length} files scanned).');
}
