# Step 10 - Integrate Platform Ports, Pigeon, and Adapters

## Mission

Connect the shared Flutter application to Android and iOS platform capabilities through clean ports, Pigeon contracts, and thin native adapters. This step is where platform-specific code finally appears, but it must remain a translation layer only. Shared business rules must stay in Dart, and iOS limitations must be documented as explicit degradation rather than hidden omissions.

## Why This Step Exists

The architecture and migration specs are unusually clear about platform boundaries. Android keeps global overlay, permission navigation, foreground keep-alive, and APK install behavior. iOS does not support system-wide overlay over third-party apps, so it must expose only an in-app overlay host, relevant permissions, and App Store or TestFlight launching. The documents also ban hand-written weakly typed method-channel strings and require Pigeon for platform bridging. This step is therefore not optional plumbing. It is the enforcement point for the most important architectural separation in the project.

## Required Outputs

Create the platform integration layer with the following pieces:

- Shared Dart-side ports for overlay host, permissions, keep-alive, app info, sound, installer, and external launch actions
- Pigeon schema definitions and generated channel code
- Android adapter implementations for overlay host, permission navigation, keep-alive, and APK update install
- iOS adapter implementations for in-app overlay hosting, permission handling, and store-launch actions
- Contract tests or adapter-facing tests that verify the Dart side behaves predictably
- Documentation comments or a dedicated matrix that explicitly records iOS degradation

## Exact Implementation Instructions

1. Under `lib/core/platform`, define the abstract ports that the shared code depends on. Examples include `OverlayHostPort`, `PermissionPort`, `KeepAlivePort`, `UpdateInstallPort`, `ExternalLauncherPort`, `AppInfoPort`, and `SoundPlayerPort`. Keep these interfaces narrow and business-shaped. They should expose meaningful actions, not transport details.
2. Add the Pigeon definitions that bridge Flutter to Android and iOS. Group related calls cleanly instead of creating one giant API surface. For example, overlay host control, permission actions, and update installation may each deserve separate Pigeon APIs. Generate the Dart and native stubs from those definitions and commit the generated outputs that belong in the repository.
3. Implement Android adapters under the generated or platform-specific areas created by `flutter create`. The Android side must cover overlay permission entry, actual system overlay host control, optional foreground keep-alive service coordination, and APK install or release-page fallback. Keep business decisions in Dart: the native side should execute instructions, report capability or failure, and not decide product policy on its own.
4. Implement iOS adapters that intentionally stop at supported behaviors. That includes hosting the in-app overlay scene, handling any required permissions that still make sense, and launching the App Store or TestFlight destination for updates. Do not attempt unsupported global overlay behavior. Instead, make the lack of support explicit through capability responses or no-op with typed failures, depending on the chosen port design.
5. Wire the adapters into the dependency injection graph so controllers and repositories receive platform-neutral ports. The shared layers should not import native implementation details directly.
6. Add tests at the Dart boundary that verify adapter contracts. At minimum, confirm that unsupported iOS global overlay requests are surfaced as explicit degradation, Android keep-alive permission denial flows are handled, and installer fallback behavior can be triggered predictably.
7. If platform shell folders were still absent, create them now inside `Flutter_Project` only, preserving the existing Dart source tree and docs. Never edit legacy native code outside this folder. This step is allowed to modify `Flutter_Project/android` and `Flutter_Project/ios`, and no other platform project.

## Important Constraints

- Do not write raw string-based `MethodChannel` contracts if Pigeon can define them.
- Do not migrate business rules into Kotlin, Java, Swift, or Objective-C when Dart already owns them.
- Do not hide iOS capability loss. Make it explicit and documented.
- Do not let controllers import platform implementation classes directly.

## Acceptance Criteria

This step is complete only when the platform boundary is real and disciplined:

- Shared code depends only on abstract ports.
- Pigeon-generated contracts exist and are wired.
- Android and iOS adapters each implement only their supported behavior.
- iOS degradation is explicit and traceable.
- Adapter or contract tests prove the shared layer can rely on platform responses.

## Handoff Notes for the Next AI

The final step will be a regression and readiness pass across tests, traceability, and documentation. That means platform integration should already be architecturally settled when this step finishes. Resist the urge to "just move a little logic into native because it is easier." Shortcuts taken here are the fastest way to collapse the whole migration architecture.
