# Setup

Version: 1.0.0. Read this to set up the package in an app, or to understand how bars, regions and the queue work.
The rules in `AI_GUIDE.md` apply here too.

## Setup

Pick one. Bars requested earlier wait in the queue and appear when the overlay exists.

```dart
// A. Recommended: bars live above the navigator and survive route changes.
MaterialApp(builder: FluentBarScope.builder(config: const FluentBarConfig()), home: const Home());

// B. Navigator overlay through an observer.
MaterialApp(navigatorObservers: [FluentBarObserver.instance], home: const Home());

// C. Your own navigator key.
final navigatorKey = GlobalKey<NavigatorState>();
FluentBar.initialize(config: const FluentBarConfig(), navigatorKey: navigatorKey);
MaterialApp(navigatorKey: navigatorKey, home: const Home());
```

The config can be set or changed at any time, also before `runApp`:

```dart
FluentBar.updateConfig(const FluentBarConfig(defaultPosition: FluentBarPosition.bottom));
FluentBar.patchConfig((c) => c.copyWith(maxQueueLength: 5));
```

Keep bars clear of app chrome by wrapping it once (heights are measured automatically):

```dart
Scaffold(
  appBar: FluentBarTopInset(child: AppBar(title: const Text('Inbox'))),
  bottomNavigationBar: FluentBarBottomInset(child: NavigationBar(destinations: destinations)),
);
```

Bottom bars also rise above the on-screen keyboard by themselves. While another screen, a dialog
or a sheet covers the screen, its insets are withdrawn; the keyboard is always taken into account.

## Mental model

- `FluentBarItem<T>`: an immutable description of a bar (a draft). `T` is the payload type.
- `FluentBarEntry<T>`: a bar that was shown or queued. `entry.item` is always the current content;
  `entry.controller` (`FluentBarController<T>`) changes it.
- Two **regions**, top and bottom, with one visible bar and one queue each (see [queue.md](queue.md)).
- Lifecycle: `queued → showing → visible → hiding → dismissed` (`controller.stateNotifier`).
  The state has a getter for every question; use them, never `==` (rule 13 in `AI_GUIDE.md`). One state:
  `isQueued`, `isShowing`, `isVisible`, `isHiding`, `isDismissed`. Several: `isOnScreen`
  (`showing`, `visible`, `hiding`), `isInteractive` (`showing`, `visible`), `isAnimating`
  (`showing`, `hiding`), `isFinished` (`hiding`, `dismissed`).
  ```dart
  final state = entry.controller.stateNotifier.value;
  if (state.isVisible) startReading();
  if (!state.isFinished) entry.update(message: 'Almost done');
  ```
  `showing` = on screen, entrance animation playing (taps and the action already work);
  `visible` = in place. **The countdown starts at `visible`**: a bar's duration is the time it
  stands still, entrance and exit animations are extra. With animations off `visible` follows
  `showing` immediately. Time added during `showing` (`addDuration`) is kept. An attention effect
  requested before `visible` plays when the bar gets there (only the last one). A bar closed while
  appearing goes `showing → hiding` and never becomes `visible`.
- Naming rule: `FluentBar.showX(...)` shows now and returns `FluentBarEntry<T>?`;
  `FluentBar.x(...)` returns a draft `FluentBarItem<T>` for a chain that ends with `.show()`.
- `show` returns `null` only when the bar was dropped: the queue is full, or a custom queue
  strategy left it out.
