# Launch Edition Cross-Platform Project Implementation AI Memory

## 1. Highest Behavior Instruction

You are the implementation AI reading this memory file. Your only goal in the current round is to locate the first unchecked task marked `[ ]` in the task tracker below, open the referenced `plan/step_XX_*.md` file, and complete only the implementation scope defined by that single step file. Do not perform any part of later steps, do not "prepare ahead," and do not silently bundle multiple milestones into one response.

You must produce only the code and project changes required to satisfy that one step. After finishing the step, you must reprint this entire memory document inside a fenced Markdown code block and change only that completed task from `[ ]` to `[x]`. Preserve the wording and order of every other task exactly so the user can paste the updated memory into the next round without reconstructing state manually.

If the selected step becomes blocked by a truly missing product decision that cannot be derived from repository documents, ask the user one concise question and stop. Do not invent hidden assumptions for release repository identifiers, store destinations, or package IDs if the chosen step cannot proceed safely without them.

## 2. Global Business Summary

Project name: Subtitle Blocker Flutter Refactor.

Final goal: rebuild the legacy Android subtitle-blocking application as a Flutter-based cross-platform project inside `Flutter_Project/`, preserving the legacy business rules, constants, edge cases, and migration traceability while adapting unsupported platform capabilities honestly. Android must retain the system-level overlay path through platform adapters. iOS cannot support a system-wide overlay over third-party apps, so its product shape must be an in-app overlay, preview, or calibration mode built from the same shared Flutter domain and widget logic.

This is not a line-by-line Java-to-Dart translation. It is a clean rebuild based on shared domain rules, Riverpod application logic, Flutter presentation, and platform-specific ports and adapters.

## 3. Current Project Baseline

At the moment this memory file was created, the repository inside `Flutter_Project/` contains:

- Architecture and migration documents in `docs/`
- A minimal `pubspec.yaml`
- A minimal `lib/main.dart`
- No confirmed production feature implementation yet
- No guaranteed generated `android/` or `ios/` shell inside `Flutter_Project/` yet
- A complete `plan/` folder containing the implementation work orders for each step

The source authority for requirements is:

- `docs/TECH_ARCHITECTURE.md`
- `docs/AI_DEVELOPMENT_SPEC.md`
- `docs/LEGACY_FEATURE_INVENTORY.md`
- `README.md`

## 4. Global Development Conventions and Shared Variables

- Work only inside `Flutter_Project/`. Do not modify the legacy native project outside this folder.
- Architecture stack is fixed unless the user explicitly changes it: `flutter_riverpod`, `riverpod_annotation`, `freezed`, `json_serializable`, `dio`, `retrofit`, `hive`, `get_it`, `injectable`, `go_router`, `intl`, `flutter_localizations`, `permission_handler`, `package_info_plus`, `url_launcher`, `share_plus`, `path_provider`, and `pigeon`.
- Shared business logic must live in Dart domain or application layers. Platform-specific capabilities must live behind ports and adapters.
- Platform channels must use Pigeon. Do not introduce weak string-based method-channel contracts when a typed bridge is required.
- UI widgets must not contain hidden business rules, magic numbers, or direct platform exception handling.
- External boundaries should return a typed `Result<T>` or equivalent failure object. Do not let raw exceptions leak into widgets.
- Required default business constants must remain preserved and test-covered:
  - Default overlay size: `220 x 80`
  - Minimum overlay size: `100 x 40`
  - Default vertical position: `max(safeTop, screenHeight * 0.65)`
  - Maximum width and height: `80%` of screen dimensions
  - Snap threshold: `15dp`
  - Move animation: `150ms`
  - Resize animation: `200ms`
  - Fade-out animation: `300ms`
  - Hide completion delay: `320ms`
  - Transparency auto-restore range: `1..60`
  - Transparency auto-restore fallback: `5`
  - Minimized dot range: `10..200`
  - Minimized dot default: `40`
  - Default close button position: `RIGHT_TOP`
  - Default language: `SYSTEM`
  - Default sound enabled: `false`
  - Default keep-alive enabled: `false`
  - Default transparency toggle enabled: `true`
  - Default transparency auto-restore enabled: `false`
  - Default ignored version: `null`
- Required branch behavior that must remain visible in code and tests:
  - Missing overlay permission must emit a permission-navigation command instead of showing the overlay
  - Hide must fade first, then actually hide
  - Sound plays before hide only when enabled
  - Transparency toggle must obey the master switch
  - Disabling transparency while already transparent must revert immediately and cancel restore timers
  - Auto-restore must schedule on transparent entry and cancel on opaque return
  - Android keep-alive must respect notification permission on Android 13+
  - Export must prefer current runtime state, then persisted state, and fail clearly otherwise
  - Import must fail atomically on invalid JSON
  - Import must force transparency to `false`
  - Import must preserve current runtime visibility instead of imported visibility
  - Manual and automatic update checks must not present identical outcomes
  - Ignored version logic must re-alert only when a higher version appears
  - Android APK download failure must fall back to the release page
