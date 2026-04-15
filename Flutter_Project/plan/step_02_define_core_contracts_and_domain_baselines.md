# Step 02 - Define Core Contracts and Domain Baselines

## Mission

Build the shared, platform-agnostic foundation that every feature will depend on: business constants, domain enums, immutable baseline models, and the common failure/result contracts for external boundaries. This step must stay strictly in the shared domain and core layers. It must not implement repositories, controllers, routes, or UI pages. It should create the language the rest of the codebase will speak.

## Why This Step Exists

The migration documents are explicit that constants, null handling, and exception fallbacks are non-negotiable. They must be promoted into testable Dart code rather than buried in widgets or adapter logic. If the project starts building controllers or UI before these constants and contracts exist, later code will hardcode sizes, timings, or branch behavior and the migration will lose fidelity. This step protects the business boundaries by defining them once, clearly, and in a reusable way.

## Required Outputs

Produce a shared baseline that includes the following categories:

- A core failure type hierarchy or failure union used across storage, network, parsing, permission, and platform boundaries.
- A generic `Result<T>` or `Either<AppFailure, T>` contract, consistent with the migration spec.
- Canonical business constants for overlay defaults, ranges, durations, and settings defaults.
- Core enums and small value types that are referenced by multiple features.
- Immutable baseline domain models for settings and for the overlay session shape, but not yet the full constraint engine or controller behavior.
- Unit tests that lock the documented defaults in place.

## Exact Implementation Instructions

1. Create a core error contract under `lib/core/error`. The project documents permit either `Result<T>` or `Either<AppFailure, T>`. Pick one and keep it consistent for all external boundaries. The recommended mainstream choice is a lightweight sealed `Result<T>` with `success` and `failure` branches, because it keeps the syntax readable for AI-generated code and works cleanly with Riverpod controllers later.
2. Model failures explicitly. At minimum, cover storage read/write failures, JSON parse failures, clipboard failures, network failures, permission denials, unsupported platform behavior, and installer or external launcher failures. Do not use only strings. Preserve raw cause information when useful, but present typed failure categories first.
3. Promote every mandatory constant from `AI_DEVELOPMENT_SPEC.md` into a single obvious source of truth under `lib/core/contracts`. Include overlay default size `220 x 80`, minimum size `100 x 40`, snap threshold `15`, maximum scale of `80%` of screen size, move animation `150ms`, resize animation `200ms`, fade-out `300ms`, hide completion `320ms`, transparency auto-restore range `1..60`, fallback auto-restore value `5`, minimized dot range `10..200`, minimized dot default `40`, close button default `RIGHT_TOP`, default language `SYSTEM`, default sound `false`, default keep-alive `false`, default transparency toggle `true`, default auto-restore `false`, and default ignored version `null`.
4. Create the foundational enums and shared models that many later features will import. Suggested locations are `lib/shared/models` or the relevant domain folders. Expected examples include `CloseButtonPosition`, `AppLanguage`, `OverlayVisibilityMode`, `OverlayCommandType`, or other small cross-cutting value types. Keep names aligned with the architecture documents and the legacy feature inventory.
5. Create an immutable `Settings` model in `features/settings/domain`. It should represent the persisted user preferences and defaults, but it should not yet know anything about Hive, widgets, or controllers. Use Freezed if the generator setup from step 01 is available. Include fields for close button position, sound enabled, keep-alive enabled, transparency toggle enabled, transparency auto-restore enabled, transparency auto-restore seconds, minimized dot size, rotation behavior if preserved, ignored version, and app language.
6. Create the initial overlay state baseline in `features/overlay/domain`. This should not yet implement all geometry rules. It should define the state shape the app will carry: visible, transparent, minimized, size, position, and any fields required for import/export parity. Keep it immutable and serializable-friendly.
7. Add focused unit tests under `test/` that verify all default settings and constant values. The tests must serve as the executable version of the migration agreement. If a later AI changes a default accidentally, the test suite should catch it immediately.

## Important Constraints

- Do not implement overlay constraint math here. That belongs to the next step.
- Do not add persistence annotations unless they are harmless and obviously part of the baseline model strategy.
- Do not put fallback logic in widgets or controllers when it belongs in the model layer.
- Do not skip nullable branches such as ignored version or optional runtime snapshot fields.

## Acceptance Criteria

This step is complete only when the codebase has a stable shared vocabulary:

- Every mandatory business constant exists in one canonical place.
- A typed failure/result strategy exists and is ready for infrastructure work.
- `Settings` defaults are encoded in immutable Dart models, not scattered across UI.
- Baseline overlay state exists as shared domain data.
- Unit tests prove the defaults match the migration documents exactly.

## Handoff Notes for the Next AI

The next step should be able to implement pure domain logic such as overlay geometry constraints and version comparison without having to guess names, defaults, or fallback policies. If, during this step, you discover a missing constant or enum that is clearly implied by the docs, add it now. If you find yourself needing a repository or a controller, you have gone too far. Keep this step as the stable contract layer that future code will import.
