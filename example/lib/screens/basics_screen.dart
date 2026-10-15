import 'dart:async';

import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_kit.dart';

// The "download with Cancel" recipe. The callback only stops the task; the bar does the rest.
void _download({required bool indeterminate}) {
  final DemoProgressRunner runner = DemoProgressRunner();

  final FluentBarEntry<void>? entry = FluentBar.info<void>('Downloading the map')
      .withTitle('Offline maps')
      .withPreset('download')
      .withId('recipe_download')
      .dismissOnTap(false)
      .withLinearProgress(state: indeterminate ? const FluentBarProgressState.indeterminate() : const FluentBarProgressState.value(0), showText: !indeterminate)
      .withCancelButton(
        'Cancel',
        onCancel: () async {
          runner.stop();
          await Future<void>.delayed(const Duration(milliseconds: 1500));
        },
        canceledMessage: 'Download cancelled',
        canceledType: FluentBarType.warning,
      )
      .show();
  if (entry == null) return;

  void finish() {
    if (identical(FluentBar.find('recipe_download'), entry)) entry.completeProgress(message: 'Map downloaded', type: FluentBarType.success);
  }

  if (indeterminate) {
    Future<void>.delayed(const Duration(seconds: 6), finish);
    return;
  }

  runner.start((double value) {
    if (!identical(FluentBar.find('recipe_download'), entry)) {
      scheduleMicrotask(runner.stop);
      return;
    }
    value < 1 ? entry.updateValue(value) : finish();
  });
}

Timer? _uploadTimer;

