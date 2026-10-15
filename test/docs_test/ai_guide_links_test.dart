import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final RegExp link = RegExp(r'\]\(([^)\s]+)\)');

  List<File> guideFiles() => <File>[
    File('AI_GUIDE.md'),
    ...Directory('doc/ai').listSync().whereType<File>().where((File f) => f.path.endsWith('.md')),
    ...Directory('ai').listSync(recursive: true).whereType<File>().where((File f) => f.path.endsWith('.md') || f.path.endsWith('.mdc')),
  ];

  test('every relative link in the AI guide leads to a file of the package', () {
    for (final File file in guideFiles()) {
      for (final RegExpMatch match in link.allMatches(file.readAsStringSync())) {
        final String target = match.group(1)!.split('#').first;
        if (target.isEmpty || target.contains('://')) continue;
        final String path = '${file.parent.path}/$target';
        expect(File(path).existsSync() || Directory(path).existsSync(), isTrue, reason: '${file.path} -> $target');
      }
    }
  });

  test('the index of AI_GUIDE.md names every file in doc/ai', () {
    final String index = File('AI_GUIDE.md').readAsStringSync();
    for (final File file in Directory('doc/ai').listSync().whereType<File>().where((File f) => f.path.endsWith('.md'))) {
      final String name = file.uri.pathSegments.last;
      expect(index, contains('](doc/ai/$name)'), reason: name);
    }
  });

  test('the AI guide does not point at numbered sections that no longer exist', () {
    for (final File file in guideFiles()) {
      expect(file.readAsStringSync(), isNot(matches(RegExp(r'\bsection \d+\b'))), reason: file.path);
    }
  });
}