- Route targets mandated by architecture:
  - `/home`
  - `/usage`
  - `/overlay-preview`
  - `/onboarding/permissions`
  - `/debug/contracts`
- Legacy-to-Flutter feature mapping must remain traceable to `LEGACY_FEATURE_INVENTORY.md`.
- If a step depends on unresolved product configuration such as GitHub release repository identifiers, App Store URL, TestFlight destination, Android application ID, or iOS bundle ID, ask the user only when that exact step becomes blocked. Do not derail unrelated steps.

## 5. Single-Step Task Tracker

- [x] Step 01: Bootstrap the real Flutter shell and repository structure. Target file: `plan/step_01_bootstrap_flutter_shell.md`. Detailed logic: expand the project scaffold into a real Flutter shell with approved dependencies, generator setup, folder structure, bootstrap entry point, and a placeholder app root, while still avoiding feature logic.
  Special mapping note: `MainActivity` and `UsageActivity` were translated only into the shared Flutter shell boundary and placeholder entry-page mapping in this step, with real routed feature pages intentionally deferred. Flutter/Dart tooling is unavailable in this workspace, so `flutter create . --platforms=android,ios` could not be executed and the platform shell remains a documented follow-up once the SDK is installed.
- [ ] Step 02: Define core contracts and domain baselines. Target file: `plan/step_02_define_core_contracts_and_domain_baselines.md`. Detailed logic: create the typed failure and result contract, promote all mandatory business constants, add shared enums and immutable baseline models, and lock the defaults with unit tests.
- [ ] Step 03: Build overlay constraints and version logic. Target file: `plan/step_03_build_overlay_constraints_and_version_logic.md`. Detailed logic: implement pure-domain geometry policies, safe-area and size clamping, snap behavior, minimized-dot boundaries, semantic version comparison, and domain tests for malformed inputs and edge cases.
- [ ] Step 04: Implement settings persistence and config transfer. Target file: `plan/step_04_implement_settings_persistence_and_config_transfer.md`. Detailed logic: add Hive-backed persistence, repository contracts, import/export payloads, clipboard and share ports, atomic import failure behavior, export priority handling, and tests for merge rules.
- [ ] Step 05: Create the update checking data flow. Target file: `plan/step_05_create_update_checking_data_flow.md`. Detailed logic: build the remote release client, DTO mapping, current-version comparison, ignored-version handling, manual versus automatic semantics, and tests that preserve the legacy update behavior.
- [ ] Step 06: Build application controllers and command flow. Target file: `plan/step_06_build_application_controllers_and_command_flow.md`. Detailed logic: create Riverpod controllers for settings, overlay, and updates, emit typed one-shot commands, preserve hide and transparency timing rules, and cover mandatory behavior with controller tests.
- [ ] Step 07: Wire app router, theme, and localization. Target file: `plan/step_07_wire_app_router_theme_and_localization.md`. Detailed logic: replace the placeholder shell with `MaterialApp.router`, add the mandated route map, create a stable theme layer, generate localization resources, and bind stored language selection into app-level locale handling.
- [ ] Step 08: Deliver the settings and usage experience. Target file: `plan/step_08_deliver_settings_and_usage_experience.md`. Detailed logic: build the settings home page and usage guide page, connect UI actions to controllers, expose import/export and update entry points, communicate platform limitations honestly, and add widget tests.
- [ ] Step 09: Build the overlay preview and in-app overlay mode. Target file: `plan/step_09_build_overlay_preview_and_in_app_overlay_mode.md`. Detailed logic: implement the shared overlay widget tree, gesture system, minimized state, transparency interactions, animation-driven hide and restore consumption, and widget tests for drag, snap, resize, and minimize behavior.
- [ ] Step 10: Integrate platform ports, Pigeon, and adapters. Target file: `plan/step_10_integrate_platform_ports_pigeon_and_adapters.md`. Detailed logic: define shared ports, generate Pigeon channels, implement Android overlay and keep-alive adapters, implement iOS in-app and store-launch adapters, and document explicit iOS degradation.
- [ ] Step 11: Run regression, traceability, and release readiness. Target file: `plan/step_11_run_regression_traceability_and_release_readiness.md`. Detailed logic: complete the test sweep, build traceability and platform-difference documentation, verify branch coverage against the migration spec, finish the debug contracts page, and leave the repository maintainable.

## 6. Completion Rule

At the end of every round, print this full memory document in a fenced Markdown code block with the newly completed step changed from `[ ]` to `[x]`. Do not summarize the memory file. Do not omit sections. Do not reorder tasks. The user will use the updated memory document plus the fixed prompt "Please read the project implementation progress AI memory document and complete only the next step" to trigger the next round.
