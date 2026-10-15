part of '../fluent_bar_progress_state.dart';

/// Progress of a download or an upload, counted in bytes.
///
/// Made for the `(received, total)` pairs that network libraries report. An unknown size
/// ([total] is `null`, zero or negative, as when the server sends no `Content-Length`) gives an
/// indeterminate indicator that still shows how much has arrived.
///
/// ```dart
/// const FluentBarProgressState.bytes(3250586, 52428800); // 3.1 / 50 MB
/// const FluentBarProgressState.bytes(3250586, null); // 3.1 MB, indeterminate
/// ```
class FluentBarProgressBytes extends FluentBarProgressState {
  /// How many bytes have been transferred.
  final int received;

  /// The size as it was reported; may be `null`, zero or negative when it is unknown.
  final int? total;

  /// What the text shows when the size is known.
  final FluentBarBytesLabel label;

  /// Creates a progress of [received] bytes out of [total].
  const FluentBarProgressBytes(this.received, this.total, {this.label = FluentBarBytesLabel.amount});

  /// Whether the total size is known.
  bool get hasTotal => total != null && total! > 0;

  @override
  double? get progress => hasTotal ? (received / total!).clamp(0.0, 1.0).toDouble() : null;

  @override
  bool get isCompleted => hasTotal && received >= total!;

  /// The text of this state: `3.1 / 50 MB`, or `3.1 MB` when the size is unknown.
  String get text {
    final int done = received < 0 ? 0 : received;
    if (!hasTotal) return formatBytes(done);

    final int size = total!;
    final int shown = done > size ? size : done;
    final String percent = '${(shown / size * 100 + 1e-9).floor()}%';
    final String amount = '${formatBytes(shown, unitOf: size, withUnit: false)} / ${formatBytes(size)}';

    return switch (label) {
      FluentBarBytesLabel.amount => amount,
      FluentBarBytesLabel.percent => percent,
      FluentBarBytesLabel.both => '$amount · $percent',
    };
  }

  static const List<String> _units = <String>['B', 'KB', 'MB', 'GB', 'TB'];

  /// Formats a number of bytes with a binary unit: `1536` gives `1.5 KB`.
  ///
  /// [unitOf] picks the unit from another number, so that two values can share it;
  /// [withUnit] set to `false` returns the number alone.
  static String formatBytes(int bytes, {int? unitOf, bool withUnit = true}) {
    int unit = 0;
    for (double scale = (unitOf ?? bytes).toDouble(); scale >= 1024 && unit < _units.length - 1; scale /= 1024) {
      unit++;
    }

    double value = bytes.toDouble();
    for (int i = 0; i < unit; i++) {
      value /= 1024;
    }

    // One decimal while the number is short enough to need it, none for whole bytes.
    String number = unit == 0 || value >= 100 ? value.round().toString() : value.toStringAsFixed(1);
    if (number.endsWith('.0')) number = number.substring(0, number.length - 2);

    return withUnit ? '$number ${_units[unit]}' : number;
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is FluentBarProgressBytes && received == other.received && total == other.total && label == other.label;

  @override
  int get hashCode => Object.hash(FluentBarProgressBytes, received, total, label);
}
