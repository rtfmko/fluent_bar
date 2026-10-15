// Checks that every Dart example in the documentation compiles against the current API.
//
// Collects each ```dart block of README.md, AI_GUIDE.md, llms.txt, doc/*.md, doc/ai/*.md and
// ai/, and each ```dart block of a doc comment in lib/, writes it into test/_snippets as a
// file of its own, analyzes them and removes them again. doc/INTEGRATIONS.md is left out: its
// examples need packages fluent_bar does not depend on.
//
// Names that examples use without declaring them (loadFeed, crashReporter, ...) are declared
// in tool/snippets/stubs.dart. Run from the package root: `dart run tool/check_snippets.dart`.
import 'dart:io';

const String _outDir = 'test/_snippets';

const String _header = '''
// ignore_for_file: type=lint, unused_local_variable, unused_element, dead_code, unused_import, inference_failure_on_function_invocation, inference_failure_on_instance_creation, inference_failure_on_collection_literal, strict_raw_type, unnecessary_statements, unused_label
import 'dart:async';

import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';

import 'stubs.dart';

''';

class _Snippet {
  _Snippet(this.source, this.line, this.code);

  final String source;
  final int line;
  final String code;
}

Future<void> main() async {
  final List<_Snippet> snippets = <_Snippet>[for (final String path in _markdownFiles()) ..._markdownSnippets(path), for (final String path in _dartFiles('lib')) ..._docCommentSnippets(path)];

  final Directory out = Directory(_outDir);
  if (out.existsSync()) out.deleteSync(recursive: true);
  out.createSync(recursive: true);

  try {
    File('tool/snippets/stubs.dart').copySync('$_outDir/stubs.dart');
    final Map<String, _Snippet> byFile = <String, _Snippet>{};
    for (int i = 0; i < snippets.length; i++) {
      final String name = 's_${i.toString().padLeft(3, '0')}.dart';
      byFile[name] = snippets[i];
      final (String top, String body) = _split(snippets[i].code);
      File('$_outDir/$name').writeAsStringSync('$_header// ${snippets[i].source}:${snippets[i].line}\n$top\n\nFuture<void> snippet(BuildContext context) async {\n$body\n}\n');
    }

    final ProcessResult result = await Process.run(Platform.resolvedExecutable, <String>['analyze', '--fatal-infos', _outDir]);
    final List<String> problems = <String>[
      for (final String line in '${result.stdout}'.split('\n'))
        if (RegExp(r'^\s*(error|warning|info) -').hasMatch(line)) _describe(line, byFile),
    ];

    stdout.writeln('Checked ${snippets.length} snippets.');
    if (problems.isNotEmpty || result.exitCode != 0) {
      stdout.writeln(problems.isEmpty ? '${result.stdout}${result.stderr}' : problems.join('\n'));
      exitCode = 1;
    }
  } finally {
    out.deleteSync(recursive: true);
  }
}

List<String> _markdownFiles() => <String>[
  'README.md',
  'AI_GUIDE.md',
  'llms.txt',
  for (final String dir in <String>['doc', 'doc/ai']) ..._filesIn(dir, (String p) => p.endsWith('.md') && !p.endsWith('INTEGRATIONS.md')),
  ..._filesIn('ai', (String p) => p.endsWith('.md'), recursive: true),
];

List<String> _dartFiles(String dir) => _filesIn(dir, (String p) => p.endsWith('.dart'), recursive: true);

List<String> _filesIn(String dir, bool Function(String path) accept, {bool recursive = false}) {
  final Directory directory = Directory(dir);
  if (!directory.existsSync()) return <String>[];
  return directory.listSync(recursive: recursive).whereType<File>().map((File f) => f.path.replaceAll(r'\', '/')).where(accept).toList()..sort();
}

Iterable<_Snippet> _markdownSnippets(String path) sync* {
  final String text = File(path).readAsStringSync().replaceAll('\r\n', '\n');
  for (final RegExpMatch match in RegExp(r'```dart\n(.*?)```', dotAll: true).allMatches(text)) {
    yield _Snippet(path, '\n'.allMatches(text.substring(0, match.start)).length + 2, match.group(1)!);
  }
}

Iterable<_Snippet> _docCommentSnippets(String path) sync* {
  final List<String> lines = File(path).readAsStringSync().replaceAll('\r\n', '\n').split('\n');
  for (int i = 0; i < lines.length; i++) {
    if (!RegExp(r'^\s*/// ```dart\s*$').hasMatch(lines[i])) continue;
    final int start = i + 2;
    final List<String> body = <String>[];
    for (i++; i < lines.length && !RegExp(r'^\s*/// ```\s*$').hasMatch(lines[i]); i++) {
      body.add(lines[i].replaceFirst(RegExp(r'^\s*/// ?'), ''));
    }
    yield _Snippet(path, start, '${body.join('\n')}\n');
  }
}

/// Splits an example into top-level declarations (classes, enums, extensions, mixins), which stay
/// top-level, and the rest, which becomes the body of a function.
(String, String) _split(String code) {
  final List<String> lines = code.split('\n');
  final List<String> top = <String>[];
  final List<String> body = <String>[];
  final RegExp declaration = RegExp(r'^(abstract |final |base |sealed )*(class|enum|extension|mixin) \w');
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].startsWith("import '")) continue;
    if (!declaration.hasMatch(lines[i])) {
      body.add(lines[i]);
      continue;
    }
    int depth = 0;
    bool started = false;
    for (; i < lines.length; i++) {
      depth += '{'.allMatches(lines[i]).length - '}'.allMatches(lines[i]).length;
      started = started || lines[i].contains('{');
      top.add(lines[i]);
      if (started && depth == 0) break;
    }
  }
  return (top.join('\n'), body.join('\n'));
}

/// Rewrites an analyzer line so that it names the documentation file and line of the example.
String _describe(String line, Map<String, _Snippet> byFile) {
  final RegExpMatch? match = RegExp(r's_\d{3}\.dart').firstMatch(line);
  final _Snippet? snippet = match == null ? null : byFile[match.group(0)];
  return snippet == null ? line.trim() : '${snippet.source}:${snippet.line}: ${line.trim()}';
}
