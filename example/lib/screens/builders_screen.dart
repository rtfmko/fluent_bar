import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../custom/custom_bar_builder.dart';
import '../custom/custom_bar_theme.dart';
import '../custom/custom_effect_builder.dart';
import '../custom/custom_position_builder.dart';
import '../custom/custom_transition_builder.dart';
import '../widgets/demo_kit.dart';

Widget segmentsProgressBuilder(BuildContext context, ValueListenable<FluentBarProgressState?> notifier) => ValueListenableBuilder<FluentBarProgressState?>(
  valueListenable: notifier,
  builder: (BuildContext context, FluentBarProgressState? state, _) {
    const int segments = 10;
    final int filled = ((state?.progress ?? 0) * segments).round();

    return Row(
      children: <Widget>[
        for (int i = 0; i < segments; i++)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(color: i < filled ? Colors.lightGreenAccent : Colors.white24, borderRadius: BorderRadius.circular(3)),
            ),
          ),
      ],
    );
  },
);

class BuildersScreen extends StatefulWidget {
  const BuildersScreen({super.key});

  @override
  State<BuildersScreen> createState() => _BuildersScreenState();
}

class _BuildersScreenState extends State<BuildersScreen> {
  static const String _id = 'builder_demo';

  @override
  void dispose() {
    FluentBar.patchConfig((FluentBarConfig config) => config.copyWith(clearDefaultTransitionBuilder: true));
    super.dispose();
  }

