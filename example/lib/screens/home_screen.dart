import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';

import '../app/demo_index.dart';
import '../widgets/demo_kit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _search = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<DemoSectionInfo> found = DemoIndex.search(_query);

    final bool isNarrow = MediaQuery.sizeOf(context).width < 620;
    final double side = isNarrow ? 6 : 16;

    return Scaffold(
      appBar: FluentBarTopInset(
        child: AppBar(title: const Text('FluentBar'), actions: const <Widget>[DemoAppBarActions()]),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(side, 4, side, 32),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _Hero(theme: theme),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16 - side),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(height: 20),
                        TextField(
                          controller: _search,
                          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                          onChanged: (String value) => setState(() => _query = value.trim()),
                          decoration: InputDecoration(
                            hintText: 'Search the demo: duplicate, withAction, clearQueue, queue/jump ...',
                            prefixIcon: const Icon(Icons.search_rounded, size: 20),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear',
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    onPressed: () => setState(() {
                                      _search.clear();
                                      _query = '';
                                    }),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_query.isNotEmpty) ...<Widget>[
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 10),
                            child: DemoLabel(found.isEmpty ? 'Nothing found' : '${found.length} ${found.length == 1 ? 'section' : 'sections'}'),
                          ),
                          for (final DemoSectionInfo section in found) _SearchResult(section),
                        ] else ...<Widget>[
                          const Padding(padding: EdgeInsets.only(left: 4, bottom: 10), child: DemoLabel('Explore')),
                          LayoutBuilder(
                            builder: (BuildContext context, BoxConstraints constraints) {
                              final int columns = constraints.maxWidth >= 620 ? 2 : 1;
                              final double width = (constraints.maxWidth - (columns - 1) * 12) / columns;

                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: <Widget>[for (final DemoScreenInfo demo in DemoIndex.screens) SizedBox(width: width, child: _DemoCard(demo))],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResult extends StatelessWidget {
  final DemoSectionInfo section;

  const _SearchResult(this.section);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final DemoScreenInfo screen = section.screen;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openDemo(context, '/${section.code}'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: <Widget>[
                Icon(screen.icon, size: 20, color: screen.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(section.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(
                        '${screen.title}  -  ${section.code}',
                        style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  final ThemeData theme;

  const _Hero({required this.theme});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(colors: <Color>[Color(0xFF4F46E5), Color(0xFF9333EA), Color(0xFFDB2777)], begin: Alignment.topLeft, end: Alignment.bottomRight),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Notifications that\nstay out of your way',
          style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800, height: 1.15),
        ),
        const SizedBox(height: 8),
        Text(
          'Queues, progress, themes, gestures and analytics - one call to show, one chain to customize.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.88), height: 1.4),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _HeroButton('Say hello', Icons.waving_hand_outlined, () => FluentBar.showSuccess('Hello from FluentBar!', title: 'It works')),
            _HeroButton('Snack with undo', Icons.undo, () => FluentBar.showSnack('Message archived', action: 'Undo', onAction: (_, _) => FluentBar.showToast('Restored'))),
            _HeroButton(
              'Run a task',
              Icons.play_arrow_rounded,
              () => FluentBar.future<void>(Future<void>.delayed(const Duration(seconds: 2)), loading: 'Working on it...', success: (_) => 'All done', id: 'hero_task'),
            ),
            _HeroButton('Toast', Icons.chat_bubble_outline, () => FluentBar.showToast('Copied to clipboard')),
            _HeroButton('Banner', Icons.campaign_outlined, () => FluentBar.showBanner('A new version is ready to install.', title: 'Update available', action: 'Later', id: 'hero_banner')),
            _HeroButton('Upload with progress', Icons.cloud_upload_outlined, () {
              final FluentBarEntry<void>? entry = FluentBar.info<void>(
                'Uploading photos',
              ).withId('hero_upload').withLinearProgress(value: 0, showText: true, textEffect: FluentBarProgressTextEffect.roll).atBottom().show();
              DemoProgressRunner.playOn(entry, completedMessage: 'Photos uploaded', motion: DemoProgressMotion.jumps);
            }),
            _HeroButton('Burst of 5', Icons.dynamic_feed_outlined, () {
              const List<(FluentBarType, String, String)> tour = <(FluentBarType, String, String)>[
                (FluentBarType.info, 'One at a time', 'Five bars were just requested at once. They queue up instead of piling on.'),
                (FluentBarType.success, 'One line to show', 'FluentBar.showSuccess(\'Saved\') - no context, no Scaffold, works from anywhere.'),
                (FluentBarType.warning, 'One chain to customize', 'Add only what differs: .withAction(), .withTimeoutBar(), .atBottom() and more.'),
                (FluentBarType.info, 'Alive after it is shown', 'Update the text, the progress or the position of a bar that is already on screen.'),
                (FluentBarType.success, 'Safe by design', 'If your callback or builder throws, the bar still shows and the error is reported.'),
              ];
              for (int i = 0; i < tour.length; i++) {
                FluentBar.showCustom<void>(tour[i].$1, tour[i].$3, title: '${i + 1}/5 - ${tour[i].$2}', id: 'hero_burst_$i', duration: const Duration(milliseconds: 3500));
              }
            }),
          ],
        ),
      ],
    ),
  );
}

class _HeroButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _HeroButton(this.label, this.icon, this.onPressed);

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    style: FilledButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.18), foregroundColor: Colors.white),
    icon: Icon(icon, size: 18),
    label: Text(label),
  );
}

class _DemoCard extends StatelessWidget {
  final DemoScreenInfo demo;

  const _DemoCard(this.demo);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openDemo(context, '/${demo.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: demo.color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(14)),
                child: Icon(demo.icon, color: demo.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(demo.title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(demo.description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.35)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
