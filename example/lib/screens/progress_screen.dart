import 'dart:async';

import 'package:fluent_bar/fluent_bar.dart';
import 'package:flutter/material.dart';

import '../widgets/demo_kit.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

enum _Way { controller, entry, sameId }

class _ProgressScreenState extends State<ProgressScreen> {
  FluentBarBytesLabel _bytesLabel = FluentBarBytesLabel.amount;
  Timer? _downloadTimer;

  // Plays a download: `updateBytes` gets the same (received, total) pairs a network library reports.
  void _download({required bool knowsSize, bool sizeArrivesLater = false, bool circular = false}) {
    const int size = 48 * 1024 * 1024;
    final FluentBarItem<void> draft = FluentBar.info<void>(
      sizeArrivesLater ? 'Downloading (the size arrives a moment later)' : (knowsSize ? 'Downloading the offline map' : 'Downloading (the server did not say how much)'),
    ).withId('progress_bytes').atBottom();
    final FluentBarEntry<void>? entry = (circular ? draft.withCircularProgress(showText: true) : draft.withLinearProgress(showText: true)).show();

    int received = 0;
    _downloadTimer?.cancel();
    _downloadTimer = Timer.periodic(const Duration(milliseconds: 120), (Timer timer) {
      if (entry == null || !identical(FluentBar.find('progress_bytes'), entry)) return timer.cancel();

      received += size ~/ 40;
      if (sizeArrivesLater) {
        // The same bar, the same indicator: it is endless while the size is unknown and turns
        // into a normal one as soon as a real total is passed.
        entry.updateBytes(received, received < size ~/ 3 ? null : size, label: _bytesLabel);
        if (received >= size) timer.cancel();
      } else if (knowsSize) {
        entry.updateBytes(received, size, label: _bytesLabel);
        if (received >= size) timer.cancel();
      } else if (received >= size) {
        timer.cancel();
        entry.completeProgress(message: 'Downloaded 48 MB', type: FluentBarType.success);
      } else {
        entry.updateBytes(received, -1);
      }
    });
  }

  static const String _id = 'progress_demo';

  FluentBarProgressStyle _style = FluentBarProgressStyle.linear;
  FluentBarProgressPosition _position = FluentBarProgressPosition.bottom;
  FluentBarProgressTextEffect _effect = FluentBarProgressTextEffect.roll;
  bool _showText = true;
  bool _fraction = false;

  bool _hideSuccess = false;

  double _jumpMs = 800;

  bool _toastCallbacks = false;

  _Way _way = _Way.controller;

  final DemoProgressRunner _runner = DemoProgressRunner(loop: true);
  final DemoProgressRunner _retryRunner = DemoProgressRunner();

  FluentBarProgressState? _sent;

  bool get _isRunning => _runner.isRunning;

  @override
  void initState() {
    super.initState();
    _runner.addListener(_onRunner);
  }

  void _onRunner() {
    if (mounted) setState(() {});
  }

  void _start() {
    _sent = null;
    _runner.start((double value) {
      final FluentBarProgressState state = _state(value);
      if (state == _sent) return;
      _sent = state;

      switch (_way) {
        case _Way.controller:
          _viaController(state);
        case _Way.entry:
          _viaEntry(value);
        case _Way.sameId:
          _viaSameId(state);
      }
    });
  }

  void _halt() {
    _runner.stop();
    FluentBar.close(_id);
  }

  String get _stateCode => _fraction ? 'const FluentBarProgressState.fraction(12, 20)' : 'const FluentBarProgressState.value(0.6)';

