import 'package:fluent_bar/src/internal.dart';

/// A marker for the payload type, used to compare the type arguments of two bars.
class _PayloadType<T> {
  const _PayloadType();
}

/// The description of a bar: its content, look, behavior and callbacks.
///
/// Immutable. Create one with a draft such as `FluentBar.info`, adjust it with the chain
/// methods and end with `show()`.
///
/// ```dart
/// final FluentBarItem<void> item = FluentBar.info<void>('Profile saved').withTitle('Done').atBottom();
/// item.show();
/// ```
class FluentBarItem<T> {
  /// A unique identifier generated for every bar; it survives [copyWith].
  final String uuid;

  /// The identifier set by the app, used to find, update, close and de-duplicate the bar.
  final String? id;

  /// What kind of bar this is: info, success, warning, error or a custom type.
  final FluentBarType type;

  /// The optional title above the message.
  final String? title;

  /// The text of the bar.
  final String message;

  /// How long the bar stays on screen; `null` takes the duration of the type or the config.
  final Duration? duration;

  /// Data that travels with the bar and comes back in `onTap` and in the action handler.
  final T? payload;

  /// Whether the bar stays until it is closed by the user or from code.
  final bool? isPersistent;

  /// Free-form data for analytics and for a custom duplicate rule.
  final Map<String, dynamic>? meta;

  /// The progress of the bar; `null` when it shows no progress.
  final FluentBarProgressState? progressState;

  /// Position, gestures, priority and other behavior.
  final FluentBarBehavior behavior;

  /// The action button, if any.
  final FluentBarActions<T>? actions;

  /// Theme, colors, icon, animations and other look.
  final FluentBarAppearance<T> appearance;

  /// Callbacks for the life of the bar.
  final FluentBarCallbacks<T>? callbacks;

  /// A label for logs and analytics: what kind of bar this is. Presets set it themselves
  /// (`snack`, `toast`, `banner`, `loading`); set your own with `withPreset`.
  /// Does not affect the look or the behavior of the bar.
  final String? preset;

  /// Labels that group bars: by screen, by feature, by anything. `FluentBar.closeTag` closes
  /// every bar with a tag, and `FluentBarOwner` does it when a part of the app goes away.
  /// A tag does not affect the look, the queue or the priority of the bar.
  final Set<String> tags;

  static int _uuidSeq = 0;

  static String _generateUuid() => '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${(_uuidSeq++).toRadixString(36)}';

  /// Creates a bar. Most code uses `FluentBar.info` and the other drafts instead.
  FluentBarItem({
    this.id,
    required this.type,
    this.title,
    this.duration,
    required this.message,
    this.payload,
    this.isPersistent,
    this.meta,
    this.progressState,
    FluentBarBehavior? behavior,
    this.actions,
    FluentBarAppearance<T>? appearance,
    this.callbacks,
    this.preset,
    Set<String>? tags,
  }) : uuid = _generateUuid(),
       tags = tags == null || tags.isEmpty ? const <String>{} : Set<String>.unmodifiable(tags),
       behavior = behavior ?? const FluentBarBehavior(),
       appearance = appearance ?? FluentBarAppearance<T>();

  FluentBarItem._withUuid({
    required this.uuid,
    required this.id,
    required this.type,
    required this.title,
    required this.duration,
    required this.message,
    required this.payload,
    required this.isPersistent,
    this.meta,
    this.progressState,
    required this.behavior,
    required this.actions,
    required this.appearance,
    required this.callbacks,
    this.preset,
    required this.tags,
  });

