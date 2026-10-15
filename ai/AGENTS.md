## fluent_bar (in-app notification bars)

This project uses the `fluent_bar` package for snackbars, toasts, banners and progress bars. Before
writing or changing code that uses it, read its guide. The guide ships with the package, so it
always matches the installed version:

1. Find the installed version in `pubspec.lock` (the `fluent_bar:` entry, field `version`).
2. Find the package root in `.dart_tool/package_config.json` (the entry with
   `"name": "fluent_bar"`, field `rootUri`; a `file://` URI or a path relative to `.dart_tool/`).
3. Open `AI_GUIDE.md` in that root. Compare its `Version:` line with the version from step 1 (see
   below if they differ), read it in full, then open the file in `doc/ai/` that it names for
   your task.

If the versions differ, make sure you are reading `AI_GUIDE.md` from the root of the installed
package (the path from `.dart_tool/package_config.json`) and use that one; if you already are,
`pubspec.lock` changed without `flutter pub get`, so tell the user to run it. Do not edit the guide
and do not copy it into the project.

If there is no guide in the package root, read `lib/` of the package there instead of guessing
the API.
