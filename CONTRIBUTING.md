# Contributing to fluent_bar

Thanks for taking the time. This page describes how the repository is organised and what a pull
request needs to pass.

## Branches

| Branch | Purpose |
|---|---|
| `main` | Always releasable. Protected: no direct pushes, changes arrive through pull requests with green checks. |
| `feat/<name>`, `fix/<name>`, `docs/<name>`, `chore/<name>` | Short-lived branches cut from `main`, one topic each. Deleted after merge. |

Releases are tags on `main` named `vX.Y.Z` (the same version as in `pubspec.yaml` and the top entry
of `CHANGELOG.md`). There is no long-lived `develop` branch. See [Releasing](#releasing).

Pull requests are squash-merged, so the title becomes the commit on `main`. Write it as a short
imperative sentence, optionally prefixed with the kind of change: `fix: keep bottom bars above the keyboard`.

## Before you open a pull request

```sh
flutter pub get
dart format lib test example/lib tool
flutter analyze
dart run tool/check_snippets.dart   # every dart example in the docs compiles
flutter test
cd example && flutter analyze
```

CI runs these on every pull request, plus the example tests, `dart doc --dry-run`,
`flutter pub publish --dry-run`, the tests on the minimum Flutter and a web build of the example; `main` cannot be merged into while they fail.

- **Tests.** A bug fix comes with a test that fails without it. A new feature comes with tests for
  its behaviour and edge cases. The suite is expected to stay green and coverage should not drop.
- **Example.** Anything a user can see or call gets a place in the example app
  (`example/lib/screens/`), with the code snippet shown next to it.
- **Docs.** Public API changes are reflected in `README.md`, the topic file in `doc/ai/` (and
  `AI_GUIDE.md` when a rule changes) and `CHANGELOG.md` (under the next version).
- **Style.** The analyzer configuration in `analysis_options.yaml` is the source of truth. Match
  the surrounding code: explicit types, package imports, no relative imports inside `lib/`.

## Project layout

| Path | Contents |
|---|---|
| `lib/fluent_bar.dart` | public exports |
| `lib/src/facade/` | `FluentBar` (static API) and `FluentBarScope` |
| `lib/src/extensions/` | the chain and entry shortcuts |
| `lib/src/models/`, `lib/src/interfaces/` | data classes, controller, themes, types |
| `lib/src/manager/` | queue, lifecycle, overlay, relocation, analytics |
| `lib/src/widgets/` | the bar widgets and inset reporters |
| `test/` | unit and widget tests, grouped by area |
| `example/` | the demo app, also deployed to GitHub Pages |
| `AI_GUIDE.md`, `doc/ai/`, `ai/`, `llms.txt` | material for AI coding assistants: the index, the topic files, the pointer for agents (`ai/AGENTS.md`), the link list |

## Design rules worth knowing

- Every setting resolves in one order: the bar, then its type, then the global config.
- User code (callbacks, builders, themes, types) is never trusted: call it through the error
  handler so a throw is reported and replaced by a default.
- A visible bar is updated in place; its widget state must survive the update.
- Nothing runs when nobody needs it: no timers without listeners, no rebuilds for unchanged content.

## Links in the documentation

The docs that ship with the package (README, `AI_GUIDE.md`, `llms.txt`, `doc/`, `ai/`) link into
this repository through the release tag, not through `main`:

```
https://github.com/rtfmko/fluent_bar/blob/v1.0.0/doc/queue.md
https://raw.githubusercontent.com/rtfmko/fluent_bar/v1.0.0/doc/media/hero.gif
```

So the README of a version on pub.dev opens the docs and pictures of that version, and an AI
assistant that follows `llms.txt` reads the guide of a released version, not of unreleased work.
Write a new link with the tag of the current version in `pubspec.yaml`; only links to
`CONTRIBUTING.md` use `main`. A test (`test/docs_test/repo_links_test.dart`) fails on a link
that names another ref or a file that does not exist.

## Releasing

1. On a `chore/release-X.Y.Z` branch: set `version` in `pubspec.yaml`, add `## X.Y.Z` at the top
   of `CHANGELOG.md`, and run `dart run tool/update_doc_links.dart`. It rewrites every link to
   `vX.Y.Z` and the `Version:` line of the AI guide.
2. Open the pull request, wait for green checks, squash-merge.
3. Tag `main` after the merge, never the branch: squash merging replaces the branch commits.

   ```sh
   git switch main && git pull
   git tag vX.Y.Z
   git push origin vX.Y.Z
   ```

4. Wait for the `Release` workflow. It fails if the tag does not match `pubspec.yaml`, points at a
   commit that is not on `main`, or that commit does not pass the checks. Pushing the tag also
   deploys the demo of this version.
5. Publish: `flutter pub publish`.

A release tag cannot be moved or deleted (`.github/rulesets/tags.json`). A fix after a release,
documentation included, is the next patch version. Until a tag is pushed, the links that name it
lead nowhere, which is why step 1 happens in the release pull request and not earlier.

## Renaming or removing public API

Nothing public disappears at once. Keep the old name working and mark it:

```dart
@Deprecated('Use withTheme instead')
FluentBarItem<T> withStyle(FluentBarTheme theme) => withTheme(theme);
```

Then add a row to [doc/ai/migrations.md](doc/ai/migrations.md) (old name, new name, the version
that deprecates it, the text to search for, a before → after example) and a line to `CHANGELOG.md`.
Remove the old name in a later minor or major version, not in the one that deprecates it.

## Reporting a bug

Open an issue with the package version, Flutter version, platform, a minimal piece of code that
reproduces the problem, and what you expected to happen. If an error handler or the debug console
printed a `[FluentBar]` message, include it.
