# Step 01 - Bootstrap the Real Flutter Shell and Repository Structure

## Mission

Turn the current minimal scaffold into a real Flutter application shell that is ready for iterative feature work. This step is not allowed to implement business logic, feature controllers, platform adapters, or polished screens. Its only purpose is to establish the engineering foundation that every later step depends on: correct package dependencies, code-generation setup, a stable directory structure, a thin bootstrap entry point, and a placeholder app shell that compiles without mixing business behavior into the startup layer.

## Why This Step Exists

The current repository only contains a tiny `pubspec.yaml` and a placeholder `lib/main.dart`. The architecture documents already prescribe a serious stack: Riverpod for state, Freezed and annotations for immutable models, Dio and Retrofit for remote data, Hive for local persistence, get_it and injectable for dependency injection, go_router for routing, intl for localization, and Pigeon for type-safe platform bridging. If later steps begin creating feature code before the project shell is stabilized, the codebase will drift, file placement will become inconsistent, and the future AI will waste time moving files around or rewriting imports. This step eliminates that risk.

## Required Outputs

Create or update the project so that the following foundation exists inside `Flutter_Project`:

- `pubspec.yaml` expanded with the architecture-approved runtime packages and dev packages.
- `analysis_options.yaml` with a strict but practical lint baseline.
- `l10n.yaml` prepared for the localization step.
- `build.yaml` only if it is genuinely needed to constrain generator output; otherwise omit it.
- A stable folder skeleton under `lib/app`, `lib/core`, `lib/features`, `lib/shared`, and `test`.
- A thin `lib/main.dart` that only handles Flutter bootstrap concerns.
- `lib/app/app.dart` or equivalent as the root widget entry.
- A temporary placeholder home screen that proves the shell works without embedding any real feature logic.

## Exact Implementation Instructions

1. Expand `pubspec.yaml` to include the libraries already mandated by the architecture documents. Use current stable versions that are mutually compatible at implementation time, but do not invent alternative stacks. The minimum expected set is `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator`, `freezed_annotation`, `json_annotation`, `dio`, `retrofit`, `hive`, `hive_flutter`, `get_it`, `injectable`, `go_router`, `intl`, `flutter_localizations`, `permission_handler`, `package_info_plus`, `url_launcher`, `share_plus`, `path_provider`, and `pigeon`. Dev dependencies should include `build_runner`, `freezed`, `json_serializable`, `retrofit_generator`, `injectable_generator`, `hive_generator`, `flutter_test`, and a lint package such as `flutter_lints`.
2. If `android/` and `ios/` are still missing because this folder was created without the full Flutter CLI, regenerate the platform shell from inside `Flutter_Project` only. The preferred command is `flutter create . --platforms=android,ios`. Before running it, preserve existing `docs/`, `lib/`, and `plan/` content. After generation, verify that no architecture documents were overwritten. If the Flutter SDK is unavailable in the execution environment, write the source files for this step anyway and clearly leave platform shell creation for the later adapter step.
3. Replace the current demo-style `lib/main.dart` with a thin bootstrap file. It should call `WidgetsFlutterBinding.ensureInitialized()`, optionally initialize Hive later through a future bootstrap hook, wrap the root app in `ProviderScope`, and delegate the actual widget tree to `AppRoot` or an equivalent widget in `lib/app/app.dart`.
4. Create the intended top-level directory skeleton even if many folders are still empty. At minimum, prepare `lib/app/router`, `lib/app/theme`, `lib/core/di`, `lib/core/error`, `lib/core/platform`, `lib/core/contracts`, `lib/core/logging`, `lib/features/settings`, `lib/features/overlay`, `lib/features/usage`, `lib/features/updates`, `lib/features/config_transfer`, `lib/features/onboarding`, and `lib/shared/widgets`, `lib/shared/models`, `lib/shared/utils`.
5. Add a temporary root widget that uses `MaterialApp` or `MaterialApp.router` only in the most skeletal way needed to compile. Do not create real routes yet if that would force unfinished dependencies. A simple placeholder home that announces "project shell ready" is enough as long as the structure points cleanly toward the later router step.
6. Add generator-friendly conventions now. If Freezed or JSON models will be introduced later, establish a predictable export style and file naming pattern such as `settings.dart`, `settings.freezed.dart`, and `settings.g.dart`. This step should not generate feature models yet, but it should leave the repository ready for that pattern.

## Important Constraints

- Do not write real feature logic here.
- Do not add fake platform business code just to satisfy imports.
- Do not mix dependency registration, routing, localization, and feature state into one startup file.
- Do not touch any legacy native code outside `Flutter_Project`.
- Do not hardcode package versions in documentation comments; keep version choices in `pubspec.yaml`.

## Acceptance Criteria

This step is complete only when the project has a stable shell that later steps can safely extend:

- The dependency list matches the mandated stack from the docs.
- The directory skeleton mirrors the target architecture.
- `main.dart` is slim and future-friendly.
- The app root compiles conceptually without feature logic leaking in.
- The repository is ready for generated code, tests, and future platform integration.

## Handoff Notes for the Next AI

When this step is finished, the next step must be able to focus entirely on shared constants, failure contracts, immutable domain baselines, and tests without needing to revisit bootstrapping decisions. If you feel tempted to also add domain models, controllers, or routes while doing this step, stop. Those belong to later plan files and must not be pulled forward, because the whole point of this workflow is single-step isolation and predictable handoff.
