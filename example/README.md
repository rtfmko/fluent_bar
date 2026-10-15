# fluent_bar example

A showcase app for the `fluent_bar` package. Every screen covers one topic and shows the code behind each button.

| Screen | Code | What it shows |
|---|---|---|
| Quick start | `start` | One-liners (`showSuccess`, `showError`...), presets (`snack`, `toast`, `banner`, `loading`), recipes, the `.with...()` chain, typed payload, closing bars |
| Progress & futures | `progress` | Linear / circular progress, text effects, three ways to update, complete / fail / cancel, a Cancel button, fail and retry, downloads in bytes, `FluentBar.future` |
| Behavior & gestures | `behavior` | Positions, `FluentBarTopInset` / `FluentBarBottomInset`, live relocation, pause on touch, the close button, actions with loaders, screen readers, controlling a live bar, attention effects |
| Queue & duplicates | `queue` | Queue strategies (incl. a custom one), priorities, forcing, duplicate policies, tags and `FluentBarOwner`, live view of both queues |
| Overriding settings | `overrides` | "Who wins?": one setting on three levels (the bar, its type, the config) with the winner highlighted, and where to put a setting |
| Themes & types | `themes` | A live preview bar: built-in themes, light / dark mode, `theme.copyWith`, custom `FluentBarType`, global `typeOverrides` |
| Builders | `builders` | Your own widget in place of a part of the bar: content, standard parts, position, transition, effect, progress, label, action, theme hooks |
| Global config | `config` | Every app-wide default in one place, applied live, with the config shown as code |
| Monitor | `monitor` | Traffic generator, queue stats and the story of every bar: lifecycle, metrics and all analytics events (summary and raw data) |
| Analytics & safety | `analytics` | Filterable event log, error handler, and what happens when user code throws |
| Playground | `playground` | Configure a bar with switches, watch it change live and copy the generated code |

## Finding things

- **Search** on the home screen looks through section titles, codes and the API names each section
  uses: type `duplicate`, `withAction` or `clearQueue`.
- **Codes.** Every section has one, shown in its header: `queue/duplicates`. Tap it to copy.
- **Links.** On the web a code is an address: `<demo url>/#/queue/duplicates` opens the demo
  scrolled to that section. The package documentation links to sections this way.

## Structure

- `lib/main.dart` - app setup: `FluentBarScope.builder()` in `MaterialApp.builder`.
- `lib/app/app_state.dart` - app theme and the base `FluentBarConfig`.
- `lib/app/demo_index.dart` - the list of screens and sections with their codes; search and routes are built on it.
- `lib/app/telemetry.dart` - collects analytics, errors and the lifecycle of every bar from app start.
- `lib/widgets/demo_kit.dart` - the shared building blocks every screen is made of (incl. the live-bar control).
- `lib/widgets/telemetry_views.dart` - event log, queue lanes and the bar details sheet.
- `lib/screens/` - one file per screen.
- `lib/custom/` - custom theme, type, builders and queue strategy used by the demos.
- `test/demo_test.dart` - checks that every screen builds, that the index matches the screens, and the "Who wins?" logic.

## Run

```bash
flutter run
```