  void _runProgress(FluentBarItem<void> item, {required String done}) {
    FluentBar.close(_id);
    DemoProgressRunner.playOn(item.withId('${_id}_progress').show(), completedMessage: done);
  }

  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Builders',
    subtitle:
        'When settings are not enough, replace a part of the bar with your own widget. Every builder follows the usual priority - the bar, then its type, then the config - and every one is guarded: if it throws, the bar falls back to the default and the error goes to the error handler (try it on the Analytics & safety screen).',
    children: <Widget>[
      DemoSection(
        icon: Icons.dashboard_customize_outlined,
        id: 'builders/content-builder',
        description: 'Replaces everything inside the bar. Position, queue, timers, gestures and animations keep working around your widget. The entry gives you the item and the controller.',
        code: '''
// For one bar:
FluentBar.info('unused').withContent((context, entry) => MyCard(entry)).show();

// For a type - every bar of this type uses it:
final chat = FluentBarType.info.copyWith(builder: (context, entry) => ChatBubble(entry.item.message));
FluentBar.showCustom(chat, 'Are we still on for lunch?');

// For the whole app:
FluentBarConfig(defaultBuilder: (context, entry) => MyBar(entry));''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton('On one bar', tone: DemoTone.primary, onPressed: () => FluentBar.info<void>('unused').withContent(customBarBuilder).withId(_id).show()),
            DemoButton(
              'On a type',
              onPressed: () => FluentBar.showCustom<void>(
                FluentBarType.info.copyWith(
                  builder: (BuildContext context, FluentBarEntry<dynamic> entry) => Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(20).copyWith(bottomLeft: const Radius.circular(4)),
                    ),
                    child: Text(entry.item.message, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),
                'Are we still on for lunch?',
                id: _id,
              ),
            ),
            DemoButton(
              'Uses the controller',
              onPressed: () => FluentBar.info<void>('unused')
                  .withId(_id)
                  .withDuration(const Duration(seconds: 8))
                  .withContent(
                    (BuildContext context, FluentBarEntry<void> entry) => Card(
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: <Widget>[
                            ValueListenableBuilder<Duration>(
                              valueListenable: entry.controller.remainingDurationNotifier,
                              builder: (_, Duration left, _) => CircleAvatar(child: Text('${(left.inMilliseconds / 1000).ceil()}')),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('My own countdown, driven by the controller.')),
                            TextButton(onPressed: () => entry.addDuration(const Duration(seconds: 5)), child: const Text('+5 s')),
                            FluentBarCloseButton(controller: entry.controller),
                          ],
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
        icon: Icons.widgets_outlined,
        id: 'builders/standard-parts',
        description:
            'Your own layout does not have to redraw everything. FluentBarTaskProgressWidget is the standard progress indicator of the library: give it the progress notifier of the controller and it animates, shows the text and the success icon by itself.',
        code: '''
FluentBar.info('Exporting the report')
    .withLinearProgress(value: 0)
    .withContent((context, entry) => Card(
          child: Column(children: [
            Text(entry.item.message),
            FluentBarTaskProgressWidget(
              progressNotifier: entry.controller.progressStateNotifier,
              theme: const FluentBarProgressTheme(showText: true),
              defaultColor: Theme.of(context).colorScheme.primary,
              successIcon: const Icon(Icons.check_circle),
            ),
          ]),
        ))
    .show();''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton(
              'Own card, standard progress',
              tone: DemoTone.primary,
              onPressed: () => _runProgress(
                FluentBar.info<void>('Exporting the report')
                    .withLinearProgress(value: 0)
                    .withContent(
                      (BuildContext context, FluentBarEntry<void> entry) => Card(
                        margin: const EdgeInsets.all(12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Icon(Icons.description_outlined),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(entry.item.message, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              FluentBarTaskProgressWidget(
                                progressNotifier: entry.controller.progressStateNotifier,
                                theme: const FluentBarProgressTheme(showText: true),
                                defaultColor: Theme.of(context).colorScheme.primary,
                                successIcon: const Icon(Icons.check_circle, color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                done: 'Report exported',
              ),
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.open_in_full_rounded,
        id: 'builders/position-builder',
        description: 'Puts the bar anywhere on screen. Note the rule that keeps things predictable: an explicit position set closer to the bar cancels a position builder set further away.',
        code: '''
FluentBar.show(
  message: 'Placed by a builder',
  options: FluentBarOptions(
    behavior: FluentBarBehavior(
      positionBuilder: (context, child) => Align(alignment: const Alignment(-0.8, -0.5), child: child),
    ),
  ),
);''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton(
              'Placed and rotated',
              tone: DemoTone.primary,
              onPressed: () => FluentBar.show<void>(
                message: 'Placed and rotated by a position builder.',
                id: _id,
                options: const FluentBarOptions<void>(behavior: FluentBarBehavior(positionBuilder: customPositionBuilder)),
              ),
            ),
            DemoButton(
              'Type has a builder, the bar says atBottom()',
              onPressed: () =>
                  FluentBar.custom<void>(FluentBarType.info.copyWith(positionBuilder: customPositionBuilder), 'My explicit position wins over the builder of my type.').withId(_id).atBottom().show(),
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.animation_rounded,
        id: 'builders/transition-effect',
        description: 'The transition builder draws how a bar enters and leaves; it receives the animation. The effect builder draws an attention effect you start with customEffect().',
        code: '''
FluentBarAppearance(
  transitionBuilder: (context, animation, child) => ScaleTransition(scale: animation, child: child),
  customEffectBuilder: (context, controller, child) => MyGlow(animation: controller, child: child),
)

entry.customEffect(duration: const Duration(milliseconds: 700), repeat: true);

// The same builder for every bar: one level up, in the config.
FluentBar.patchConfig((config) => config.copyWith(defaultTransitionBuilder: mySpin));
FluentBar.patchConfig((config) => config.copyWith(clearDefaultTransitionBuilder: true));   // back to the default''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton(
              'Custom entrance',
              tone: DemoTone.primary,
              onPressed: () => FluentBar.show<void>(
                message: 'I spin in with a custom transition.',
                id: _id,
                options: FluentBarOptions<void>(
                  appearance: FluentBarAppearance<void>(transitionBuilder: customTransitionBuilder, transitionDuration: const Duration(milliseconds: 600)),
                ),
              ),
            ),
            DemoButton(
              'Custom entrance for every bar (config)',
              onPressed: () {
                FluentBar.patchConfig((FluentBarConfig config) => config.copyWith(defaultTransitionBuilder: customTransitionBuilder));
                FluentBar.showInfo<void>('I set nothing myself: the entrance comes from the config.', id: _id);
              },
            ),
            DemoButton(
              'Back to the default entrance',
              onPressed: () {
                FluentBar.patchConfig((FluentBarConfig config) => config.copyWith(clearDefaultTransitionBuilder: true));
                FluentBar.showInfo<void>('The config builder is cleared: the usual slide again.', id: _id);
              },
            ),
            DemoButton(
              'Custom looping effect',
              onPressed: () => FluentBar.show<void>(
                message: 'A custom effect drives me.',
                id: _id,
                options: FluentBarOptions<void>(appearance: FluentBarAppearance<void>(customEffectBuilder: customEffectBuilder)),
              )?.customEffect(duration: const Duration(milliseconds: 700), repeat: true),
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.downloading_rounded,
        id: 'builders/progress-label',
        description:
            'The progress builder replaces the indicator itself and listens to the progress on its own. The label builder only changes the text next to the standard indicator. Both are part of FluentBarProgressTheme, so they can come from the bar, its type or the config.',
        code: '''
FluentBarProgressTheme(
  // Your own indicator:
  progressBuilder: (context, notifier) => MySegments(notifier),
)

FluentBarProgressTheme(
  showText: true,
  // Or just your own text:
  labelBuilder: (state) => '\${((state.progress ?? 0) * 48).round()} of 48 MB',
)''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton(
              'Own indicator (segments)',
              tone: DemoTone.primary,
              onPressed: () => _runProgress(
                FluentBar.info<void>('Installing update')
                    .withProgress(const FluentBarProgressState.value(0))
                    .copyWith(
                      appearance: const FluentBarAppearance<void>(progressTheme: FluentBarProgressTheme(progressBuilder: segmentsProgressBuilder)),
                    ),
                done: 'Update installed',
              ),
            ),
            DemoButton(
              'Own label',
              onPressed: () => _runProgress(
                FluentBar.info<void>('Downloading the map')
                    .withLinearProgress(value: 0, showText: true)
                    .copyWith(
                      appearance: FluentBarAppearance<void>(
                        progressTheme: FluentBarProgressTheme(
                          showText: true,
                          textEffect: FluentBarProgressTextEffect.fade,
                          labelBuilder: (FluentBarProgressState state) => '${((state.progress ?? 0) * 48).round()} of 48 MB',
                        ),
                      ),
                    ),
                done: 'Map downloaded',
              ),
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.smart_button_outlined,
        id: 'builders/action-builder',
        description:
            'Any widget in place of the default action button. You get the controller, so your buttons can update or close the bar. Call controller.handleAction to keep what the default button does: the loader, the paused countdown and protection from double taps.',
        code: '''
// Your own button, the standard handling.
FluentBarActions(
  builder: (context, controller, type, mode) => ValueListenableBuilder<bool>(
    valueListenable: controller.isActionExecutingNotifier,
    builder: (context, isBusy, _) => OutlinedButton(
      onPressed: isBusy ? null : () => controller.handleAction(onPressed: (controller, payload) => retry()),
      child: Text(isBusy ? 'Retrying...' : 'Retry'),
    ),
  ),
)

FluentBar.info('2 new messages').copyWith(
  actions: FluentBarActions(
    builder: (context, controller, type, mode) => Row(children: [
      IconButton(icon: const Icon(Icons.reply), onPressed: () => controller.updateContent(message: 'Reply sent')),
      IconButton(icon: const Icon(Icons.close), onPressed: controller.close),
    ]),
  ),
).show();''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton(
              'Own button with handleAction',
              tone: DemoTone.primary,
              onPressed: () => FluentBar.warning<void>('The upload was interrupted.')
                  .withId(_id)
                  .persistent()
                  .dismissOnTap(false)
                  .copyWith(
                    actions: FluentBarActions<void>(
                      builder: (BuildContext context, FluentBarController<void> controller, FluentBarType type, FluentBarThemeMode mode) => ValueListenableBuilder<bool>(
                        valueListenable: controller.isActionExecutingNotifier,
                        builder: (BuildContext context, bool isBusy, _) => OutlinedButton(
                          onPressed: isBusy ? null : () => controller.handleAction(onPressed: (_, _) => Future<void>.delayed(const Duration(seconds: 2))),
                          child: Text(isBusy ? 'Retrying...' : 'Retry'),
                        ),
                      ),
                    ),
                  )
                  .show(),
            ),
            DemoButton(
              'Two icon buttons',
              onPressed: () => FluentBar.info<void>('2 new messages from Alex')
                  .withId(_id)
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
          ],
        ),
      ),
      DemoSection(
        icon: Icons.layers_outlined,
        id: 'builders/theme-hooks',
        description:
            'A theme has builders of its own: wrapContainer wraps the whole bar, buildTimeoutBar draws the countdown. The neon theme uses wrapContainer to run the countdown around the border; copyWith adds a hook to any built-in theme.',
        code: '''
class NeonTheme extends FluentBarTheme {
  @override
  Widget wrapContainer(context, child, entry, type, {themeMode}) => PerimeterTimeoutBar(
        progressNotifier: entry.controller.remainingProgressNotifier,
        borderRadius: borderRadius(context, type),
        child: child,
      );
}

// Or patch a built-in theme:
final glowing = FluentBarTheme.material.copyWith(
  wrapContainer: (context, child, entry, type, mode) => DecoratedBox(decoration: myGlow, child: child),
);''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton(
              'Countdown around the border',
              tone: DemoTone.primary,
              onPressed: () => FluentBar.info<void>(
                'The theme draws my countdown along the border.',
              ).withTitle('Neon theme').withTheme(const CustomBarTheme()).withDuration(const Duration(seconds: 6)).withId(_id).show(),
            ),
            DemoButton(
              'Material + a glow hook',
              onPressed: () => FluentBar.success<void>('A built-in theme with one hook added through copyWith.')
                  .withTheme(
                    FluentBarTheme.material.copyWith(
                      wrapContainer: (BuildContext context, Widget child, FluentBarEntry<dynamic> entry, FluentBarType type, FluentBarThemeMode? themeMode) => DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: <BoxShadow>[BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.55), blurRadius: 24, spreadRadius: 2)],
                        ),
                        child: child,
                      ),
                    ),
                  )
                  .withId(_id)
                  .show(),
            ),
          ],
        ),
      ),
    ],
  );
}
