import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final String version = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1)!;
  final RegExp repoLink = RegExp(r'https://(?:github\.com/rtfmko/fluent_bar/(?:blob|tree)|raw\.githubusercontent\.com/rtfmko/fluent_bar)/([^/\s)]+)((?:/[^\s)"`>]*)?)');

  List<File> docFiles() => <File>[
    for (final String path in <String>['README.md', 'AI_GUIDE.md', 'llms.txt', 'example/README.md']) File(path),
    for (final String dir in <String>['doc', 'ai'])
      ...Directory(dir).listSync(recursive: true).whereType<File>().where((File f) {
        final String path = f.path.replaceAll(r'\', '/');
        return !path.contains('doc/api/') && (path.endsWith('.md') || path.endsWith('.txt'));
      }),
  ].where((File f) => f.existsSync()).toList();

  test('links into the repository name the release tag of the version in pubspec.yaml', () {
    final List<String> wrong = <String>[
      for (final File file in docFiles())
        for (final RegExpMatch match in repoLink.allMatches(file.readAsStringSync()))
          if (match.group(1) != (match.group(2)!.startsWith('/CONTRIBUTING.md') ? 'main' : 'v$version')) '${file.path}: ${match.group(0)}',
    ];

    expect(wrong, isEmpty, reason: 'Run `dart run tool/update_doc_links.dart`.');
  });

  test('links into the repository lead to files that exist', () {
    final List<String> missing = <String>[
      for (final File file in docFiles())
        for (final RegExpMatch match in repoLink.allMatches(file.readAsStringSync()))
          if (match.group(2)!.isNotEmpty && !_exists(match.group(2)!.split('#').first.split('?').first.substring(1))) '${file.path}: ${match.group(0)}',
    ];

    expect(missing, isEmpty);
  });

  test('the top entry of CHANGELOG.md is the version in pubspec.yaml', () {
    final String? top = RegExp(r'^## (\S+)', multiLine: true).firstMatch(File('CHANGELOG.md').readAsStringSync())?.group(1);

    expect(top, version);
  });
}

bool _exists(String path) => path.isEmpty || File(path).existsSync() || Directory(path).existsSync();
