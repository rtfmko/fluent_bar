import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';

import '../app/app_state.dart';
import '../widgets/demo_kit.dart';
import '../widgets/telemetry_views.dart';
import 'monitor_screen.dart';

// A custom duplicate rule replaces the default one, so the id check is repeated here.
bool sameGroupComparator(FluentBarItem<dynamic> a, FluentBarItem<dynamic> b) {
  if (a.id != null && a.id == b.id) return true;

  final Object? group = a.meta?['group'];
  return group != null && group == b.meta?['group'];
}

class QueueScreen extends StatefulWidget {
  const QueueScreen({super.key});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  int _counter = 0;
  int _duplicateSends = 0;
  int _chatMessages = 0;
  bool _checkoutOnScreen = true;

  void _sendChatMessage() {
    _chatMessages++;
    FluentBar.info<void>(
      'Message #$_chatMessages: are we still on for lunch?',
    ).withTitle('Alex').withMeta(const <String, dynamic>{'group': 'chat_alex'}).withDuration(const Duration(seconds: 5)).withTimeoutBar().show();
  }

  void _patch(FluentBarConfig Function(FluentBarConfig config) change) => FluentBar.patchConfig(change);

  void _enqueue(FluentBarPriority priority, {bool bottom = false}) {
    _counter++;
    final FluentBarItem<void> draft = FluentBar.custom<void>(
      switch (priority) {
        FluentBarPriority.critical => FluentBarType.error,
        FluentBarPriority.high => FluentBarType.warning,
        FluentBarPriority.normal => FluentBarType.info,
        FluentBarPriority.low => FluentBarType.success,
      },
      '${priority.name} priority, ${bottom ? 'bottom' : 'top'} region',
      title: 'Bar #$_counter',
      id: 'queue_$_counter',
    ).withPriority(priority).withDuration(const Duration(seconds: 3)).withTimeoutBar();

    (bottom ? draft.atBottom() : draft.atTop()).show();
  }

  void _burst({bool bottom = false}) {
    for (final FluentBarPriority priority in <FluentBarPriority>[FluentBarPriority.low, FluentBarPriority.normal, FluentBarPriority.high, FluentBarPriority.normal, FluentBarPriority.critical]) {
      _enqueue(priority, bottom: bottom);
    }
  }

  void _sendDuplicate({bool withProgress = false}) {
    _duplicateSends++;
    final String policy = FluentBar.currentConfig.defaultDuplicatePolicy.name;
    final FluentBarItem<void> draft = FluentBar.info<void>(
      'Sent $_duplicateSends time(s) with the "$policy" policy',
    ).withTitle('Same id every time').withId('duplicate_demo').withDuration(const Duration(seconds: 5)).withTimeoutBar();

    (withProgress ? draft.withLinearProgress(value: (_duplicateSends % 11) / 10, showText: true) : draft).show();
  }

