# Accessibility

[Back to the README](https://github.com/rtfmko/fluent_bar/blob/v1.0.0/README.md)

## Accessibility

**Screen readers.** A bar is a live region: TalkBack and VoiceOver read it out when it appears and
when its title or message changes, without moving the focus away from what the user was reading.
The reader's dismiss gesture closes a bar that can be swiped or tapped away; analytics get the
dismiss reason `accessibility` (a part of `isByUser`).

| Mode | For the screen reader the bar is |
|---|---|
| `announce` (default) | read out by itself, and readable |
| `quiet` | readable when the user moves to it, never read out by itself |
| `hidden` | not there at all |

```dart
FluentBar.toast<void>('Copied').withSemantics(FluentBarSemantics.quiet).show();

FluentBar.patchConfig((config) => config.copyWith(defaultSemantics: FluentBarSemantics.quiet));
```

Like any setting it lives on the bar, on a type (`semantics`) or in the config. Use `quiet` for
bars that repeat what the screen already says, and think twice about `hidden`: a blind user will
not know that the bar exists.

**Progress is not read out on every step.** The percent has its own place in the reader's order,
so the user can move to it and hear `42%`, but an upload does not talk all the way through. The
result is announced when you give the bar a new message: `completeProgress(message: 'Uploaded')`.
`FluentBarProgressTheme(announceUpdates: true)` reads out every update.

**Motion.** With the system "reduce motion" setting bars fade instead of sliding
(see [Global config](settings.md#global-config)).

> **Demo:** [Behavior & gestures → Screen readers](https://rtfmko.github.io/fluent_bar/#/behavior/screen-readers) (`behavior/screen-readers`) · [Global config → Gestures](https://rtfmko.github.io/fluent_bar/#/config/gestures) (`config/gestures`) · [Global config → Progress indicator](https://rtfmko.github.io/fluent_bar/#/config/progress) (`config/progress`)<br>
> **API:** [`FluentBarSemantics`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarSemantics.html) · [`FluentBarProgressTheme`](https://pub.dev/documentation/fluent_bar/latest/fluent_bar/FluentBarProgressTheme-class.html)

