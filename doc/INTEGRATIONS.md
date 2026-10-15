# Using fluent_bar with other packages

`fluent_bar` needs none of the packages below, and nothing here is required. These are short,
copy-ready examples of how it fits together with packages you probably already use. Every example
was compiled against the package it names; none of them is part of the `fluent_bar` package itself.

- [Network: downloads and uploads](#network-downloads-and-uploads): [dio](#dio), [http](#http), [firebase_storage](#firebase_storage)
- [State management](#state-management): [flutter_bloc](#flutter_bloc), [provider](#provider), [flutter_riverpod](#flutter_riverpod), [state inside a bar](#state-inside-a-bar)
- [Analytics](#analytics): [firebase_analytics](#firebase_analytics)
- [Crash reporting](#crash-reporting): [firebase_crashlytics](#firebase_crashlytics), [sentry_flutter](#sentry_flutter)
- [Connectivity](#connectivity): [connectivity_plus](#connectivity_plus)
- [Push notifications](#push-notifications): [firebase_messaging](#firebase_messaging)
- [Navigation](#navigation): [go_router](#go_router)

One idea runs through all of them: a bar is shown **without a `BuildContext`**, so the call belongs
where the event happens (a cubit, a repository, a listener registered in `main`), not in a widget
that has to be on screen at the right moment.

## Network: downloads and uploads

Network libraries report progress as two numbers, the bytes transferred and the total size.
`entry.updateBytes(received, total)` takes exactly that pair:

- it picks the unit for the text: `3.1 / 50 MB`;
- a missing size (`null`, `0` or `-1`, as when the server sends no `Content-Length`) turns the
  indicator indeterminate and the text into `3.1 MB`;
- reaching the total completes the progress, so the bar starts its countdown and leaves by itself.

You do not have to throttle the callbacks: the indicator animates between values on its own.

### dio

`updateBytes` has the shape of `onReceiveProgress` and `onSendProgress`, so pass it as is:

```dart
Future<void> downloadMap(Dio dio, String url, String path) async {
  final entry = FluentBar.info<void>('Downloading the map')
      .withId('map_download')
      .withLinearProgress(showText: true)
      .show();

  try {
    await dio.download(url, path, onReceiveProgress: entry?.updateBytes);
    entry?.completeProgress(message: 'Map downloaded', type: FluentBarType.success);
  } on DioException catch (error) {
    entry?.failProgress(message: error.message ?? 'Download failed');
  }
}
```

An upload is the same with `onSendProgress`:

```dart
Future<void> uploadPhoto(Dio dio, FormData photo) async {
  final entry = FluentBar.info<void>('Uploading the photo').withLinearProgress(showText: true).show();

  try {
    await dio.post<void>('/photos', data: photo, onSendProgress: entry?.updateBytes);
    entry?.completeProgress(message: 'Photo uploaded', type: FluentBarType.success);
  } on DioException {
    entry?.failProgress(message: 'Upload failed');
  }
}
```

A Cancel button on the bar that cancels the request:

```dart
Future<void> downloadWithCancel(Dio dio, String url, String path) async {
  final cancelToken = CancelToken();

  final entry = FluentBar.info<void>('Downloading the map')
      .withLinearProgress(showText: true)
      .withCancelButton(
        'Cancel',
        onCancel: () => cancelToken.cancel(),
        canceledMessage: 'Download cancelled',
        canceledType: FluentBarType.warning,
      )
      .show();

  try {
    await dio.download(url, path, cancelToken: cancelToken, onReceiveProgress: entry?.updateBytes);
    entry?.completeProgress(message: 'Map downloaded', type: FluentBarType.success);
  } on DioException catch (error) {
    // The bar has already shown the cancellation; only a real failure is left to report.
    if (!CancelToken.isCancel(error)) entry?.failProgress(message: 'Download failed');
  }
}
```

The button removes itself when the download ends in any way, and progress that arrives after the
tap is ignored.

A failed download that offers a second try on the same bar. Retry calls the function again; the
same `id` makes the bar start over in place, with the progress and the Cancel button back:

```dart
Future<void> downloadWithRetry(Dio dio, String url, String path) async {
  final cancelToken = CancelToken();

  final entry = FluentBar.info<void>('Downloading the map')
      .withId('map_download')
      .withLinearProgress(showText: true)
      .withCancelButton('Cancel', onCancel: () => cancelToken.cancel(), canceledMessage: 'Download cancelled')
      .show();

  try {
    await dio.download(url, path, cancelToken: cancelToken, onReceiveProgress: entry?.updateBytes);
    entry?.completeProgress(message: 'Map downloaded', type: FluentBarType.success);
  } on DioException catch (error) {
    if (CancelToken.isCancel(error)) return;

    entry?.failProgress(
      message: 'Download failed',
      type: FluentBarType.warning,
      retryLabel: 'Retry',
      onRetry: () => downloadWithRetry(dio, url, path),
    );
  }
}
```

The failed bar stays until the user taps Retry or closes it; `isPersistent: false` lets it leave
by its timer.

One place for every failed request is an interceptor. The same `id` keeps ten failed requests
from producing ten bars:

```dart
class ErrorBarInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final bool isOffline = err.type == DioExceptionType.connectionError || err.type == DioExceptionType.connectionTimeout;

    FluentBar.showError(
      isOffline ? 'Check your connection and try again.' : 'Something went wrong. Please try again.',
      title: isOffline ? 'No connection' : null,
      id: 'network_error',
    );

    handler.next(err);
  }
}
```

### http

`package:http` has no progress callback; count the chunks of a streamed response yourself and
hand the numbers over. `contentLength` is `null` when the size is unknown, which `updateBytes`
understands:

```dart
Future<List<int>> downloadWithHttp(http.Client client, Uri url) async {
  final entry = FluentBar.info<void>('Downloading').withLinearProgress(showText: true).show();

  try {
    final response = await client.send(http.Request('GET', url));
    final bytes = <int>[];

    await for (final chunk in response.stream) {
      bytes.addAll(chunk);
      entry?.updateBytes(bytes.length, response.contentLength);
    }

    entry?.completeProgress(message: 'Downloaded', type: FluentBarType.success);
    return bytes;
  } catch (_) {
    entry?.failProgress(message: 'Download failed');
    rethrow;
  }
}
```

### firebase_storage

An upload task reports `bytesTransferred` and `totalBytes` in every snapshot:

```dart
Future<void> uploadToStorage(Reference reference, File file) async {
  final entry = FluentBar.info<void>('Uploading the file').withLinearProgress(showText: true).show();
  final task = reference.putFile(file);

  final subscription = task.snapshotEvents.listen((snapshot) => entry?.updateBytes(snapshot.bytesTransferred, snapshot.totalBytes));

  try {
    await task;
    entry?.completeProgress(message: 'File uploaded', type: FluentBarType.success);
  } on FirebaseException catch (error) {
    entry?.failProgress(message: error.message ?? 'Upload failed');
  } finally {
    await subscription.cancel();
  }
}
```

## State management

A bar needs no `BuildContext`, so it can be shown from the place that knows what happened. You do
not need a `BlocListener`, a `Consumer` or a `ScaffoldMessenger` only to show a message.

### flutter_bloc

Show the bar from the cubit. `FluentBar.future` covers loading, success and failure in one call
and hands the result (or the exception) back:

```dart
class ProfileCubit extends Cubit<Profile?> {
  ProfileCubit(this._api) : super(null);

  final ProfileApi _api;

  Future<void> save(Profile profile) async {
    final saved = await FluentBar.future<Profile>(
      _api.save(profile),
      loading: 'Saving the profile…',
      success: (profile) => 'Profile of ${profile.name} saved',
      error: (error) => 'Could not save the profile',
    );
    emit(saved);
  }
}
```

One observer reports the errors of every bloc and cubit in the app:

```dart
class ErrorBarObserver extends BlocObserver {
  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    FluentBar.showError('Something went wrong.', id: 'bloc_error');
    super.onError(bloc, error, stackTrace);
  }
}

void setUpBloc() => Bloc.observer = ErrorBarObserver();
```

If you prefer to keep the UI reaction in the widget tree, a `BlocListener` works too; no
`ScaffoldMessenger` is involved:

```dart
Widget profileListener(Widget child) => BlocListener<ProfileCubit, Profile?>(
  listenWhen: (previous, current) => previous != current && current != null,
  listener: (context, profile) => FluentBar.showSuccess('Signed in as ${profile!.name}', id: 'signed_in'),
  child: child,
);
```

### provider

The same from a `ChangeNotifier`:

```dart
class CartModel extends ChangeNotifier {
  final List<String> items = <String>[];

  void add(String item) {
    items.add(item);
    notifyListeners();

    // The same id: adding five items quickly updates one bar instead of queueing five.
    FluentBar.snack<String>('$item added to the cart', id: 'cart', action: 'Undo', onAction: (controller, _) => remove(item)).show();
  }

  void remove(String item) {
    items.remove(item);
    notifyListeners();
  }
}
```

### flutter_riverpod

`ref.listen` reacts to a change once, which is what a notification needs (reading the value in
`build` would show the bar again on every rebuild):

```dart
final profileProvider = FutureProvider<Profile>((ref) => ref.watch(profileApiProvider).load());

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<Profile>>(profileProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        FluentBar.error<void>('Could not load the profile')
            .withId('profile_error')
            .withAction('Retry', onPressed: (controller, _) => ref.invalidate(profileProvider))
            .show();
      }
    });

    return const Placeholder();
  }
}
```

### State inside a bar

The examples above show a bar from the place that knows what happened. The opposite direction
needs one fact: a bar is drawn in an overlay **above the navigator**. Its texts and callbacks do
not care, but a content builder (`.withContent(...)`) is built there, so it sees only what is
provided above it.

| Where the object is provided | Visible in a content builder |
|---|---|
| Above `MaterialApp` | yes |
| In `MaterialApp.builder`, above `FluentBarScope` | yes |
| Inside a screen or a route | no |

A builder that fails to find its provider does not break the app: the error goes to the error
handler and the bar is drawn with its standard content.

**Provide above the app** when the state is global anyway. With flutter_riverpod this is always
the case, because `ProviderScope` wraps the app:

```dart
void showCartBar() => FluentBar.info<void>('Cart')
    .persistent()
    .withContent((context, entry) => Consumer(builder: (context, ref, _) => Text('Items: ${ref.watch(cartCountProvider)}')))
    .show();
```

**Read the value before showing the bar** when a snapshot is enough:

```dart
void showTotal(BuildContext context) {
  final int count = context.read<CartModel>().items.length;
  FluentBar.showInfo('$count items in the cart');
}
```

**Hand the object over** when the bar must follow a state that lives on a screen. The bar gets the
same instance and rebuilds with it:

```dart
void showLiveCart(BuildContext context) {
  final CartModel cart = context.read<CartModel>();

  FluentBar.info<void>('Cart')
      .persistent()
      .withTag('cart')
      .withContent((_, entry) => ChangeNotifierProvider<CartModel>.value(
            value: cart,
            child: Consumer<CartModel>(builder: (context, cart, _) => Text('Items: ${cart.items.length}')),
          ))
      .show();
}
```

The same with flutter_bloc:

```dart
void showLiveProfile(BuildContext context) {
  final ProfileCubit cubit = context.read<ProfileCubit>();

  FluentBar.info<void>('Profile')
      .persistent()
      .withTag('profile')
      .withContent((_, entry) => BlocProvider<ProfileCubit>.value(
            value: cubit,
            child: BlocBuilder<ProfileCubit, Profile?>(builder: (context, profile) => Text(profile?.name ?? 'Signed out')),
          ))
      .show();
}
```

A bar that holds an object of a screen should not outlive the screen: tag it and wrap the screen
in `FluentBarOwner(tag: 'cart', ...)`, which closes the bar when the screen goes away.

## Analytics

One listener receives every event of every bar. `payload.toFlatMap()` returns only strings and
numbers, which is what analytics services accept as event parameters.

### firebase_analytics

```dart
void setUpBarAnalytics() {
  // Send only what you will look at; a muted event is not even created.
  FluentBar.patchConfig((config) => config.copyWith(
    disabledAnalyticsEvents: {
      FluentBarAnalyticsEvent.requested,
      FluentBarAnalyticsEvent.queued,
      FluentBarAnalyticsEvent.updated,
      FluentBarAnalyticsEvent.paused,
      FluentBarAnalyticsEvent.resumed,
    },
  ));

  FluentBar.addAnalyticsListener((payload) {
    FirebaseAnalytics.instance.logEvent(name: 'bar_${payload.event.name}', parameters: payload.toFlatMap());
  });
}
```

What arrives with `bar_dismissed`: `id`, `type_name`, `preset`, `tags`, `position`, `action_name`, `dismiss_reason`,
`visible_ms`, `showing_ms`, `planned_ms`, `queued_ms`, `paused_ms`, `was_visible`, `was_forced`, `timed_out`, `had_action`,
`was_action_tapped`, `was_tapped`, `was_untouched`, `update_count`, `progress_outcome` and one
`interaction_…` key per kind of interaction. Flags are `1` / `0`.

Firebase limits: an event carries at most 25 parameters, a name is at most 40 characters and a
string value at most 100. The flat map of a dismissed bar stays within that limit; if your ids are long,
shorten them before sending. To tell your own kinds of bars apart, label them with
`.withPreset('undo')` and read `preset`.

## Crash reporting

Your callbacks, builders, themes and types are isolated: when one throws, the bar still appears
and the error goes to the handlers registered with `FluentBar.addErrorHandler`. Nothing reaches
`FlutterError.onError`, so without a handler these errors are visible only in the debug console.

`error.severity` tells real failures from misuse the library recovered from (no overlay yet, a
full queue). The second kind is worth a log line, not a crash report.

### firebase_crashlytics

```dart
void setUpBarCrashReports() {
  FluentBar.addErrorHandler((error, stackTrace) {
    if (error.severity.isWarning) {
      FirebaseCrashlytics.instance.log('fluent_bar warning: ${error.type.displayName}');
      return;
    }

    FirebaseCrashlytics.instance.recordError(error.error, stackTrace, reason: 'fluent_bar: ${error.type.displayName}');
  });
}
```

### sentry_flutter

Errors as events, and the life of every bar as breadcrumbs, so a crash report shows what the user
was looking at:

```dart
void setUpBarSentry() {
  FluentBar.addErrorHandler((error, stackTrace) {
    if (error.severity.isWarning) return;

    Sentry.captureException(
      error.error,
      stackTrace: stackTrace,
      withScope: (scope) => scope.setTag('fluent_bar', error.type.name),
    );
  });

  FluentBar.addAnalyticsListener((payload) {
    Sentry.addBreadcrumb(Breadcrumb(category: 'fluent_bar', message: payload.event.name, data: payload.toFlatMap(), level: SentryLevel.info));
  });
}
```

## Connectivity

### connectivity_plus

A banner that stays while the device is offline and turns into a short confirmation when the
connection is back. Both bars share an `id`, so the second one replaces the first:

```dart
StreamSubscription<List<ConnectivityResult>> watchConnection() {
  bool wasOffline = false;

  return Connectivity().onConnectivityChanged.listen((results) {
    final bool isOffline = results.contains(ConnectivityResult.none);

    if (isOffline) {
      FluentBar.banner<void>('Changes will sync when you are back online.', title: 'You are offline', type: FluentBarType.warning, id: 'network').show();
    } else if (wasOffline) {
      FluentBar.success<void>('Back online').withId('network').withDuration(const Duration(seconds: 2)).show();
    }

    wasOffline = isOffline;
  });
}
```

## Push notifications

### firebase_messaging

A push that arrives while the app is open is not shown by the system. Show it as a bar; the
message travels as the payload and comes back in `onTap`:

```dart
StreamSubscription<RemoteMessage> showForegroundPushes(void Function(RemoteMessage message) open) =>
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      FluentBar.info<RemoteMessage>(notification.body ?? '')
          .withTitle(notification.title ?? 'New message')
          .withId('push_${message.messageId}')
          .withPayload(message)
          .withDuration(const Duration(seconds: 6))
          .onTap((message) {
            if (message != null) open(message);
          })
          .show();
    });
```

## Navigation

### go_router

Put the scope into the `builder` of `MaterialApp.router`. Bars then live above the router and
survive every navigation, including `go` and redirects:

```dart
Widget buildApp(GoRouter router) => MaterialApp.router(
  routerConfig: router,
  builder: FluentBarScope.builder(),
);
```

No observer and no navigator key are needed with this setup.