  String get _lookCode {
    final bool isLinear = _style == FluentBarProgressStyle.linear;
    final FluentBarProgressPosition defaultPosition = isLinear ? FluentBarProgressPosition.bottom : FluentBarProgressPosition.replaceIcon;
    final List<String> args = <String>[
      _fraction ? 'state: const FluentBarProgressState.fraction(12, 20)' : 'value: 0.6',
      if (_showText) 'showText: true',
      if (_position != defaultPosition) 'position: FluentBarProgressPosition.${_position.name}',
      if (_showText && _effect != FluentBarProgressTextEffect.count) 'textEffect: FluentBarProgressTextEffect.${_effect.name}',
      if (_hideSuccess) 'successIconDuration: const Duration(milliseconds: 1500)',
      if (_jumpMs != 800) 'animationDuration: const Duration(milliseconds: ${_jumpMs.round()})',
    ];
    return "FluentBar.info('Uploading photos to the cloud')\n    .withTitle('Upload')\n    .${isLinear ? 'withLinearProgress' : 'withCircularProgress'}(${args.join(', ')})\n    .show();";
  }

  // The first attempt breaks at 60%, the retry goes through. One bar all the way.
  void _downloadWithRetry({bool breaks = true}) {
    final FluentBarEntry<void>? entry = FluentBar.info<void>('Downloading the map')
        .withId('retry_demo')
        .withLinearProgress(value: 0, showText: true)
        .withCancelButton('Cancel', onCancel: _retryRunner.stop, canceledMessage: 'Download cancelled', canceledType: FluentBarType.warning)
        .show();

    _retryRunner.start((double value) {
      if (entry == null || !identical(FluentBar.find('retry_demo'), entry)) {
        scheduleMicrotask(_retryRunner.stop);
      } else if (breaks && value >= 0.6) {
        scheduleMicrotask(_retryRunner.stop);
        entry.failProgress(message: 'Download failed: no connection', type: FluentBarType.warning, retryLabel: 'Retry', onRetry: () => _downloadWithRetry(breaks: false));
      } else if (value < 1) {
        entry.updateValue(value);
      } else {
        entry.completeProgress(message: 'Map downloaded', type: FluentBarType.success);
      }
    });
  }

  @override
  void dispose() {
    _runner
      ..removeListener(_onRunner)
      ..dispose();
    _retryRunner.dispose();
    FluentBar.close('retry_demo');
    FluentBar.close(_id);
    _downloadTimer?.cancel();
    FluentBar.close('progress_bytes');
    super.dispose();
  }

  static const int _files = 20;
  static const String _doneMessage = 'All photos are in the cloud';

  FluentBarProgressState _state(double value) => _fraction ? FluentBarProgressState.fraction((value * _files).round(), _files) : FluentBarProgressState.value(value);

  FluentBarProgressTheme _look() => FluentBarProgressTheme(
    style: _style,
    position: _position,
    showText: _showText,
    textEffect: _effect,
    successIconDuration: _hideSuccess ? const Duration(milliseconds: 1500) : null,
    animationDuration: Duration(milliseconds: _jumpMs.round()),
    size: _style == FluentBarProgressStyle.circular && _position != FluentBarProgressPosition.replaceIcon ? 32 : 24,
  );

  void _toast(String callback) {
    if (_toastCallbacks) FluentBar.showToast('$callback fired', id: 'progress_callback');
  }

  FluentBarItem<void> _draft(FluentBarProgressState state) => FluentBar.info<void>('Uploading photos to the cloud')
      .withId(_id)
      .withTitle('Upload')
      .withProgress(state)
      .copyWith(
        appearance: FluentBarAppearance<void>(progressTheme: _look()),
        callbacks: FluentBarCallbacks<void>(
          onProgressCompleted: (_) => _toast('onProgressCompleted'),
          onProgressFailed: (_) => _toast('onProgressFailed'),
          onProgressCanceled: (_) => _toast('onProgressCanceled'),
        ),
      );

  void _setLook(VoidCallback change) {
    setState(change);

    final FluentBarEntry<dynamic>? entry = FluentBar.find(_id);
    if (entry == null) return;
    entry.patchAppearance((FluentBarAppearance<dynamic> appearance) => appearance.copyWith(progressTheme: _look()));
  }

  FluentBarEntry<dynamic>? _bar() => FluentBar.find(_id) ?? _draft(_state(0)).show();

  void _resetTexts(FluentBarEntry<dynamic>? entry) => entry?.controller.updateContent(message: 'Uploading photos to the cloud', type: FluentBarType.info);

