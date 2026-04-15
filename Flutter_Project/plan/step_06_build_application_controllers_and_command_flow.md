# Step 06 - Build Application Controllers and Command Flow

## Mission

Create the Riverpod application layer that coordinates shared domain logic, local persistence, remote update checking, and one-shot side effects. This step must build the controllers and their tests, but it must not yet build the full visual pages. The goal is to make behavior executable and testable before presentation concerns arrive.

## Why This Step Exists

The migration documents draw a hard line between domain rules, infrastructure, and UI. They also describe several one-shot effects: navigate to permission settings when overlay permission is missing, play a tone before hide if sound is enabled, trigger a fade-out before actual hide, launch delayed transparency restore, revert keep-alive if Android notification permission is denied, and differentiate manual and automatic update feedback. Those behaviors should not be improvised inside widgets. This step centralizes them in Riverpod notifiers so the interface can stay declarative.

## Required Outputs

Build the controller layer with the following pieces:

- `SettingsController`
- `OverlaySessionController`
- `UpdateController`
- A clean strategy for one-shot commands or effects
- Provider definitions and dependency injection wiring at the application boundary
- Controller tests for the mandatory branch behavior from the migration spec

## Exact Implementation Instructions

1. Under `features/settings/application`, create `SettingsController` backed by the repository from step 04. It should load persisted settings, expose immutable state, update individual settings fields, and persist changes through the repository. It must not know about widget layout or route names.
2. Under `features/overlay/application`, create `OverlaySessionController`. This is one of the most important classes in the project. It should coordinate overlay visibility, transparency, minimized state, size, position, hide flow, drag and resize updates, and delayed transparency restoration. It must call the pure constraint logic from step 03 instead of reimplementing geometry math inline.
3. Implement the hide contract exactly. `onRequestHide()` and close-button actions must first emit a fade-out command, then after the documented delay mark the overlay truly hidden. If sound is enabled, emit a play-sound command before the final hide completes. Use injected timers or a schedulable clock abstraction where practical so tests can control time without sleeping.
4. Implement the transparent-mode rules exactly. If the master transparency toggle is disabled, tapping the overlay must not change transparency. If the overlay is already transparent and the master toggle gets disabled, transparency must immediately revert to false and any auto-restore timer must be cancelled. If auto-restore is enabled, switching into transparent mode must schedule a delayed restore. Switching back to opaque must cancel the pending restore command.
5. Under `features/updates/application`, create `UpdateController`. It should ask the repository from step 05 for update availability, persist ignored versions through the settings repository or a dedicated store, and emit user-facing command intents such as "show up-to-date message," "show update dialog," or "launch release action" without directly rendering anything.
6. Choose and implement one consistent one-shot command strategy. The migration docs allow either a command field in state or a separate command stream. A dedicated command stream or event provider is usually cleaner here because navigation, sound, installer launch, and fade requests are transient. Whichever strategy you choose, keep it typed and testable, and document the pattern in code comments for future AI contributors.
7. Add controller tests that cover the mandatory branches from `AI_DEVELOPMENT_SPEC.md`: permission-insufficient command emission, hide flow with fade timing, transparent toggle restrictions, auto-restore scheduling and cancellation, config import merge behavior, ignored-version comparisons, and keep-alive permission fallback behavior for Android-oriented settings.

## Important Constraints

- Do not perform widget navigation directly from controllers; emit commands and let the UI consume them.
- Do not perform raw `try/catch` in widgets later for work that belongs in controllers or repositories.
- Do not bypass the domain constraint engine when updating overlay geometry.
- Do not use singletons hidden inside controllers. Depend on providers and injected ports.

## Acceptance Criteria

This step is complete only when behavior exists independently of the UI:

- Controllers expose coherent immutable state.
- One-shot effects are typed and consumable through a predictable pattern.
- Overlay hide, transparency, import, and update rules match the migration spec.
- Tests cover both happy paths and important branch behavior.
- The later UI step can mostly bind to providers and listen for commands instead of inventing business logic.

## Handoff Notes for the Next AI

The next app-shell step will wire routing, theming, and localization. After that, real pages will bind to these controllers. That means the provider API you create here should feel stable, readable, and unsurprising. If you find yourself putting formatting strings, route pushes, or widget-specific booleans into controller state, pull back. The controller layer should express business intent, not presentation noise.