class BasicsScreen extends StatelessWidget {
  const BasicsScreen({super.key});

  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Quick start',
    subtitle: 'Everything on this screen is a single call. showX(...) shows a bar at once; x(...) returns a draft you can extend with .with...() and finish with .show().',
    children: <Widget>[
      const DemoSection(
        icon: Icons.power_settings_new_rounded,
        id: 'start/setup',
        description:
            'The library needs a place to draw bars. There are three ways to give it one; pick one. FluentBarScope is the recommended one: bars live above the navigator, so they survive route changes and sit on top of dialogs and sheets. Using several at once is safe - the scope simply wins - but there is nothing to gain from it.',
        code: '''
// 1. Recommended: a scope around the app. The config is optional.
MaterialApp(
  builder: FluentBarScope.builder(config: const FluentBarConfig()),
);

// 2. A navigator observer: bars are drawn in the navigator's own overlay.
MaterialApp(navigatorObservers: [FluentBarObserver.instance]);

// 3. A navigator key, when you already have one.
FluentBar.initialize(config: const FluentBarConfig(), navigatorKey: navigatorKey);

// The config can be set at any time, even before runApp():
void main() {
  FluentBar.updateConfig(const FluentBarConfig(maxQueueLength: 10));
  FluentBar.showInfo('Requested before runApp()');   // waits and appears on startup
  runApp(const MyApp());
}''',
        child: DemoNote(
          'This app uses option 1. The bar you saw on startup was requested on the very first line of main() - before the config and before runApp(). See example/lib/main.dart.',
          icon: Icons.info_outline,
        ),
      ),
      DemoSection(
        icon: Icons.bolt_outlined,
        id: 'start/one-liners',
        description: 'Four built-in types. Colors, icon, duration and haptics come from the type and the global config.',
        code: '''
FluentBar.showSuccess('Profile saved');
FluentBar.showError('Could not reach the server', title: 'Connection lost');
FluentBar.showWarning('Storage is almost full');
FluentBar.showInfo('A new version is available');''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton('Success', icon: Icons.check_circle_outline, tone: DemoTone.success, onPressed: () => FluentBar.showSuccess('Profile saved')),
            DemoButton(
              'Error',
              icon: Icons.error_outline,
              tone: DemoTone.danger,
              onPressed: () => FluentBar.showError('Could not reach the server', title: 'Connection lost'),
            ),
            DemoButton('Warning', icon: Icons.warning_amber_rounded, tone: DemoTone.warning, onPressed: () => FluentBar.showWarning('Storage is almost full')),
            DemoButton('Info', icon: Icons.info_outline, onPressed: () => FluentBar.showInfo('A new version is available')),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.auto_awesome_outlined,
        id: 'start/presets',
        description: 'Ready-made shapes for the most common jobs. Each one is also available as a draft (FluentBar.snack(...)) for the chain.',
        code: '''
// Like a SnackBar: bottom, no icon, optional action.
FluentBar.showSnack('Message archived', action: 'Undo', onAction: (controller, _) => restore());

// Short hint that disappears by itself.
FluentBar.showToast('Copied to clipboard');

// Pinned message: stays until the action or code closes it.
FluentBar.showBanner('You are offline', title: 'No connection', action: 'Retry', type: FluentBarType.warning);

// Spinner that waits for your work.
final entry = FluentBar.showLoading('Uploading...');
entry?.completeProgress(message: 'Uploaded');''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton(
              'Snack + Undo',
              icon: Icons.undo,
              onPressed: () => FluentBar.showSnack('Message archived', action: 'Undo', onAction: (_, _) => FluentBar.showToast('Restored')),
            ),
            DemoButton('Toast', icon: Icons.chat_bubble_outline, onPressed: () => FluentBar.showToast('Copied to clipboard')),
            DemoButton(
              'Banner',
              icon: Icons.wifi_off_rounded,
              tone: DemoTone.warning,
              onPressed: () => FluentBar.showBanner(
                'Changes will be sent when you are back online.',
                title: 'No connection',
                action: 'Retry',
                type: FluentBarType.warning,
                id: 'offline_banner',
                onAction: (_, _) => FluentBar.showToast('Reconnecting...'),
              ),
            ),
            DemoButton(
              'Loading',
              icon: Icons.hourglass_empty_rounded,
              onPressed: () {
                final FluentBarEntry<void>? entry = FluentBar.showLoading<void>('Uploading...', id: 'basics_loading');
                Future<void>.delayed(DemoProgressRunner.resultPause, () => entry?.completeProgress(message: 'Uploaded', type: FluentBarType.success));
              },
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.menu_book_outlined,
        id: 'start/recipes',
        description:
            'Typical jobs put together from the same building blocks. Each one is a preset or a type plus a few .with...() calls. withPreset(...) labels the bar so you can tell these apart in logs and analytics.',
        code: '''
// An error the user can retry: the button shows a loader while the work runs, then the bar closes.
FluentBar.error('Could not load the feed').withPreset('retry').persistent()
    .withAction('Retry', closeOnAction: false, onPressed: (controller, _) async {
      await loadFeed();
      controller.close();
    }).show();

// Loading, then the result, in the same bar.
final loading = FluentBar.showLoading('Signing in...', id: 'sign_in');
try {
  await auth.signIn();
  loading?.completeProgress(message: 'Welcome back', type: FluentBarType.success);
} catch (_) {
  loading?.failProgress(message: 'Wrong email or password');
}

// Upload with a progress line.
final upload = FluentBar.info('Uploading 12 photos').withId('upload')
    .withLinearProgress(value: 0, showText: true).atBottom().show();
upload?.updateFraction(3, 12);
upload?.completeProgress(message: 'All photos uploaded', type: FluentBarType.success);

// Undo: a snack that stays a bit longer and shows how much time is left.
FluentBar.snack('Conversation deleted', action: 'Undo', onAction: (c, _) => restore())
    .withPreset('undo').withDuration(const Duration(seconds: 6)).withTimeoutBar().show();

// Offline / back online: one id, so the second call replaces the first bar.
FluentBar.banner('Changes will sync later.', title: 'You are offline', type: FluentBarType.warning, id: 'network').show();
FluentBar.success('Back online').withId('network').withDuration(const Duration(seconds: 2)).show();

// Critical alert: jumps the queue, cannot be dismissed, asks for an action.
FluentBar.error('Your session has expired.')
    .withTitle('Sign in again').withPreset('alert')
    .forced().persistent().undismissible()
    .withAction('Sign in', onPressed: (c, _) => signIn())
    .show()?.shake();

// Consent: sits at the bottom until answered.
FluentBar.info('We use cookies to keep you signed in.')
    .withPreset('consent').atBottom().persistent().undismissible().withoutIcon()
    .withAction('Accept').show();

// "Saved" that never piles up: the same id restarts the countdown instead of queueing.
FluentBar.toast('Saved', id: 'saved').withDuplicatePolicy(FluentBarDuplicatePolicy.updateAndResetTimer).show();

// Download with Cancel: the button shows a loader while the task stops, the bar turns
// into a warning and closes by itself. The button also leaves when the download ends.
final entry = FluentBar.info('Downloading the map')
    .withPreset('download')
    .withLinearProgress(value: 0, showText: true)
    .withCancelButton(
      'Cancel',
      onCancel: () => download.cancel(),
      canceledMessage: 'Download cancelled',
      canceledType: FluentBarType.warning,
    )
    .show();

download.onProgress = (received, total) => entry?.updateBytes(received, total);
download.onDone = () => entry?.completeProgress(message: 'Map downloaded', type: FluentBarType.success);''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton(
              'Undo',
              icon: Icons.undo,
              onPressed: () => FluentBar.snack<void>(
                'Conversation deleted',
                action: 'Undo',
                onAction: (_, _) => FluentBar.showToast('Conversation restored'),
              ).withPreset('undo').withId('recipe_undo').withDuration(const Duration(seconds: 6)).withTimeoutBar().show(),
            ),
            DemoButton(
              'Error with Retry',
              icon: Icons.refresh_rounded,
              tone: DemoTone.danger,
              onPressed: () => FluentBar.error<void>('Could not load the feed')
                  .withPreset('retry')
                  .withId('recipe_retry')
                  .persistent()
                  .withAction(
                    'Retry',
                    closeOnAction: false,
                    onPressed: (FluentBarController<void> controller, _) async {
                      await Future<void>.delayed(const Duration(milliseconds: 1500));
                      controller.close();
                    },
                  )
                  .show(),
            ),
            DemoButton(
              'Loading, then the result',
              icon: Icons.login_rounded,
              onPressed: () {
                final FluentBarEntry<void>? loading = FluentBar.showLoading<void>('Signing in...', id: 'recipe_sign_in');
                Future<void>.delayed(const Duration(seconds: 2), () => loading?.completeProgress(message: 'Welcome back', type: FluentBarType.success));
              },
            ),
            DemoButton(
              'Upload with progress',
              icon: Icons.cloud_upload_outlined,
              onPressed: () {
                final FluentBarEntry<void>? upload = FluentBar.info<void>(
                  'Uploading 12 photos',
                ).withPreset('upload').withId('recipe_upload').withLinearProgress(value: 0, showText: true).atBottom().show();

                int sent = 0;
                _uploadTimer?.cancel();
                _uploadTimer = Timer.periodic(const Duration(milliseconds: 350), (Timer timer) {
                  sent++;
                  if (upload == null || !identical(FluentBar.find('recipe_upload'), upload)) return timer.cancel();

                  upload.updateFraction(sent, 12, completedMessage: 'All photos uploaded', completedType: FluentBarType.success);
                  if (sent == 12) timer.cancel();
                });
              },
            ),
            DemoButton(
              'Go offline',
              icon: Icons.wifi_off_rounded,
              tone: DemoTone.warning,
              onPressed: () => FluentBar.banner<void>('Changes will sync later.', title: 'You are offline', type: FluentBarType.warning, id: 'recipe_network').show(),
            ),
            DemoButton(
              'Back online',
              icon: Icons.wifi_rounded,
              tone: DemoTone.success,
              onPressed: () => FluentBar.success<void>('Back online').withId('recipe_network').withDuration(const Duration(seconds: 2)).show(),
            ),
            DemoButton(
              'Critical alert',
              icon: Icons.gpp_maybe_outlined,
              tone: DemoTone.danger,
              onPressed: () => FluentBar.error<void>('Your session has expired.')
                  .withTitle('Sign in again')
                  .withPreset('alert')
                  .withId('recipe_alert')
                  .forced()
                  .persistent()
                  .undismissible()
                  .withAction('Sign in', onPressed: (_, _) => Future<void>.delayed(const Duration(seconds: 1)))
                  .show()
                  ?.shake(),
            ),
            DemoButton(
              'Achievement',
              icon: Icons.emoji_events_outlined,
              onPressed: () => FluentBar.success<void>('7 days in a row. Keep going!')
                  .withTitle('Streak unlocked')
                  .withPreset('achievement')
                  .withId('recipe_achievement')
                  .withBackground(const Color(0xFF7C3AED))
                  .dark()
                  .withIcon(const Icon(Icons.emoji_events_rounded), color: Colors.amberAccent)
                  .withEntrance(FluentBarEntranceAnimation.elastic)
                  .atCenter()
                  .show()
                  ?.heartbeat(),
            ),
            DemoButton(
              'Cookie consent',
              icon: Icons.cookie_outlined,
              onPressed: () => FluentBar.info<void>(
                'We use cookies to keep you signed in.',
              ).withPreset('consent').withId('recipe_consent').atBottom().persistent().undismissible().withoutIcon().withAction('Accept').show(),
            ),
            DemoButton('Download with Cancel', icon: Icons.download_rounded, tone: DemoTone.primary, onPressed: () => _download(indeterminate: false)),
            DemoButton('Download with Cancel (no percent)', icon: Icons.downloading_rounded, onPressed: () => _download(indeterminate: true)),
            DemoButton(
              'Saved (press many times)',
              icon: Icons.save_outlined,
              onPressed: () => FluentBar.toast<void>('Saved', id: 'recipe_saved').withDuplicatePolicy(FluentBarDuplicatePolicy.updateAndResetTimer).show(),
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.link_rounded,
        id: 'start/the-chain',
        description: 'Start from a draft and add only what differs from the defaults. Every call returns a new draft, so a draft can be reused.',
        code: '''
FluentBar.success('Order #1042 has been shipped')
    .withTitle('On its way')
    .withAction('Track', onPressed: (controller, _) => openTracking())
    .withTimeoutBar()
    .withDuration(const Duration(seconds: 6))
    .atBottom()
    .show();''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton(
              'Title + action + timeout bar',
              tone: DemoTone.primary,
              onPressed: () => FluentBar.success<void>('Order #1042 has been shipped')
                  .withTitle('On its way')
                  .withAction('Track', onPressed: (_, _) => FluentBar.showToast('Opening tracking...'))
                  .withTimeoutBar()
                  .withDuration(const Duration(seconds: 6))
                  .atBottom()
                  .show(),
            ),
            DemoButton(
              'Own colors & icon',
              onPressed: () => FluentBar.info<void>('You earned 50 bonus points')
                  .withTitle('Nice!')
                  .withBackground(const Color(0xFF7C3AED))
                  .withIcon(const Icon(Icons.stars_rounded), color: Colors.amberAccent)
                  .dark()
                  .withEntrance(FluentBarEntranceAnimation.bouncingSlide)
                  .show(),
            ),
            DemoButton(
              'Sticky until tapped',
              onPressed: () => FluentBar.warning<void>('Tap this bar to dismiss it').withTitle('Persistent').persistent().swipeable(false).dismissOnTap().atCenter().show(),
            ),
            DemoButton(
              'Fully custom content',
              onPressed: () => FluentBar.info<void>('unused')
                  .withContent(
                    (BuildContext context, FluentBarEntry<void> entry) => Card(
                      margin: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.inverseSurface,
                      child: ListTile(
                        leading: const CircleAvatar(child: Text('JD')),
                        title: Text('Jane Doe', style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface)),
                        subtitle: Text('Sent you a photo', style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface.withValues(alpha: 0.7))),
                        trailing: IconButton(
                          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onInverseSurface),
                          onPressed: entry.close,
                        ),
                      ),
                    ),
                  )
                  .show(),
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.data_object_rounded,
        id: 'start/payload-callbacks',
        description: 'A bar can carry your own object. The payload comes back typed in the action, in onTap and in every callback.',
        code: '''
FluentBar.info<Order>('Order ready for pickup', payload: order)
    .withAction('Open', onPressed: (controller, Order? order) => openOrder(order!))
    .onTap((Order? order) => preview(order))
    .onDismiss((item, metrics) => log(metrics.dismissReason))
    .show();''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton(
              'Bar with a payload',
              onPressed: () => FluentBar.info<_Order>('Order ready for pickup', payload: const _Order(1042, 'Espresso machine'))
                  .withTitle('Tap me or press Open')
                  .withAction('Open', onPressed: (_, _Order? order) => FluentBar.showToast('Opening #${order?.number}: ${order?.title}'))
                  .onTap((_Order? order) => FluentBar.showToast('Tapped order #${order?.number}'))
                  .onDismiss((_, FluentBarMetrics metrics) => debugPrint('Dismissed by ${metrics.dismissReason.name} after ${metrics.visibleDuration.inMilliseconds} ms'))
                  .dismissOnTap(false)
                  .show(),
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.close_fullscreen_rounded,
        id: 'start/closing',
        description: 'Close one bar by its id, everything on screen, or everything including the queue.',
        code: '''
FluentBar.close('offline_banner');   // one bar, shown or queued
FluentBar.closeActive();             // what is on screen, with animation
FluentBar.closeAll();                // screen + queue, with animation
FluentBar.clearQueue();              // only the waiting bars
FluentBar.dismissAndClear();         // everything, instantly''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton(
              'Show 5 bars',
              tone: DemoTone.primary,
              onPressed: () {
                for (int i = 1; i <= 5; i++) {
                  FluentBar.showInfo('Bar $i of 5', id: 'closing_$i');
                }
              },
            ),
            DemoButton("close('closing_1')", onPressed: () => FluentBar.close('closing_1')),
            DemoButton('closeActive()', onPressed: FluentBar.closeActive),
            DemoButton('clearQueue()', onPressed: FluentBar.clearQueue),
            DemoButton('closeAll()', onPressed: FluentBar.closeAll),
            DemoButton('dismissAndClear()', tone: DemoTone.danger, onPressed: FluentBar.dismissAndClear),
          ],
        ),
      ),
    ],
  );
}

class _Order {
  final int number;
  final String title;

  const _Order(this.number, this.title);
}
