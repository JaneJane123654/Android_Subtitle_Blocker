# Step 08 - Deliver the Settings and Usage Experience

## Mission

Build the first real user-facing pages: the settings home page and the usage guide page. These pages must bind to the controllers from step 06, live within the router and localization shell from step 07, and expose the behaviors identified in the legacy feature inventory without leaking business logic into widgets. This is the first step where the app should begin to feel like the product instead of a technical scaffold.

## Why This Step Exists

The feature inventory says the settings home page is not a simple preference list. It is the operational center of the app: it contains settings, permission entry points, update checking, import/export triggers, and navigation to the usage guide. The usage guide itself must follow the selected application language. Building these pages too early would have forced guesswork around state, localization, and repositories. Building them now allows the implementation to stay clean: widgets bind to providers, command listeners react to one-shot effects, and the architecture remains intact.

## Required Outputs

Create the following user-facing pieces:

- `SettingsHomePage`
- `UsageGuidePage`
- Reusable settings section widgets and action tiles
- UI bindings for settings toggles, import/export actions, update check triggers, and navigation actions
- Widget tests for the key interactions that belong to shared Flutter UI

## Exact Implementation Instructions

1. Under `features/settings/presentation`, create `SettingsHomePage` as the main app route that corresponds to the legacy `MainActivity`. Organize the screen into clear sections instead of one giant build method. Recommended sections include overlay behavior, accessibility or permission actions, keep-alive and platform-specific actions, import/export actions, update actions, language selection, and a link to the usage guide.
2. Build reusable presentation widgets such as `SettingsSectionCard`, `SettingsToggleTile`, `SettingsActionTile`, `LanguageSelectorField`, or similar abstractions. The goal is not abstraction for its own sake, but to keep the page readable and consistent. Make the widgets lean and feed them already-processed state from Riverpod.
3. Bind all persisted settings to `SettingsController`. Toggling sound, keep-alive, transparency mode, auto-restore, or language must call controller methods rather than mutating local state in the widget. If the controller emits commands such as "open permission onboarding" or "show update feedback," consume them via `ref.listen` or the chosen command strategy.
4. Implement the import and export action entry points using the repositories and command flow already created. The UI is responsible only for gathering user intent, optionally showing progress, and rendering success or failure feedback. The business rules about export priority, invalid import, and state merge must still live below the widget layer.
5. Create `UsageGuidePage` under `features/usage/presentation`. It can start as a scrollable documentation-style screen, but it must already use localized strings and fit naturally within the route shell. Keep content structured so it can later grow without becoming an unreadable wall of text.
6. Reflect platform differences honestly in the UI. If a control only makes sense on Android, label it accordingly or hide/disable it through a clear rule. Do not pretend that iOS can provide a global system overlay. The architecture document requires explicit degradation, not silent omission.
7. Add widget tests that cover at least these shared behaviors: the settings page renders main sections, toggling a setting calls the expected controller path, the usage guide route opens correctly, localization-sensitive labels update, and import/export action buttons are present and connected to commands.

## Important Constraints

- Do not move business rules into click handlers.
- Do not directly call platform APIs from page widgets.
- Do not hide platform degradation behind vague wording.
- Do not over-design the page with temporary visual flourish that fights maintainability.

## Acceptance Criteria

This step is complete only when the product's core control surface exists:

- The settings home page covers the inventory-defined entry points.
- The usage guide page exists and is localized.
- UI interactions delegate to controllers and command listeners cleanly.
- Platform-specific limitations are communicated honestly.
- Widget tests prove the shared Flutter experience is wired correctly.

## Handoff Notes for the Next AI

The next step will focus on the overlay preview and in-app overlay experience, which is more gesture-heavy and visually dynamic. The settings and usage pages built here should therefore act as stable launch points, not as experimental containers. Keep the navigation and command hooks clean so the preview page can be added without reworking the home screen.