  void _viaController(FluentBarProgressState state) {
    final FluentBarEntry<dynamic>? entry = _bar();
    if (!state.isCompleted) _resetTexts(entry);
    entry?.controller.updateProgress(state, completedMessage: _doneMessage, completedType: FluentBarType.success);
  }

  void _viaEntry(double value) {
    final FluentBarEntry<dynamic>? entry = _bar();
    if (value < 1) _resetTexts(entry);
    _fraction
        ? entry?.updateFraction((value * _files).round(), _files, completedMessage: _doneMessage, completedType: FluentBarType.success)
        : entry?.updateValue(value, completedMessage: _doneMessage, completedType: FluentBarType.success);
  }

  void _viaSameId(FluentBarProgressState state) {
    final FluentBarItem<void> next = _draft(state);
    (state.isCompleted ? next.copyWith(message: _doneMessage, type: FluentBarType.success) : next).show();
  }

  void _stop(void Function(FluentBarEntry<dynamic> entry) action) {
    _runner.stop();
    final FluentBarEntry<dynamic>? entry = FluentBar.find(_id);
    if (entry == null) {
      FluentBar.showToast('Start the upload demo first', id: 'progress_hint');
      return;
    }
    action(entry);
  }

  void _bigJump() {
    _runner.stop();
    final FluentBarEntry<dynamic>? entry = _bar();
    _resetTexts(entry);
    entry?.controller.updateProgress(const FluentBarProgressState.value(0.03));
    Future<void>.delayed(const Duration(milliseconds: 900), () => FluentBar.find(_id)?.controller.updateProgress(const FluentBarProgressState.value(0.87)));
  }

  void _connect({required bool linear}) {
    final FluentBarEntry<void>? entry = FluentBar.showLoading<void>('Connecting...', linear: linear, id: 'connect_demo');
    Future<void>.delayed(DemoProgressRunner.resultPause, () => entry?.completeProgress(message: 'Connected', type: FluentBarType.success));
  }

  Future<void> _future({required bool fail}) async {
    try {
      final int files = await FluentBar.future<int>(
        Future<int>.delayed(const Duration(seconds: 2), () => fail ? throw StateError('Server returned 503') : 12),
        loading: 'Syncing your library...',
        title: 'Sync',
        id: 'future_demo',
        success: (int count) => '$count files are up to date',
        error: (Object error) => 'Sync failed: $error',
      );
      debugPrint('Synced $files files');
    } catch (error) {
      debugPrint('Caller still gets the error: $error');
    }
  }

