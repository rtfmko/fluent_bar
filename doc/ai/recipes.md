# Recipes and other packages

Version: 1.0.0. Read this for a ready solution to a common task, or before writing glue code for dio, bloc, provider, riverpod, Firebase and others.
The rules in `AI_GUIDE.md` apply here too.

## Recipes

```dart
// Undo
FluentBar.snack<void>('Conversation deleted', action: 'Undo', onAction: (c, _) => restore())
    .withDuration(const Duration(seconds: 6)).withTimeoutBar().show();

// Offline → back online: one id, the second call replaces the first bar
FluentBar.banner<void>('Changes will sync later.', title: 'You are offline', type: FluentBarType.warning, id: 'network').show();
FluentBar.success<void>('Back online').withId('network').withDuration(const Duration(seconds: 2)).show();

// Critical alert that must be answered
FluentBar.error<void>('Your session has expired.')
    .withTitle('Sign in again').forced().persistent().undismissible()
    .withAction('Sign in', onPressed: (c, _) => signIn()).show();

// "Saved" that never piles up
FluentBar.toast<void>('Saved', id: 'saved').withDuplicatePolicy(FluentBarDuplicatePolicy.updateAndResetTimer).show();

// Typed payload that comes back in the action
FluentBar.success<Order>('Order shipped').withPayload(order)
    .withAction('Track', onPressed: (controller, order) => openTracking(order!.id)).show();

// Loading, then the result, in one bar
final loading = FluentBar.showLoading<void>('Signing in…', id: 'sign_in');
try {
  await auth.signIn();
  loading?.completeProgress(message: 'Welcome back', type: FluentBarType.success);
} catch (_) {
  loading?.failProgress(message: 'Wrong email or password');
}

// An error the user can retry: the bar stays with a loader on the button, the handler closes it
FluentBar.error<void>('Could not load the feed').persistent()
    .withAction('Retry', closeOnAction: false, onPressed: (c, _) async {
      await loadFeed();
      c.close();
    }).show();

// Messages of one chat update one bar (no id needed)
FluentBar.patchConfig((c) => c.copyWith(
  duplicateComparator: (a, b) =>
      (a.id != null && a.id == b.id) || (a.meta?['group'] != null && a.meta?['group'] == b.meta?['group']),
));
FluentBar.info<void>('Are we still on for lunch?').withTitle('Alex').withMeta({'group': 'chat_alex'}).show();
```

## Other packages

`doc/INTEGRATIONS.md` in the package has compiled examples for dio, http, firebase_storage
(progress in bytes), flutter_bloc, provider, flutter_riverpod (showing bars from the state layer),
firebase_analytics, firebase_crashlytics, sentry_flutter, connectivity_plus, firebase_messaging and
go_router. Read it before writing glue code for any of them. The rule behind all of them: show the
bar where the event happens (a cubit, a repository, a listener registered in `main`), not through a
widget; no `BuildContext`, `BlocListener` or `ScaffoldMessenger` is needed for that.
