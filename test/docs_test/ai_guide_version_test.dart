import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final String version = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1)!;

  String head(File file) => file.readAsLinesSync().take(12).join('\n');

  test('AI_GUIDE.md names the version of the package', () {
    expect(head(File('AI_GUIDE.md')), contains('Version: $version.'));
  });

  test('every file in doc/ai names the version of the package', () {
    final List<File> files = Directory('doc/ai').listSync().whereType<File>().where((File f) => f.path.endsWith('.md')).toList();

    expect(files, isNotEmpty);
    for (final File file in files) {
      expect(head(file), contains('Version: $version.'), reason: file.path);
    }
  });
}
