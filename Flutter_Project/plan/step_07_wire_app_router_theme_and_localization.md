# Step 07 - Wire App Router, Theme, and Localization

## Mission

Convert the placeholder shell into a real application container by wiring the route table, app theme, localization pipeline, and shared top-level app composition. This step should make the app structurally navigable and language-aware without yet attempting to deliver the full settings experience or overlay interactions. It is the bridge between infrastructure-heavy work and the first real UI screens.

## Why This Step Exists

The architecture document is specific about the target route map, the move to a single `MaterialApp.router`, and the requirement to support multiple languages that correspond to the legacy app. The feature inventory also treats language selection as part of the preserved behavior, not a future enhancement. If pages get built before routing, theming, and localization are standardized, the project will quickly accumulate ad hoc navigation code, hardcoded strings, and style drift. This step creates the application shell that later pages can plug into without rethinking startup structure.

## Required Outputs

Create a real app container with the following elements:

- `MaterialApp.router` with the documented route map.
- A typed `go_router` setup for `/home`, `/usage`, `/overlay-preview`, `/onboarding/permissions`, and `/debug/contracts`.
- A coherent theme structure under `lib/app/theme`.
- Localization generation with ARB files and language resolution logic.
- A clean bridge between persisted language settings and the app locale.
- Basic smoke tests for router startup and locale switching.

## Exact Implementation Instructions

1. Under `lib/app/router`, create the central router definition using `go_router`. Keep route names and paths aligned with `TECH_ARCHITECTURE.md`. The main routes should include the settings home page, usage page, overlay preview page, Android permission onboarding page, and a debug contracts page reserved for development and verification. If some pages are not implemented yet, wire them to simple placeholders with correct titles instead of leaving the route missing.
2. Replace any temporary `MaterialApp` setup from step 01 with `MaterialApp.router`. This is the moment where the app shell becomes structurally correct. Keep the top-level widget clean: theme, locale, localizations delegates, router configuration, and little else.
3. Create the theme primitives in `lib/app/theme`. Use a simple but deliberate Material 3 setup rather than default chaos. Define color roles, spacing or radius tokens if helpful, and a text theme that can survive both settings screens and overlay calibration pages. The goal is stability and consistency, not visual polish obsession.
4. Add `flutter_localizations` and `intl` integration if not already done. Create the ARB files for at least the languages explicitly documented in the inventory: `SYSTEM`, Chinese, English, French, Spanish, Russian, and Arabic. The `SYSTEM` option is not a locale file; it is a settings choice that maps to the device locale at runtime. Build the localization generation structure so later pages can consume strongly typed strings.
5. Create a small locale-mapping utility that converts the persisted app-language enum into a `Locale?` or a concrete locale strategy. Make sure Arabic is treated as an RTL language and verify that the app does not crash when the stored language is unsupported by the current device. Fallback should always be safe and explicit.
6. Integrate the language state from `SettingsController` or a temporary app-level provider so the whole app can rebuild with a new locale when the setting changes later. Even if the settings page has not been built yet, the app shell should already be ready to consume that state.
7. Add minimal smoke tests or widget tests that prove the app starts on the expected initial route and that locale mapping works for at least English, Chinese, and Arabic. This is not the step for deep page tests, but it should still establish confidence that the shell can host the later UI.

## Important Constraints

- Do not fully implement the settings page in this step.
- Do not hardcode text in widgets when it belongs in localization resources.
- Do not hide locale or router state inside random helper singletons.
- Do not force platform-specific navigation into the app shell.

## Acceptance Criteria

This step is complete only when the app shell is structurally ready:

- `MaterialApp.router` is the canonical root.
- The documented route map exists, even if some pages still use placeholders.
- Localization is generated and ready for real page strings.
- Theme setup is centralized and reusable.
- The app can respond to stored language choice without redesigning the shell later.

## Handoff Notes for the Next AI

The next step will finally build the user-facing settings home page and usage guide using the controllers and shell prepared so far. That means the router names, localization keys, and theme primitives established here should be stable and obvious. Avoid last-minute "temporary" shortcuts in this step because the next screens will immediately depend on them.
