# Step 05 - Create the Update Checking Data Flow

## Mission

Implement the shared update-checking stack so the app can discover newer releases, compare versions correctly, respect ignored versions, and prepare downstream platform-specific update actions. This step must stop at the repository and service layer. It should not build a visible update card yet and it should not implement the Android installer or iOS launcher itself. Its job is to make update information reliable and testable before the controller or UI consumes it.

## Why This Step Exists

The legacy inventory includes both remote release discovery and platform-different update behavior. The migration spec also requires several nuanced branches: automatic and manual checks produce different user messaging, the ignored version must still participate in comparison, and Android must fall back to opening the release page if APK download fails. If the project jumps into a button-first implementation, those differences will end up scattered between controllers and widgets. This step centralizes update logic into a clean data flow so later steps only orchestrate and present it.

## Required Outputs

Build the shared update stack with the following pieces:

- Remote DTOs and a Retrofit or Dio data source for release lookup.
- Domain models that represent release metadata and update decisions.
- A repository that compares current app version against remote release data.
- Logic that respects ignored versions and distinguishes manual from automatic checks.
- Typed failures for network, parsing, empty asset, and external-launch preparation issues.
- Tests that prove release selection and ignore-version behavior.

## Exact Implementation Instructions

1. Under `features/updates/infrastructure`, create a remote data source backed by `Dio` and `Retrofit`. Use the latest-release endpoint strategy described in the legacy inventory. Keep the endpoint URL and repository identifiers configurable rather than burying them in source files. If the actual repository owner or release URL is still unknown at implementation time, create a typed configuration object with placeholder values and mark it as a required product configuration, instead of hardcoding guesses into business logic.
2. Create DTOs for remote release responses and map them into clean domain models such as `ReleaseInfo`, `ReleaseAsset`, and `UpdateAvailability`. Domain objects should hide API noise and expose only what the app needs: version label, release page URL, optional Android asset URL, published time if needed, and notes if the UI will later display them.
3. Inject the current installed app version through a platform-neutral port, for example `AppInfoPort`. The repository should not call platform APIs directly. It should ask the port for the current version string, normalize it through the comparator created in step 03, and decide whether the remote release is newer.
4. Implement the ignored-version logic carefully. If the ignored version equals the remote version, the repository should suppress update prompting. If a higher version than the ignored version appears later, the app must prompt again. The logic should be explicit and tested, not inferred indirectly by UI state.
5. Model the difference between manual and automatic checks at the domain or repository boundary. Later UI messaging depends on this. A clean way is to let the controller request `checkForUpdates(trigger: manual)` or `checkForUpdates(trigger: automatic)` and have the result carry a semantic status like `upToDateSilently`, `upToDateWithUserMessage`, `updateAvailable`, or `suppressedByIgnoredVersion`.
6. Prepare, but do not yet execute, platform-specific actions. The shared update layer may expose an action intent such as `openReleasePage`, `downloadAndroidPackage`, or `openIosStorePage`, but the actual adapter implementations belong to the platform step. Keep this layer focused on deciding what should happen, not on performing it.
7. Add tests for version comparison integration, ignored-version suppression, reminder restoration when a higher version appears, release asset selection for Android, behavior when no APK asset exists, and manual-versus-automatic result semantics.

## Important Constraints

- Do not build UI messaging strings into repository classes.
- Do not implement Android APK installation yet.
- Do not guess production repository identifiers if they are not present in docs; use configuration placeholders and surface the dependency clearly.
- Do not ignore malformed or missing version strings; return typed failures instead.

## Acceptance Criteria

This step is complete only when the update layer is coherent on its own:

- Remote release data can be fetched and mapped cleanly.
- Current version comparison uses the domain comparator from step 03.
- Ignored-version behavior matches the migration spec exactly.
- Manual and automatic checks are distinguishable in the returned semantics.
- Later controllers can consume the repository without embedding network or comparison logic.

## Handoff Notes for the Next AI

The next step will orchestrate local persistence, update checks, and overlay rules inside Riverpod controllers. That only works if this update layer already returns stable, typed outcomes. Avoid pushing complexity into "we can decide in the controller later." The controller should coordinate decisions, not invent them. If a rule is clearly about release evaluation, it belongs here now.