  @override
  Widget build(BuildContext context) => DemoPage(
    title: 'Progress & futures',
    subtitle: 'A bar with unfinished progress never times out. Once the progress completes, fails or is cancelled, the usual countdown starts and the bar closes by itself.',
    bottomNavigationBar: DemoBottomBar(
      child: Row(
        children: <Widget>[
          Expanded(
            child: _isRunning
                ? DemoButton('Running - tap to stop', icon: Icons.stop_rounded, tone: DemoTone.success, onPressed: _halt)
                : DemoButton('Start the upload demo', icon: Icons.play_arrow_rounded, tone: DemoTone.primary, onPressed: _start),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: 'Start over when the progress completes',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Auto repeat', style: Theme.of(context).textTheme.labelMedium),
                Switch(value: _runner.loop, onChanged: (bool v) => _runner.loop = v),
              ],
            ),
          ),
        ],
      ),
    ),
    children: <Widget>[
      DemoSection(
        icon: Icons.tune_rounded,
        id: 'progress/look',
        description: 'Start the demo with the button at the bottom, then change these settings: the running bar follows them live.',
        code: _lookCode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DemoChoice<FluentBarProgressStyle>(label: 'Style', values: FluentBarProgressStyle.values, selected: _style, onChanged: (FluentBarProgressStyle v) => _setLook(() => _style = v)),
            const SizedBox(height: 12),
            DemoChoice<FluentBarProgressPosition>(
              label: 'Position',
              values: FluentBarProgressPosition.values,
              selected: _position,
              onChanged: (FluentBarProgressPosition v) => _setLook(() => _position = v),
            ),
            const SizedBox(height: 12),
            DemoChoice<FluentBarProgressTextEffect>(
              label: 'Text effect',
              values: FluentBarProgressTextEffect.values,
              selected: _effect,
              onChanged: (FluentBarProgressTextEffect v) => _setLook(() => _effect = v),
            ),
            const SizedBox(height: 8),
            DemoSwitch(label: 'Show text', hint: '"42%" or "12 / 20" next to the indicator', value: _showText, onChanged: (bool v) => _setLook(() => _showText = v)),
            DemoSwitch(
              label: 'Hide the success icon after 1.5 s',
              hint: 'successIconDuration: the indicator collapses, or the regular icon returns if it replaced the icon',
              value: _hideSuccess,
              onChanged: (bool v) => _setLook(() => _hideSuccess = v),
            ),
            DemoSwitch(label: 'Count items instead of percent', hint: 'FluentBarProgressState.fraction(current, total)', value: _fraction, onChanged: (bool v) => setState(() => _fraction = v)),
            const SizedBox(height: 8),
            DemoSlider(
              label: 'A jump across the whole scale takes',
              value: _jumpMs,
              min: 0,
              max: 2000,
              divisions: 20,
              format: (double v) => v == 0 ? 'no animation' : '${v.round()} ms',
              onChanged: (double v) => _setLook(() => _jumpMs = v),
            ),
            const DemoNote(
              'The indicator moves for as long as the jump is far: a small step takes about 300 ms, a jump across the whole scale takes the time set above, and everything in between is proportional. Big jumps also start softly. A value of 300 ms or less gives every jump the same duration.',
              icon: Icons.info_outline,
            ),
            const SizedBox(height: 8),
            DemoWrap(
              children: <Widget>[DemoButton('Try a big jump: 3% -> 87%', icon: Icons.fast_forward_rounded, onPressed: _bigJump)],
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.sync_alt_rounded,
        id: 'progress/update',
        description: 'All three give the same result and work for a bar on screen as well as for one still waiting in the queue.',
        code: switch (_way) {
          _Way.controller =>
            '''
// Through the controller
final entry = FluentBar.info('Uploading').withLinearProgress(value: 0).show();

entry?.controller.updateProgress($_stateCode);
entry?.controller.updateProgress(
  const FluentBarProgressState.value(1.0),
  completedMessage: 'All photos are in the cloud',
  completedType: FluentBarType.success,
);''',
          _Way.entry =>
            '''
// Through the bar itself
final entry = FluentBar.info('Uploading').withLinearProgress(value: 0).show();

${_fraction ? "entry?.updateFraction(12, 20);\nentry?.updateFraction(20, 20, completedMessage: 'All photos are in the cloud', completedType: FluentBarType.success);" : "entry?.updateValue(0.6);\nentry?.updateValue(1.0, completedMessage: 'All photos are in the cloud', completedType: FluentBarType.success);"}''',
          _Way.sameId =>
            '''
// By showing a bar with the same id again: only progress, texts and type change,
// the action, callbacks and look of the existing bar are kept.
FluentBar.info('Uploading').withId('upload').withProgress($_stateCode).show();
FluentBar.success('All photos are in the cloud').withId('upload').withProgress(const FluentBarProgressState.value(1.0)).show();''',
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DemoChoice<_Way>(
              label: 'The demo updates the bar',
              values: _Way.values,
              selected: _way,
              labelOf: (_Way way) => switch (way) {
                _Way.controller => '1. controller.updateProgress',
                _Way.entry => '2. entry.updateValue / updateFraction',
                _Way.sameId => '3. show() with the same id',
              },
              onChanged: (_Way v) => setState(() => _way = v),
            ),
            const SizedBox(height: 12),
            DemoChoice<DemoProgressMotion>(
              label: 'The value moves',
              values: DemoProgressMotion.values,
              selected: _runner.motion,
              labelOf: (DemoProgressMotion m) => m == DemoProgressMotion.smooth ? 'smoothly (1% at a time)' : 'in jumps (5-20% at a time)',
              onChanged: (DemoProgressMotion v) => _runner.motion = v,
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.flag_outlined,
        id: 'progress/finish',
        description: 'Start the upload demo, then end it with one of the outcomes. Each one fires its own callback and analytics event.',
        code: '''
entry.completeProgress(message: 'Uploaded', type: FluentBarType.success);
entry.failProgress(message: 'Upload failed');          // switches to the error type
entry.cancelProgress(fallbackMessage: 'Upload cancelled', fallbackType: FluentBarType.warning);
entry.cancelProgress(dismiss: true);                   // cancel and close at once

// Each outcome has its own callback:
FluentBar.loading('Uploading').copyWith(
  callbacks: FluentBarCallbacks(
    onProgressCompleted: (item) => analytics.log('upload_done'),
    onProgressFailed: (item) => analytics.log('upload_failed'),
    onProgressCanceled: (item) => analytics.log('upload_canceled'),
  ),
).show();''',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DemoWrap(
              children: <Widget>[
                DemoButton(
                  'Complete',
                  icon: Icons.check,
                  tone: DemoTone.success,
                  onPressed: () => _stop((FluentBarEntry<dynamic> e) => e.completeProgress(message: 'Uploaded', type: FluentBarType.success)),
                ),
                DemoButton(
                  'Fail',
                  icon: Icons.close,
                  tone: DemoTone.danger,
                  onPressed: () => _stop((FluentBarEntry<dynamic> e) => e.failProgress(message: 'Upload failed: no connection')),
                ),
                DemoButton(
                  'Cancel',
                  icon: Icons.block,
                  tone: DemoTone.warning,
                  onPressed: () => _stop((FluentBarEntry<dynamic> e) => e.cancelProgress(fallbackMessage: 'Upload cancelled', fallbackType: FluentBarType.warning)),
                ),
                DemoButton('Cancel & close', onPressed: () => _stop((FluentBarEntry<dynamic> e) => e.cancelProgress(dismiss: true))),
              ],
            ),
            const SizedBox(height: 8),
            DemoSwitch(
              label: 'Show a toast when a callback fires',
              hint: 'The demo bar always carries the three callbacks; this switch only makes them visible',
              value: _toastCallbacks,
              onChanged: (bool v) => setState(() => _toastCallbacks = v),
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.cancel_outlined,
        id: 'progress/cancel-button',
        description:
            'A ready-made Cancel button. On a tap the bar stops following the progress and the button shows a loader while your callback stops the task; then the progress is cancelled and the bar leaves by its usual timer. Let the download finish instead: the button goes away with the progress. The close button next to it only hides the bar.',
        code: '''
FluentBar.info('Downloading the map')
    .withLinearProgress(value: 0, showText: true)
    .withCancelButton(
      'Cancel',
      onCancel: () => download.cancel(),            // the button shows a loader meanwhile
      canceledMessage: 'Download cancelled',
      canceledType: FluentBarType.warning,
    )
    .withCloseButton()                              // optional: a cross that only hides the bar
    .show();

// Your own button can leave with the progress too:
const FluentBarActions<void>(label: 'Pause', removeWhenProgressEnds: true);''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton(
              'Download with Cancel',
              tone: DemoTone.primary,
              onPressed: () => DemoProgressRunner.playOn(
                FluentBar.info<void>('Downloading the map')
                    .withId('cancel_demo')
                    .withLinearProgress(value: 0, showText: true)
                    .withCancelButton(
                      'Cancel',
                      onCancel: () async {
                        DemoProgressRunner.stopOn('cancel_demo');
                        await Future<void>.delayed(const Duration(milliseconds: 1200));
                      },
                      canceledMessage: 'Download cancelled',
                      canceledType: FluentBarType.warning,
                    )
                    .show(),
                completedMessage: 'The map is ready',
              ),
            ),
            DemoButton(
              'With a close button too',
              onPressed: () => DemoProgressRunner.playOn(
                FluentBar.info<void>('Downloading the map')
                    .withId('cancel_demo')
                    .withLinearProgress(value: 0, showText: true)
                    .withCancelButton(
                      'Cancel',
                      onCancel: () async {
                        DemoProgressRunner.stopOn('cancel_demo');
                        await Future<void>.delayed(const Duration(milliseconds: 1200));
                      },
                      canceledMessage: 'Download cancelled',
                      canceledType: FluentBarType.warning,
                    )
                    .withCloseButton()
                    .show(),
                completedMessage: 'The map is ready',
              ),
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.replay_rounded,
        id: 'progress/retry',
        description:
            'Cancel, failure and Retry on one bar. The download breaks at 60%: the Cancel button gives way to Retry and the bar waits for an answer instead of closing. Retry starts the same function again, and the bar goes back to progress with Cancel. The second attempt goes through.',
        code: '''
void download() {
  final entry = FluentBar.info<void>('Downloading the map')
      .withId('map')
      .withLinearProgress(value: 0, showText: true)
      .withCancelButton('Cancel', onCancel: task.cancel, canceledMessage: 'Download cancelled')
      .show();

  task.start(
    onProgress: (received, total) => entry?.updateBytes(received, total),
    onDone: () => entry?.completeProgress(message: 'Map downloaded', type: FluentBarType.success),
    onError: () => entry?.failProgress(
      message: 'Download failed',
      type: FluentBarType.warning,      // an error by default
      retryLabel: 'Retry',
      onRetry: download,                // the same id: the bar starts over in place
      // isPersistent: false,          // let the failed bar leave by its timer
    ),
  );
}''',
        child: DemoWrap(
          children: <Widget>[DemoButton('Download that fails at 60%', tone: DemoTone.primary, onPressed: _downloadWithRetry)],
        ),
      ),
      DemoSection(
        icon: Icons.cloud_download_outlined,
        id: 'progress/bytes',
        description:
            'Downloads and uploads report (received, total) in bytes. updateBytes takes exactly that pair, so it can be passed as the progress callback of dio or fed from an http stream. The text picks its unit by itself, and a missing size (null, 0 or -1) turns the indicator indeterminate while still showing how much has arrived. Whether the indicator is endless is decided by the value you pass, not by a setting: the theme only chooses a line or a circle. Try "Size arrives later" to watch one bar go from endless to a normal progress.',
        code: '''
final entry = FluentBar.info('Downloading the offline map')
    .withLinearProgress(showText: true)
    .show();

// dio
await dio.download(url, path, onReceiveProgress: entry?.updateBytes);

// or by hand, for example from an http stream
entry?.updateBytes(received, response.contentLength);          // 3.1 / 48 MB
entry?.updateBytes(received, null);                            // 3.1 MB, indeterminate
entry?.updateBytes(received, total, label: FluentBarBytesLabel.percent);   // 6%''',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            DemoChoice<FluentBarBytesLabel>(
              label: 'Text when the size is known',
              values: FluentBarBytesLabel.values,
              selected: _bytesLabel,
              onChanged: (FluentBarBytesLabel value) => setState(() => _bytesLabel = value),
            ),
            const SizedBox(height: 12),
            DemoWrap(
              children: <Widget>[
                DemoButton('Download 48 MB', icon: Icons.download_rounded, tone: DemoTone.primary, onPressed: () => _download(knowsSize: true)),
                DemoButton('Download, size unknown', icon: Icons.help_outline_rounded, onPressed: () => _download(knowsSize: false)),
                DemoButton('Size arrives later', icon: Icons.sync_alt_rounded, onPressed: () => _download(knowsSize: true, sizeArrivesLater: true)),
                DemoButton('Size arrives later (circle)', icon: Icons.donut_large_rounded, onPressed: () => _download(knowsSize: true, sizeArrivesLater: true, circular: true)),
              ],
            ),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.hourglass_top_rounded,
        id: 'progress/future',
        description: 'Wraps any Future: shows a loading bar, then turns it into a success or an error. The same future is returned, so the result and the exception still reach your code.',
        code: '''
final int files = await FluentBar.future(
  api.sync(),
  loading: 'Syncing your library...',
  success: (int count) => '\$count files are up to date',
  error: (Object error) => 'Sync failed: \$error',
);''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton('Future that succeeds', icon: Icons.cloud_done_outlined, tone: DemoTone.success, onPressed: () => _future(fail: false)),
            DemoButton('Future that fails', icon: Icons.cloud_off_outlined, tone: DemoTone.danger, onPressed: () => _future(fail: true)),
          ],
        ),
      ),
      DemoSection(
        icon: Icons.format_paint_outlined,
        id: 'progress/label',
        description: 'FluentBarProgressTheme controls the indicator: color, thickness, text style and your own label.',
        code: '''
FluentBar.show(
  message: 'Rendering video',
  options: FluentBarOptions(
    progressState: const FluentBarProgressState.value(0),
    appearance: FluentBarAppearance(
      progressTheme: FluentBarProgressTheme(
        showText: true,
        thickness: 8,
        progressColor: Colors.pinkAccent,
        labelBuilder: (state) => 'Frame \${((state.progress ?? 0) * 240).round()} / 240',
      ),
    ),
  ),
);

// The track, the text and the success icon are yours too:
FluentBarProgressTheme(
  showText: true,
  textAlign: FluentBarProgressTextAlign.left,
  textEffect: FluentBarProgressTextEffect.pop,
  textEffectDuration: const Duration(milliseconds: 450),
  trackDecoration: BoxDecoration(border: Border.all(color: Colors.lightGreenAccent)),
  successIcon: const Icon(Icons.battery_charging_full_rounded),
)''',
        child: DemoWrap(
          children: <Widget>[
            DemoButton(
              'Own label',
              onPressed: () {
                final FluentBarEntry<void>? entry = FluentBar.show<void>(
                  message: 'Rendering video',
                  id: 'render_demo',
                  options: FluentBarOptions<void>(
                    progressState: const FluentBarProgressState.value(0),
                    appearance: FluentBarAppearance<void>(
                      progressTheme: FluentBarProgressTheme(
                        showText: true,
                        thickness: 8,
                        progressColor: Colors.pinkAccent,
                        textEffect: FluentBarProgressTextEffect.fade,
                        labelBuilder: (FluentBarProgressState state) => 'Frame ${((state.progress ?? 0) * 240).round()} / 240',
                      ),
                    ),
                  ),
                );
                DemoProgressRunner.playOn(entry, completedMessage: 'Video is ready');
              },
            ),
            DemoButton(
              'Own track & success icon',
              onPressed: () => DemoProgressRunner.playOn(
                FluentBar.show<void>(
                  message: 'Charging the battery',
                  id: 'charge_demo',
                  options: FluentBarOptions<void>(
                    progressState: const FluentBarProgressState.value(0),
                    appearance: FluentBarAppearance<void>(
                      progressTheme: FluentBarProgressTheme(
                        showText: true,
                        thickness: 10,
                        progressColor: Colors.lightGreenAccent,
                        textAlign: FluentBarProgressTextAlign.left,
                        textEffect: FluentBarProgressTextEffect.pop,
                        textEffectDuration: const Duration(milliseconds: 450),
                        trackDecoration: BoxDecoration(
                          border: Border.all(color: Colors.lightGreenAccent, width: 1.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        successIcon: const Icon(Icons.battery_charging_full_rounded, color: Colors.lightGreenAccent, size: 28),
                      ),
                    ),
                  ),
                ),
                completedMessage: 'Fully charged',
              ),
            ),
            DemoButton('Indeterminate (linear)', onPressed: () => _connect(linear: true)),
            DemoButton('Indeterminate (spinner)', onPressed: () => _connect(linear: false)),
          ],
        ),
      ),
    ],
  );
}
