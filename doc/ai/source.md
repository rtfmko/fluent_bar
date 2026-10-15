# Where things are

Version: 1.0.0. Read this to find a class in the source of the package, or a live example in the demo app to send the user to.
The rules in `AI_GUIDE.md` apply here too.

## Where things are in the source

| Path | Contents |
|---|---|
| `lib/fluent_bar.dart` | public exports |
| `lib/src/facade/` | `FluentBar` (static API), `FluentBarScope` |
| `lib/src/extensions/` | the chain (`FluentBarItemBuilder`) and entry shortcuts |
| `lib/src/models/` | `FluentBarItem`, `FluentBarConfig`, `FluentBarOptions`, `FluentBarMetrics`, enums, behavior / appearance / actions / callbacks, progress state and theme |
| `lib/src/interfaces/` | `FluentBarController`, `FluentBarTheme` (+ built-in themes), `FluentBarType` (+ built-in types), `FluentBarQueueStrategy` |
| `lib/src/strategies/` | queue strategies |
| `lib/src/manager/` | queue, lifecycle, overlay, relocation, analytics (internal) |
| `lib/src/widgets/` | the bar widgets, `FluentBarTopInset`, `FluentBarBottomInset`, `FluentBarCloseButton`, `FluentBarOwner` |
| `example/lib/screens/` | a runnable screen for every feature |

Where each topic is shown live. The example app is also online at https://rtfmko.github.io/fluent_bar/.
Every section has a code, shown in its header: `https://rtfmko.github.io/fluent_bar/#/<code>` opens
it directly, and the search field on the home screen finds sections by code, title or API name.
When you send the user there, give both the path and the code, for example
"Behavior & gestures → Actions (`behavior/actions`)". Read the screen file for a working example.

| Topic | Screen (file in `example/lib/screens/`) | Codes |
|---|---|---|
| One-liners, chain, presets, recipes, closing | Quick start (`basics_screen.dart`) | `start/setup`, `start/one-liners`, `start/presets`, `start/recipes`, `start/the-chain`, `start/payload-callbacks`, `start/closing` |
| Progress, Cancel button, fail and retry, bytes, `FluentBar.future`, indicator look | Progress & futures (`progress_screen.dart`) | `progress/look`, `progress/update`, `progress/finish`, `progress/cancel-button`, `progress/retry`, `progress/bytes`, `progress/future`, `progress/label` |
| Positions, insets, relocation, touch, close button, actions, screen readers, live control | Behavior & gestures (`behavior_screen.dart`) | `behavior/positions`, `behavior/insets`, `behavior/relocation`, `behavior/touch`, `behavior/close-button`, `behavior/actions`, `behavior/custom-action-swipe-inset`, `behavior/live-bar`, `behavior/screen-readers`, `behavior/entrance-haptics` |
| Strategies, priorities, forcing, duplicates, tags and `FluentBarOwner` | Queue & duplicates (`queue_screen.dart`) | `queue/settings`, `queue/fill`, `queue/jump`, `queue/duplicates`, `queue/clean-up`, `queue/tags` |
| One setting on three levels, where to put a setting | Overriding settings (`overrides_screen.dart`) | `overrides/who-wins`, `overrides/where` |
| Themes, light / dark, types, `typeOverrides` | Themes & types (`themes_screen.dart`) | `themes/theme`, `themes/tweak`, `themes/type`, `themes/type-overrides` |
| Every builder, standard parts, theme hooks | Builders (`builders_screen.dart`) | `builders/content-builder`, `builders/standard-parts`, `builders/position-builder`, `builders/transition-effect`, `builders/progress-label`, `builders/action-builder`, `builders/theme-hooks` |
| Every config default, applied live | Global config (`config_screen.dart`) | `config/code`, `config/placement`, `config/look`, `config/lifetime`, `config/gestures`, `config/queue`, `config/analytics-events`, `config/progress` |
| Lifecycle, metrics and raw analytics of each bar | Monitor (`monitor_screen.dart`) | `monitor/generator`, `monitor/queues`, `monitor/bars` |
| Event log, error handler, throwing user code | Analytics & safety (`diagnostics_screen.dart`) | `analytics/stream`, `analytics/errors` |
| A bar configured with switches + generated code | Playground (`playground_screen.dart`) | `playground/code`, `playground/content`, `playground/action`, `playground/lifetime`, `playground/look`, `playground/gestures`, `playground/queue`, `playground/progress`, `playground/runtime` |

API reference with every parameter: https://pub.dev/documentation/fluent_bar/latest/