  /// A copy with the given fields replaced.
  ///
  /// One rule for every field: an omitted argument (or `null`) keeps the value, a `clear...`
  /// flag removes it.
  ///
  /// Passing `behavior`, `appearance` or `callbacks` replaces the whole object; the chain
  /// methods merge instead.
  ///
  /// ```dart
  /// item.copyWith(message: 'Updated', clearTitle: true, clearActions: true);
  /// ```
  FluentBarItem<T> copyWith({
    String? uuid,
    String? id,
    FluentBarType? type,
    String? title,
    Duration? duration,
    String? message,
    T? payload,
    bool? isPersistent,
    Map<String, dynamic>? meta,
    FluentBarProgressState? progressState,
    FluentBarBehavior? behavior,
    FluentBarActions<T>? actions,
    FluentBarAppearance<T>? appearance,
    FluentBarCallbacks<T>? callbacks,
    String? preset,
    Set<String>? tags,
    bool clearTitle = false,
    bool clearDuration = false,
    bool clearPayload = false,
    bool clearMeta = false,
    bool clearProgressState = false,
    bool clearActions = false,
  }) => FluentBarItem<T>._withUuid(
    uuid: uuid ?? this.uuid,
    id: id ?? this.id,
    type: type ?? this.type,
    title: clearTitle ? null : (title ?? this.title),
    duration: clearDuration ? null : (duration ?? this.duration),
    message: message ?? this.message,
    payload: clearPayload ? null : (payload ?? this.payload),
    isPersistent: isPersistent ?? this.isPersistent,
    meta: clearMeta ? null : (meta ?? this.meta),
    progressState: clearProgressState ? null : (progressState ?? this.progressState),
    behavior: behavior ?? this.behavior,
    actions: clearActions ? null : (actions ?? this.actions),
    appearance: appearance ?? this.appearance,
    callbacks: callbacks ?? this.callbacks,
    preset: preset ?? this.preset,
    tags: tags == null ? this.tags : (tags.isEmpty ? const <String>{} : Set<String>.unmodifiable(tags)),
  );

  /// Whether the payload type of this bar is exactly [S], not a subtype of it.
  ///
  /// A shown bar can be updated only by a bar with the same payload type: its controller and
  /// widget are typed with it, and the callbacks of a bar with a narrower type (`onTap`,
  /// `onPressed`, builders) cannot be read through them - that is a runtime error.
  /// `dynamic`, `void` and `Object?` count as one type: callbacks using them are interchangeable.
  @internal
  bool hasPayloadType<S>() => _PayloadType<T>() is _PayloadType<S> && _PayloadType<S>() is _PayloadType<T>;

  // Lifecycle callbacks are called through instance methods, not by reading `callbacks` from
  // outside: the manager works with `FluentBarItem<dynamic>`, and reading a typed callback
  // through such a reference fails a type check. Inside the instance `T` is the real one.

  /// Calls `onShow`.
  @internal
  void notifyShown() => callbacks?.onShow?.call(this);

  /// Calls `onDismiss` with [metrics].
  @internal
  void notifyDismissed(FluentBarMetrics metrics) => callbacks?.onDismiss?.call(this, metrics);

  /// Calls `onProgressCompleted`.
  @internal
  void notifyProgressCompleted() => callbacks?.onProgressCompleted?.call(this);

  /// Calls `onProgressCanceled`.
  @internal
  void notifyProgressCanceled() => callbacks?.onProgressCanceled?.call(this);

  /// Calls `onProgressFailed`.
  @internal
  void notifyProgressFailed() => callbacks?.onProgressFailed?.call(this);

  @override
  bool operator ==(Object other) => identical(this, other) || other is FluentBarItem && progressState == other.progressState && isSameIgnoringProgress(other);

  @override
  int get hashCode => Object.hash(id, type, title, message, duration, payload, isPersistent, _metaHash, progressState, behavior, actions, appearance, preset, Object.hashAllUnordered(tags));

  @override
  String toString() =>
      'FluentBarItem<$T>(id: $id, type: ${FluentBarType.guard(type).name}, title: $title, message: $message, duration: $duration, isPersistent: $isPersistent, progress: ${progressState?.progress}${preset == null ? '' : ', preset: $preset'}${tags.isEmpty ? '' : ', tags: $tags'})';

  int get _metaHash => meta == null ? 0 : Object.hashAllUnordered(meta!.entries.map((MapEntry<String, dynamic> e) => Object.hash(e.key, e.value)));
}