  void _withLastWaiting(void Function(String id) action) {
    final List<FluentBarEntry<dynamic>> queue = FluentBar.mainQueue;
    final String? id = queue.isEmpty ? null : queue.last.item.id;
    id == null ? FluentBar.showToast('The top queue is empty') : action(id);
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<FluentBarConfig>(
    valueListenable: FluentBar.configNotifier,
    builder: (BuildContext context, FluentBarConfig config, _) {
      final StrategyOption strategy = AppState.strategyOf(config);

      return DemoPage(
        title: 'Queue & duplicates',
        subtitle:
            'Only one bar per region is on screen. The rest wait in a queue; a strategy decides who is next and who is dropped when the queue is full. The live view of both queues is pinned to the bottom.',
        bottomNavigationBar: const DemoBottomBar(child: QueueLanes()),
        children: <Widget>[
          DemoSection(
            icon: Icons.settings_suggest_outlined,
            id: 'queue/settings',
            description: '${strategy.hint} These are global settings - the same ones as on the Global config screen.',
            code:
                '''
FluentBar.patchConfig((config) => config.copyWith(
  defaultQueueStrategy: const ${strategy.strategy.runtimeType}(),
  maxQueueLength: ${config.maxQueueLength},
  enableMultiRegion: ${config.enableMultiRegion},
));''',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DemoChoice<StrategyOption>(
                  label: 'Strategy',
                  values: AppState.strategies,
                  selected: strategy,
                  labelOf: (StrategyOption o) => o.label,
                  onChanged: (StrategyOption v) => _patch((FluentBarConfig c) => c.copyWith(defaultQueueStrategy: v.strategy)),
                ),
                const SizedBox(height: 12),
                DemoSlider(
                  label: 'Max queue length (per region)',
                  value: config.maxQueueLength.toDouble(),
                  min: 1,
                  max: 30,
                  divisions: 29,
                  format: (double v) => '${v.round()}',
                  onChanged: (double v) => _patch((FluentBarConfig c) => c.copyWith(maxQueueLength: v.round())),
                ),
                DemoSwitch(
                  label: 'Two regions (top + bottom)',
                  hint: 'Off: every bar goes through a single queue, wherever it is placed',
                  value: config.enableMultiRegion,
                  onChanged: (bool v) => _patch((FluentBarConfig c) => c.copyWith(enableMultiRegion: v)),
                ),
              ],
            ),
          ),
          DemoSection(
            icon: Icons.playlist_add_rounded,
            id: 'queue/fill',
            description: 'Bars carry a priority (low, normal, high, critical). Watch the live view at the bottom to see how the strategy orders them.',
            code: '''
FluentBar.error('Payment failed').withPriority(FluentBarPriority.critical).show();
FluentBar.success('Saved').withPriority(FluentBarPriority.low).atBottom().show();''',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DemoWrap(
                  children: <Widget>[
                    DemoButton('Burst of 5 (top)', icon: Icons.north, tone: DemoTone.primary, onPressed: _burst),
                    DemoButton('Burst of 5 (bottom)', icon: Icons.south, tone: DemoTone.primary, onPressed: () => _burst(bottom: true)),
                  ],
                ),
                const SizedBox(height: 10),
                DemoWrap(
                  children: <Widget>[
                    DemoButton('+ low', tone: DemoTone.success, onPressed: () => _enqueue(FluentBarPriority.low)),
                    DemoButton('+ normal', onPressed: () => _enqueue(FluentBarPriority.normal)),
                    DemoButton('+ high', tone: DemoTone.warning, onPressed: () => _enqueue(FluentBarPriority.high)),
                    DemoButton('+ critical', tone: DemoTone.danger, onPressed: () => _enqueue(FluentBarPriority.critical)),
                  ],
                ),
                const SizedBox(height: 12),
                DemoWrap(
                  children: <Widget>[
                    DemoButton(
                      'Open Monitor: generator and the story of every bar',
                      icon: Icons.monitor_heart_outlined,
                      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MonitorScreen())),
                    ),
                  ],
                ),
              ],
            ),
          ),
          DemoSection(
            icon: Icons.fast_forward_rounded,
            id: 'queue/jump',
            description: 'A forced bar replaces the one on screen. You can also promote a bar that is already waiting.',
            code: '''
FluentBar.error('Connection lost').forced().show();              // show now
FluentBar.forceItemFromQueue(id: 'queue_7');                     // pull a waiting bar to the screen
FluentBar.updateItemPriority(id: 'queue_7', newPriority: FluentBarPriority.critical);''',
            child: DemoWrap(
              children: <Widget>[
                DemoButton(
                  'Show a forced bar',
                  icon: Icons.priority_high_rounded,
                  tone: DemoTone.danger,
                  onPressed: () => FluentBar.error<void>('I skipped the whole queue.').withTitle('Forced').withId('forced_${_counter++}').withDuration(const Duration(seconds: 3)).forced().show(),
                ),
                DemoButton('Force the last waiting bar', onPressed: () => _withLastWaiting((String id) => FluentBar.forceItemFromQueue(id: id))),
                DemoButton(
                  'Make the last one critical',
                  onPressed: () => _withLastWaiting((String id) => FluentBar.updateItemPriority(id: id, newPriority: FluentBarPriority.critical)),
                ),
              ],
            ),
          ),
          DemoSection(
            icon: Icons.copy_all_rounded,
            id: 'queue/duplicates',
            description: 'What happens when a bar with the same id is shown again. A bar that carries progress is always treated as a progress update of the existing one.',
            code:
                '''
// Global default:
FluentBar.patchConfig((config) => config.copyWith(defaultDuplicatePolicy: FluentBarDuplicatePolicy.${config.defaultDuplicatePolicy.name}));

// Or for one bar:
FluentBar.info('Syncing').withId('sync').withDuplicatePolicy(FluentBarDuplicatePolicy.${config.defaultDuplicatePolicy.name}).show();

// allow               - show as a separate bar
// ignore              - keep the existing bar as it is
// update              - replace its content (default)
// updateAndResetTimer - replace and restart the countdown

// By default two bars are duplicates when their ids match (or, without ids, when they are equal).
// Your own rule replaces that:
FluentBar.patchConfig((config) => config.copyWith(
  duplicateComparator: (a, b) =>
      (a.id != null && a.id == b.id) || (a.meta?['group'] != null && a.meta?['group'] == b.meta?['group']),
));
FluentBar.info('Message #2').withMeta({'group': 'chat_alex'}).show();   // updates the bar of this chat''',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DemoChoice<FluentBarDuplicatePolicy>(
                  label: 'Policy (global default)',
                  values: FluentBarDuplicatePolicy.values,
                  selected: config.defaultDuplicatePolicy,
                  onChanged: (FluentBarDuplicatePolicy v) => _patch((FluentBarConfig c) => c.copyWith(defaultDuplicatePolicy: v)),
                ),
                const SizedBox(height: 12),
                DemoWrap(
                  children: <Widget>[
                    DemoButton('Send the same bar again', tone: DemoTone.primary, onPressed: _sendDuplicate),
                    DemoButton('Send it with progress (+10% each time)', onPressed: () => _sendDuplicate(withProgress: true)),
                  ],
                ),
                const SizedBox(height: 12),
                DemoSwitch(
                  label: 'Own rule: bars of one group are the same bar',
                  hint: 'duplicateComparator. Off: every chat message below is a new bar and they queue up. On: they update one bar',
                  value: config.duplicateComparator != null,
                  onChanged: (bool v) => _patch((FluentBarConfig c) => v ? c.copyWith(duplicateComparator: sameGroupComparator) : c.copyWith(clearDuplicateComparator: true)),
                ),
                const SizedBox(height: 4),
                DemoWrap(
                  children: <Widget>[DemoButton('New message in the same chat (no id)', icon: Icons.chat_bubble_outline, onPressed: _sendChatMessage)],
                ),
              ],
            ),
          ),
          DemoSection(
            icon: Icons.cleaning_services_outlined,
            id: 'queue/clean-up',
            child: DemoWrap(
              children: <Widget>[
                DemoButton('clearQueue()', onPressed: FluentBar.clearQueue),
                DemoButton('closeActive()', onPressed: FluentBar.closeActive),
                DemoButton('closeAll()', onPressed: FluentBar.closeAll),
                DemoButton('dismissAndClear()', tone: DemoTone.danger, onPressed: FluentBar.dismissAndClear),
              ],
            ),
          ),
          DemoSection(
            icon: Icons.sell_outlined,
            id: 'queue/tags',
            description:
                'A tag groups bars so that they can be closed together. FluentBarOwner does it by itself when a part of the app goes away: the shown bar closes and the queued ones never appear. Bars without the tag stay. A tag gives no priority.',
            code: '''
FluentBar.error('Card declined').withTag('checkout').show();
FluentBar.info('Promo code applied').withTags({'checkout', 'promo'}).show();   // any of its tags closes it

FluentBar.closeTag('checkout');          // the shown bar and the queued ones
FluentBar.findByTag('checkout');         // look without closing

// Tie the bars to a screen: they go when the widget leaves the tree.
FluentBarOwner(
  tag: 'checkout',
  child: CheckoutScreen(),
);''',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DemoSwitch(
                  label: 'The checkout panel is on screen',
                  hint: 'Turning it off removes FluentBarOwner from the tree',
                  value: _checkoutOnScreen,
                  onChanged: (bool v) => setState(() => _checkoutOnScreen = v),
                ),
                const SizedBox(height: 8),
                if (_checkoutOnScreen)
                  const FluentBarOwner(
                    tag: 'checkout',
                    child: DemoNote('FluentBarOwner(tag: "checkout") is in the tree.', icon: Icons.shopping_cart_outlined),
                  )
                else
                  const DemoNote('The owner is gone, and so are the bars with its tag.', icon: Icons.remove_shopping_cart_outlined),
                const SizedBox(height: 8),
                DemoWrap(
                  children: <Widget>[
                    DemoButton(
                      'Show 3 checkout bars',
                      tone: DemoTone.primary,
                      onPressed: () {
                        FluentBar.info<void>('Card declined').withTitle('Checkout').persistent().withTag('checkout').show();
                        FluentBar.info<void>('Promo code applied').withTitle('Checkout + promo').persistent().withTags(<String>{'checkout', 'promo'}).show();
                        FluentBar.info<void>('Delivery slot is taken').withTitle('Checkout').persistent().withTag('checkout').show();
                      },
                    ),
                    DemoButton('Show a bar without a tag', onPressed: () => FluentBar.info<void>('I belong to the whole app.').persistent().atBottom().withId('untagged').show()),
                    DemoButton("findByTag('checkout')", onPressed: () => FluentBar.showToast('${FluentBar.findByTag('checkout').length} bar(s) with the tag', id: 'tag_count')),
                    DemoButton("closeTag('promo')", onPressed: () => FluentBar.closeTag('promo')),
                    DemoButton("closeTag('checkout')", tone: DemoTone.danger, onPressed: () => FluentBar.closeTag('checkout')),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}
