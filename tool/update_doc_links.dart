// Points the documentation at the version in pubspec.yaml.
//
// Every link into this repository from the files that ship with the package (README.md,
// AI_GUIDE.md, llms.txt, doc/, ai/, example/README.md) names the release tag, `vX.Y.Z`, so that
// the docs of a version on pub.dev show that version and not what is on `main` meanwhile. The
// `Version:` line at the top of AI_GUIDE.md and of every doc/ai/*.md is set to the same version.
// Links to CONTRIBUTING.md stay on `main`: contributions always go there.
//
// Run from the package root after changing `version` in pubspec.yaml:
// `dart run tool/update_doc_links.dart`. test/docs_test/repo_links_test.dart checks the result.
import 'dart:io';

/// Matches a link into the repository and captures the ref and the path after it.
final RegExp repoLink = RegExp(r'(https://(?:github\.com/rtfmko/fluent_bar/(?:blob|tree)|raw\.githubusercontent\.com/rtfmko/fluent_bar)/)([^/\s)]+)((?:/[^\s)"`>]*)?)');

/// The files that ship with the package and may link into the repository.
List<File> docFiles() => <File>[
  for (final String path in <String>['README.md', 'AI_GUIDE.md', 'llms.txt', 'example/README.md']) File(path),
  for (final String dir in <String>['doc', 'ai'])
    ...Directory(dir).listSync(recursive: true).whereType<File>().where((File f) {
      final String path = f.path.replaceAll(r'\', '/');
      return !path.contains('doc/api/') && (path.endsWith('.md') || path.endsWith('.txt'));
    }),
].where((File f) => f.existsSync()).toList();

/// The ref a link with this [path] must name for package [version].
String refFor(String path, String version) => path.startsWith('/CONTRIBUTING.md') ? 'main' : 'v$version';

void main() {
  final String version = RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1)!;
  int changed = 0;

  for (final File file in docFiles()) {
    final String before = file.readAsStringSync();
    String after = before.replaceAllMapped(repoLink, (Match m) => '${m.group(1)}${refFor(m.group(3)!, version)}${m.group(3)}');
    final String path = file.path.replaceAll(r'\', '/');
    if (path == 'AI_GUIDE.md' || path.startsWith('doc/ai/')) {
      after = after.replaceFirst(RegExp(r'Version: \S+?\.(?=\s)'), 'Version: $version.');
    }
    if (after != before) {
      file.writeAsStringSync(after);
      changed++;
      stdout.writeln('updated $path');
    }
  }
  stdout.writeln('Docs point at v$version ($changed files changed).');
}
