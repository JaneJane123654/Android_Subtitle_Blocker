# Step 04 - Implement Settings Persistence and Config Transfer

## Mission

Build the local persistence layer and the import/export workflow that preserve user settings and overlay layout across sessions. This step must convert the documented rules into infrastructure plus domain-friendly repository contracts. It must not build the visual settings page yet, but it should deliver everything the later UI and controllers need in order to load, save, import, and export configuration safely.

## Why This Step Exists

The legacy inventory makes persistence and config transfer first-class behavior, not optional convenience. The migration spec is especially strict here: defaults must survive, export must prefer the current runtime state over the last persisted state, invalid import must fail atomically, imported transparency must be reset to `false`, and imported visibility must preserve the current runtime visibility instead of trusting the JSON input. These are exactly the kinds of details that get lost if persistence is bolted onto a screen after the UI already exists. This step establishes the storage contract before any page starts depending on it.

## Required Outputs

Create an end-to-end persistence and config-transfer layer with the following pieces:

- Repository interfaces for settings and configuration transfer.
- Hive-backed data sources for persisted settings and last-known overlay layout.
- Serializable import/export payload models.
- Platform abstraction for clipboard and sharing side effects.
- Tests that prove invalid JSON, missing state, and priority order are handled correctly.

## Exact Implementation Instructions

1. Under `features/settings/domain` and `features/config_transfer/domain`, define the repository contracts. The settings repository should be able to load persisted settings, save settings, load the last overlay snapshot, and save the last overlay snapshot. The config-transfer repository or service should be able to export a payload string and import a payload string into merged domain state.
2. Under `features/settings/infrastructure`, add a Hive-backed implementation. Use `hive` and `hive_flutter` in the mainstream way. You may choose explicit Hive adapters or serialized JSON blobs, but whichever path you choose must remain maintainable and testable. If you use JSON blobs inside Hive, keep the serialization models typed and do not bury maps in random helper code.
3. Decide and document the box names and keys in a single place. Examples might include `settings_box`, `settings_key`, and `overlay_snapshot_key`. Keep them as constants, not string literals sprinkled through the data source.
4. Create dedicated import/export payload models under `features/config_transfer/domain` or `infrastructure`. The payload should be explicit, versionable, and JSON serializable. Include the fields needed to reconstruct user settings and overlay layout. Even if the app currently has only one payload version, include a top-level `schemaVersion` or equivalent marker so future migrations can reject incompatible formats cleanly.
5. Implement the export priority exactly as the migration spec describes: first try the current in-memory runtime state passed in by the caller, then fall back to the last persisted overlay snapshot, and if neither exists fail clearly. Never export partial or malformed JSON just to satisfy a user action.
6. Implement the import merge rules exactly. If JSON parsing fails, return a typed failure and do not write any data. If validation fails, also fail atomically. When import succeeds, force transparency to `false` and preserve current `visible` from the runtime state instead of trusting the imported visibility field. This rule must be visible in code and tests.
7. Add platform-side abstraction for clipboard read/write and share or copy behavior under `core/platform` or a closely related area. Do not call `Clipboard` or `Share` directly from repositories if you can avoid it. The repository should work with an injected port so later controller tests remain easy.
8. Add tests that cover settings round-trip persistence, export priority order, failure when no runtime or persisted state exists, invalid JSON import failure, successful import merge behavior, and preservation of current visibility. Make the tests readable enough that they double as migration documentation.

## Important Constraints

- Do not build UI buttons or snackbars here.
- Do not swallow JSON parsing exceptions and continue.
- Do not write direct clipboard or share calls inside controllers later if a port can be injected now.
- Do not store half-updated configuration after a failed import.

## Acceptance Criteria

This step is complete only when later layers can safely rely on persistence:

- Settings and overlay snapshots can be loaded and saved through repository contracts.
- Import and export follow the documented priority and merge rules exactly.
- Invalid input fails atomically with typed failures.
- The storage layout is explicit and centralized.
- Tests prove the correctness of both success and failure branches.

## Handoff Notes for the Next AI

The next data-oriented step will build remote update checking, and the later controller step will orchestrate both local and remote repositories together. That means the persistence layer created here must already feel stable and boring. If you are tempted to add presentation-specific formatting or toast messages in this step, stop. Everything here should read like infrastructure that can serve multiple interfaces, not just one screen.
