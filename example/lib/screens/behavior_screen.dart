import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_kit.dart';

class BehaviorScreen extends StatefulWidget {
  const BehaviorScreen({super.key});

  @override
  State<BehaviorScreen> createState() => _BehaviorScreenState();
}

class _BehaviorScreenState extends State<BehaviorScreen> {
  static const String _liveId = 'live_bar';

  FluentBarRelocationStrategy _relocation = FluentBarRelocationStrategy.queueNext;
  FluentBarEntranceAnimation _entrance = FluentBarEntranceAnimation.slide;
  FluentBarSemantics _semantics = FluentBarSemantics.announce;
  bool _showBottomBar = true;
  int _tab = 0;

  final FocusNode _keyboardFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _keyboardFocus.addListener(_onKeyboardFocus);
  }

  @override
  void dispose() {
    _keyboardFocus
      ..removeListener(_onKeyboardFocus)
      ..dispose();
    super.dispose();
  }

  void _onKeyboardFocus() => setState(() {});

  FluentBarEntry<dynamic> _live() =>
      FluentBar.find(_liveId) ??
      FluentBar.info<void>('Use the buttons to control me while I am on screen.').withTitle('Live bar').withId(_liveId).withDuration(const Duration(seconds: 12)).withTimeoutBar().show()!;

  void _moveLive(FluentBarPosition position, {FluentBarRelocationStrategy? strategy}) {
    final FluentBarEntry<dynamic> entry = _live();
    entry.patchBehavior((FluentBarBehavior behavior) => behavior.copyWith(position: position, relocationStrategy: strategy ?? _relocation));
  }

  static String _occupantId(FluentBarPosition position) => 'occupant_${position.name}';

  void _placeLive(FluentBarPosition position) {
    FluentBar.close(_occupantId(FluentBarPosition.top));
    FluentBar.close(_occupantId(FluentBarPosition.bottom));
    _moveLive(position, strategy: FluentBarRelocationStrategy.forceReplace);
    _live().updateDuration(const Duration(seconds: 30), resetTimer: true);
  }

  void _occupy(FluentBarPosition position) =>
      FluentBar.info<void>('I occupy the ${position.name} region.').withTitle('Occupant').withoutIcon().persistent().withId(_occupantId(position)).at(position).show();

  Widget _relocationSteps({required FluentBarPosition from, required FluentBarPosition to}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      DemoLabel('From the ${from.name} to the ${to.name}'),
      const SizedBox(height: 6),
      DemoWrap(
        children: <Widget>[
          DemoButton('1. Live bar at the ${from.name}', onPressed: () => _placeLive(from)),
          DemoButton('2. Occupy the ${to.name}', onPressed: () => _occupy(to)),
          DemoButton(
            '3. Move live bar ${to == FluentBarPosition.bottom ? 'down' : 'up'}',
            icon: to == FluentBarPosition.bottom ? Icons.south : Icons.north,
            tone: DemoTone.primary,
            onPressed: () => _moveLive(to),
          ),
          DemoButton('Free the ${to.name}', onPressed: () => FluentBar.close(_occupantId(to))),
        ],
      ),
    ],
  );

  final Map<String, int> _shows = <String, int>{};

  void _showFresh(String group, FluentBarItem<void> item) {
    final int number = (_shows[group] ?? 0) + 1;
    _shows[group] = number;

    FluentBar.close('${group}_${number - 1}');
    item.withId('${group}_$number').show();
  }

  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Behavior & gestures',
    subtitle: 'Where a bar appears, how it reacts to touch and what you can do with it after it is shown.',
    bottomNavigationBar: _showBottomBar
        ? FluentBarBottomInset(
            child: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (int index) => setState(() => _tab = index),
              destinations: const <Widget>[
                NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
                NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
              ],
            ),
          )
        : null,
    children: <Widget>[
      DemoSection(
        icon: Icons.open_with_rounded,
        id: 'behavior/positions',
        description:
            'Top and bottom are two independent regions: each shows one bar at a time and has its own queue. Left, right and center share the top region. Each button hides the previous bar and shows a new one in its place.',
        code: '''
FluentBar.info('Hello').atBottom().show();
FluentBar.info('Hello').at(FluentBarPosition.center).show();''',
        child: DemoWrap(
          children: <Widget>[
            for (final FluentBarPosition position in FluentBarPosition.values)
              DemoButton(position.name, onPressed: () => _showFresh('position', FluentBar.info<void>('I appear at the ${position.name}.').at(position))),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.vertical_align_bottom_rounded,
        id: 'behavior/insets',
        description:
            'Wrap the app bar in FluentBarTopInset and the bottom navigation in FluentBarBottomInset: top bars appear under the app bar, bottom bars lift above the navigation, like a SnackBar. Every screen of this app does it - that is why bars never cover the back button. Hide the panel and bottom bars drop back. Open the keyboard and they rise above it.',
        code: '''
Scaffold(
  appBar: FluentBarTopInset(child: AppBar(title: const Text('Inbox'))),
  bottomNavigationBar: FluentBarBottomInset(child: NavigationBar(...)),
);

// Fixed values work too:
FluentBar.patchConfig((config) => config.copyWith(topInset: 96, bottomInset: 80));

// One chain: the bar itself (withInsets), then its type, then the config, then what the widget measured.
// The keyboard needs no setup: a bottom bar stays above it.''',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DemoSwitch(label: 'Show the bottom navigation', hint: 'Toggle while a bottom bar is visible', value: _showBottomBar, onChanged: (bool v) => setState(() => _showBottomBar = v)),
            DemoSwitch(
              label: 'Show the keyboard',
              hint: 'On a phone: bottom bars move up with it',
              value: _keyboardFocus.hasFocus,
              onChanged: (bool v) => v ? _keyboardFocus.requestFocus() : _keyboardFocus.unfocus(),
            ),
            const SizedBox(height: 8),
            TextField(
              focusNode: _keyboardFocus,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: 'The keyboard opens for this field'),
            ),
            const SizedBox(height: 12),
            DemoWrap(
              children: <Widget>[
                DemoButton(
                  'Snack above the panel',
                  tone: DemoTone.primary,
                  onPressed: () => FluentBar.snack<void>('I sit right above the navigation bar.', action: 'OK').persistent().withId('inset_snack').show(),
                ),
              ],
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.swap_vert_rounded,
        id: 'behavior/relocation',
        description:
            'Change the position on the fly. If the target region is busy, the relocation strategy decides what happens - the same way in both directions. Pick a strategy and walk through the three steps of either row.',
        code:
            '''
entry.patchBehavior(
  (behavior) => behavior.copyWith(
    position: FluentBarPosition.bottom,   // or .top - the rules are the same both ways
    relocationStrategy: FluentBarRelocationStrategy.${_relocation.name},
  ),
);

// Or set the strategy when the bar is created:
FluentBar.info('Hello').withRelocationStrategy(FluentBarRelocationStrategy.${_relocation.name}).show();

// queueNext     - leave and wait first in the queue of the new region (default)
// forceReplace  - dismiss the bar that occupies the new region
// ignore        - stay where it was''',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DemoChoice<FluentBarRelocationStrategy>(
              label: 'If the target region is busy',
              values: FluentBarRelocationStrategy.values,
              selected: _relocation,
              onChanged: (FluentBarRelocationStrategy v) => setState(() => _relocation = v),
            ),
            const SizedBox(height: 12),
            _relocationSteps(from: FluentBarPosition.top, to: FluentBarPosition.bottom),
            const SizedBox(height: 12),
            _relocationSteps(from: FluentBarPosition.bottom, to: FluentBarPosition.top),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.pan_tool_alt_outlined,
        id: 'behavior/touch',
        description: 'By default a bar pauses its countdown while you hold or hover it, closes on tap and can be swiped away. Each of these can be switched per bar, per type or globally.',
        code: '''
FluentBar.info('Read me slowly').pauseOnTouch().withTimeoutBar().show();
FluentBar.info('Cannot be dismissed by hand').undismissible().show();
FluentBar.info('Swipe only').dismissOnTap(false).show();''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton(
              'Pause on touch',
              tone: DemoTone.primary,
              onPressed: () =>
                  FluentBar.info<void>('Hold or hover me: the countdown stops, then continues.').withTitle('Pause on touch').pauseOnTouch().dismissOnTap(false).withTimeoutBar().withId('touch').show(),
            ),
            DemoButton('No pause', onPressed: () => FluentBar.info<void>('Holding me does not stop the countdown.').pauseOnTouch(false).dismissOnTap(false).withTimeoutBar().withId('touch').show()),
            DemoButton('Swipe only', onPressed: () => FluentBar.info<void>('A tap does nothing, a swipe closes me.').dismissOnTap(false).persistent().withId('touch').show()),
            DemoButton(
              'Undismissible',
              tone: DemoTone.warning,
              onPressed: () => FluentBar.warning<void>('Neither tap nor swipe closes me.').undismissible().persistent().withAction('Got it').withId('touch').show(),
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.close_rounded,
        id: 'behavior/close-button',
        description:
            'A cross at the end of the bar. It is off by default: turn it on for one bar, for a type, or for every bar on the Global config screen. It only closes the bar - a running task goes on - and it works also while the bar is loading or its action runs. Snacks, toasts, banners and loading bars stay without it until you ask.',
        code: '''
FluentBar.info('A new version is ready').persistent().withCloseButton().show();
FluentBar.snack('Item moved to trash', action: 'Undo').persistent().withCloseButton().show();
FluentBar.success('The bar brings its own icon.').persistent().withCloseButton(icon: const Icon(Icons.expand_more)).show();

// A type gives the icon to all its bars; the bar wins over the type, the type over the theme.
final collapsing = FluentBarType.info.copyWith(showCloseButton: true, closeIcon: const Icon(Icons.keyboard_arrow_down));
FluentBar.custom(collapsing, 'Every bar of this type has this icon.').persistent().show();

// For every bar (presets and undismissible() bars stay without it):
FluentBar.patchConfig((config) => config.copyWith(defaultShowCloseButton: true));

// The look comes from the theme: icon, size, color, padding and place.
final theme = FluentBarTheme.material.copyWith(
  closeIcon: (context, type, mode) => const Icon(Icons.cancel),
  closeButtonAlignment: (context, type, mode) => CrossAxisAlignment.start,   // the top of a tall bar
);

// In your own content builder put the ready-made button where you need it:
FluentBarCloseButton(controller: entry.controller);''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton(
              'Bar with a close button',
              tone: DemoTone.primary,
              onPressed: () => FluentBar.info<void>('Tap the cross to close me.').withTitle('A new version is ready').persistent().withCloseButton().withId('close').show(),
            ),
            DemoButton('Next to an action', onPressed: () => FluentBar.snack<void>('Item moved to trash', action: 'Undo').persistent().withCloseButton().withId('close').show()),
            DemoButton('Own icon', onPressed: () => FluentBar.success<void>('The bar brings its own icon.').persistent().withCloseButton(icon: const Icon(Icons.expand_more)).withId('close').show()),
            DemoButton(
              'Icon of a type',
              onPressed: () => FluentBar.custom<void>(
                FluentBarType.info.copyWith(showCloseButton: true, closeIcon: const Icon(Icons.keyboard_arrow_down)),
                'Every bar of this type has this icon.',
              ).persistent().withId('close').show(),
            ),
            DemoButton(
              'At the top of a tall bar (theme)',
              onPressed: () => FluentBar.warning<void>('The theme moves the button to the top and swaps the icon. It still sits at the end of the row.')
                  .withTitle('Storage is almost full')
                  .persistent()
                  .withTheme(
                    FluentBarTheme.material.copyWith(
                      closeIcon: (BuildContext context, FluentBarType type, FluentBarThemeMode? mode) => const Icon(Icons.cancel),
                      closeButtonAlignment: (BuildContext context, FluentBarType type, FluentBarThemeMode? mode) => CrossAxisAlignment.start,
                    ),
                  )
                  .withCloseButton()
                  .withId('close')
                  .show(),
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.smart_button_outlined,
        id: 'behavior/actions',
        description: 'An async action shows a loader on the button and holds the countdown until it finishes. Double taps are throttled.',
        code: '''
FluentBar.info('Item moved to trash')
    .withAction('Undo', closeOnAction: false, onPressed: (controller, _) async {
      await api.restore();                       // loader on the button meanwhile
      controller.updateContent(message: 'Restored', type: FluentBarType.success);
    })
    .show();''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton(
              'Async action with loader',
              tone: DemoTone.primary,
              onPressed: () => FluentBar.info<void>('Item moved to trash')
                  .withId('action')
                  .withAction(
                    'Undo',
                    closeOnAction: false,
                    onPressed: (FluentBarController<void> controller, _) async {
                      await Future<void>.delayed(const Duration(seconds: 2));
                      controller
                        ..updateContent(message: 'Item restored', type: FluentBarType.success)
                        ..removeAction();
                    },
                  )
                  .show(),
            ),
            DemoButton(
              'Action that closes',
              onPressed: () => FluentBar.info<void>('New message from Alex').withId('action').withAction('Reply', onPressed: (_, _) => FluentBar.showToast('Opening chat...')).show(),
            ),
            DemoButton(
              'Whole-bar loading',
              onPressed: () {
                final FluentBarEntry<void>? entry = FluentBar.info<void>('Saving your settings').withId('action').withAction('Cancel', closeOnAction: false).show();
                entry?.controller.setLoading(isLoading: true);
                Future<void>.delayed(const Duration(seconds: 2), () {
                  entry?.controller.setLoading(isLoading: false);
                  entry?.update(message: 'Settings saved');
                });
              },
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.widgets_outlined,
        id: 'behavior/custom-action-swipe-inset',
        description:
            'Three smaller knobs: replace the action button with your own widget, choose which way a bar can be swiped, and give one bar its own distance from the edge (the bar wins over its type, the type over the config).',
        code: '''
// Any widget instead of the default action button:
FluentBar.info('2 new messages').copyWith(
  actions: FluentBarActions(
    builder: (context, controller, type, mode) => Row(children: [
      IconButton(icon: const Icon(Icons.reply), onPressed: () => controller.updateContent(message: 'Reply sent', type: FluentBarType.success)),
      IconButton(icon: const Icon(Icons.close), onPressed: controller.close),
    ]),
  ),
).show();

// Swipe sideways instead of up / down:
FluentBar.info('Swipe me left or right')
    .copyWith(behavior: const FluentBarBehavior(dismissDirection: DismissDirection.horizontal))
    .show();

// This bar keeps its own distance from the top edge:
FluentBar.info('160 px from the top').withInsets(top: 160).show();''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton(
              'Custom action widget',
              onPressed: () => FluentBar.info<void>('2 new messages from Alex')
                  .withId('blocks')
                  .persistent()
                  .dismissOnTap(false)
                  .copyWith(
                    actions: FluentBarActions<void>(
                      builder: (BuildContext context, FluentBarController<void> controller, FluentBarType type, FluentBarThemeMode mode) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Reply',
                            icon: const Icon(Icons.reply, size: 20),
                            onPressed: () => controller.updateContent(message: 'Reply sent', type: FluentBarType.success),
                          ),
                          IconButton(visualDensity: VisualDensity.compact, tooltip: 'Close', icon: const Icon(Icons.close, size: 20), onPressed: controller.close),
                        ],
                      ),
                    ),
                  )
                  .show(),
            ),
            DemoButton(
              'Swipe sideways only',
              onPressed: () => FluentBar.info<void>(
                'Swipe me left or right - up does nothing.',
              ).withId('blocks').persistent().dismissOnTap(false).copyWith(behavior: const FluentBarBehavior(dismissDirection: DismissDirection.horizontal, dismissOnTap: false)).show(),
            ),
            DemoButton('Own inset: 160 px from the top', onPressed: () => FluentBar.info<void>('I keep my own distance from the top edge.').withId('blocks').withInsets(top: 160).show()),
            DemoButton('Own inset: at the very top', onPressed: () => FluentBar.info<void>('Inset 0: I ignore the app bar and sit at the edge.').withId('blocks').withInsets(top: 0).show()),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.sports_esports_outlined,
        id: 'behavior/live-bar',
        description:
            'Everything below talks to one bar through its controller: time, content and attention effects. When the type changes, the colors fade to the new look instead of snapping. Attention effects are skipped when the system asks to reduce motion (you can simulate that on the Global config screen).',
        code: '''
final entry = FluentBar.find('live_bar')!;

entry.pause();                 entry.resume();
entry.addDuration(const Duration(seconds: 5));
entry.makePersistent();        // no countdown any more

entry.update(message: 'New text');
entry.update(clearTitle: true);                                             // null keeps a value, a clear... flag removes it
entry.patchAppearance((a) => a.copyWith(backgroundColor: Colors.teal));    // change one setting, keep the rest

entry.shake();                 entry.pulse();   entry.heartbeat(repeat: true);''',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const DemoLabel('Time'),
            const SizedBox(height: 6),
            DemoWrap(
              children: <Widget>[
                DemoButton('Pause', icon: Icons.pause, onPressed: () => _live().pause()),
                DemoButton('Resume', icon: Icons.play_arrow, onPressed: () => _live().resume()),
                DemoButton('+5 s', onPressed: () => _live().addDuration(const Duration(seconds: 5))),
                DemoButton('-3 s', onPressed: () => _live().subtractDuration(const Duration(seconds: 3))),
                DemoButton('Set 4 s & restart', onPressed: () => _live().updateDuration(const Duration(seconds: 4), resetTimer: true)),
                DemoButton('Make persistent', onPressed: () => _live().makePersistent()),
              ],
            ),
            const SizedBox(height: 12),
            const DemoLabel('Content'),
            const SizedBox(height: 6),
            DemoWrap(
              children: <Widget>[
                DemoButton(
                  'Change text',
                  onPressed: () => _live().update(title: 'Updated', message: 'The text changed without re-showing the bar.'),
                ),
                DemoButton('Remove the title', onPressed: () => _live().update(clearTitle: true)),
                DemoButton(
                  'Repaint (patchAppearance)',
                  onPressed: () =>
                      _live().patchAppearance((FluentBarAppearance<dynamic> appearance) => appearance.copyWith(backgroundColor: const Color(0xFF0F766E), themeMode: FluentBarThemeMode.dark)),
                ),
                DemoButton(
                  'Turn into success',
                  tone: DemoTone.success,
                  onPressed: () => _live().controller.updateContent(type: FluentBarType.success, message: 'Now I am a success bar.'),
                ),
                DemoButton(
                  'Turn into error',
                  tone: DemoTone.danger,
                  onPressed: () => _live().controller.updateContent(type: FluentBarType.error, message: 'Now I am an error bar.'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const DemoLabel('Effects'),
            const SizedBox(height: 6),
            DemoWrap(
              children: <Widget>[
                DemoButton('Shake', onPressed: () => _live().shake()),
                DemoButton('Bounce', onPressed: () => _live().bounce()),
                DemoButton('Pulse', onPressed: () => _live().pulse()),
                DemoButton('Heartbeat (loop)', onPressed: () => _live().heartbeat(repeat: true)),
                DemoButton('Stop loop', onPressed: () => _live().pulse(scale: 1.0)),
              ],
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.record_voice_over_outlined,
        id: 'behavior/screen-readers',
        description:
            'How TalkBack and VoiceOver treat a bar. By default it is announced when it appears and when its text changes. A quiet bar is read only when the user moves to it; a hidden one does not exist for the reader. The percent of a progress is not announced on every update unless you ask for it. The dismiss gesture of the reader closes the bar with the reason accessibility. Turn the screen reader on to hear the difference.',
        code:
            '''
FluentBar.info('The link is in your clipboard.').withTitle('Copied').withSemantics(FluentBarSemantics.${_semantics.name}).show();

// For a type or for every bar:
FluentBarType.info.copyWith(semantics: FluentBarSemantics.quiet);
FluentBar.patchConfig((config) => config.copyWith(defaultSemantics: FluentBarSemantics.quiet));

// announce - read out when it appears and when its title or message changes (default)
// quiet    - readable, but never announced by itself
// hidden   - not exposed at all: a blind user will not know about the bar

// The dismiss gesture of the reader counts as the user: FluentBarDismissReason.accessibility.

// Read out every step of a progress (off by default):
const FluentBarProgressTheme(announceUpdates: true);''',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DemoChoice<FluentBarSemantics>(
              label: 'For the screen reader the bar is',
              values: FluentBarSemantics.values,
              selected: _semantics,
              onChanged: (FluentBarSemantics v) => setState(() => _semantics = v),
            ),
            const SizedBox(height: 12),
            DemoWrap(
              children: <Widget>[
                DemoButton(
                  'Show a bar',
                  tone: DemoTone.primary,
                  onPressed: () => _showFresh('semantics', FluentBar.info<void>('The link is in your clipboard.').withTitle('Copied').withSemantics(_semantics)),
                ),
                DemoButton(
                  'Upload with progress',
                  onPressed: () => DemoProgressRunner.playOn(
                    FluentBar.info<void>('Uploading the photo').withId('semantics_progress').withLinearProgress(value: 0, showText: true).withSemantics(_semantics).show(),
                    completedMessage: 'Photo uploaded',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.animation_rounded,
        id: 'behavior/entrance-haptics',
        description: 'Pick how a bar arrives: the previous bar hides and a new one comes in with the chosen animation. Haptic feedback fires when the bar appears (on a real device).',
        code:
            '''
FluentBar.success('Saved').withEntrance(FluentBarEntranceAnimation.${_entrance.name}).withHaptic(FluentBarHapticType.medium).show();
FluentBar.info('No motion').withoutAnimations().show();''',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DemoChoice<FluentBarEntranceAnimation>(
              label: 'Entrance',
              values: FluentBarEntranceAnimation.values,
              selected: _entrance,
              onChanged: (FluentBarEntranceAnimation v) {
                setState(() => _entrance = v);
                _showFresh('entrance', FluentBar.success<void>('Entrance: ${v.name}').withEntrance(v));
              },
            ),
            const SizedBox(height: 12),
            DemoWrap(
              children: <Widget>[
                for (final FluentBarHapticType haptic in FluentBarHapticType.values)
                  DemoButton('Haptic: ${haptic.name}', onPressed: () => _showFresh('entrance', FluentBar.info<void>('Haptic feedback: ${haptic.name}').withHaptic(haptic))),
                DemoButton('No animations', onPressed: () => _showFresh('entrance', FluentBar.info<void>('I appear and disappear instantly.').withoutAnimations())),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}
