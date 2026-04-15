# Step 03 - Build Overlay Constraints and Version Logic

## Mission

Implement the two most important pure-domain behavior engines from the legacy app: overlay geometry constraints and semantic version comparison. This step is intentionally limited to pure logic plus tests. No repositories, no controllers, no UI, and no platform adapters are allowed here. The output must be deterministic, test-heavy, and independent of Flutter widgets whenever possible.

## Why This Step Exists

The architecture and migration documents repeatedly say that domain logic must be extracted and validated before UI or platform work begins. The legacy app's credibility depends on preserving subtle behavior: safe-area positioning, minimum dimensions, maximum scaling, snap-to-edge behavior, visibility restoration rules, and tolerant version comparison that strips prefixes or qualifiers. These are exactly the kind of rules that get corrupted when AI jumps straight into interface code. This step protects the project by encoding those rules as pure functions with strong tests.

## Required Outputs

Create a pure-domain package for overlay layout rules and release version comparison:

- Screen bounds and safe-area value objects.
- Overlay geometry value objects if not already created in the previous step.
- A constraint engine that clamps size and position, enforces minimums, respects the `80%` max bound, and optionally snaps to edges when within threshold.
- A version comparator that can compare user-facing release names robustly.
- Unit tests that reproduce the documented edge cases and the known legacy defaults.

## Exact Implementation Instructions

1. Under `features/overlay/domain`, add the pure value objects required to reason about the overlay without any dependency on Flutter rendering. Typical examples include `ScreenBounds`, `SafeInsets`, `OverlayRect`, `OverlaySize`, and `OverlayPosition`. If some of these were already introduced in step 02, extend them rather than duplicating concepts.
2. Implement `OverlayConstraints` or an equivalently named policy class. It should expose pure methods that sanitize requested size and position based on screen bounds and the migration constants. The logic must preserve these rules: minimum size is `100 x 40`, default size is `220 x 80`, maximum width and height are each capped at `80%` of available screen dimensions, and edge snap threshold is `15dp`.
3. Encode the documented default position behavior: `x` starts centered and `y` starts at `max(safeTop, screenHeight * 0.65)`. Make sure that sanitized results remain inside the safe renderable area. If the requested position would place the overlay off-screen, clamp it deterministically rather than throwing.
4. Include behavior for minimized-dot sizing in the domain layer. Even if the minimized presentation is implemented later in widgets, the clamp range `10..200dp` belongs here because it is a business boundary, not a UI whim.
5. Decide how snapping should be represented. A good approach is to return a full sanitized geometry result instead of mutating fields in place. That result can tell the presentation layer exactly where the overlay should land after drag or resize.
6. Implement `VersionNameComparator` under `features/updates/domain`. The docs require support for stripping prefixes, ignoring qualifiers, and treating non-numeric fragments as zero rather than crashing. The implementation should compare normalized numeric segments in order and remain stable for values like `v1.2.3`, `1.2.3-beta`, and `release-2.0`.
7. Add domain-level tests that explicitly cover the documented constants and the expected odd inputs. For overlay logic, include tests for default position, safe-top clamping, width and height minimums, width and height maximums, edge snapping near left and right, and minimized dot clamp behavior. For version logic, include equal versions with different prefixes, qualifier stripping, different segment lengths, and malformed text.

## Important Constraints

- Keep this step platform-agnostic. No `BuildContext`, `MediaQuery`, `Widget`, or `MethodChannel` code belongs here.
- Do not wire this logic into controllers yet.
- Do not hide edge cases behind comments. Prove them with tests.
- Do not silently ignore malformed version names without a deterministic normalization rule.

## Acceptance Criteria

This step is complete only when domain logic is trustworthy on its own:

- Overlay constraint rules are pure and deterministic.
- All boundary constants from the spec are represented through code or tests.
- Version comparison no longer depends on UI or network layers.
- Unit tests cover both happy paths and malformed inputs.
- A future controller can call these policies without embedding geometry math inside Riverpod notifiers.

## Handoff Notes for the Next AI

The next infrastructure step should treat these domain policies as fixed contracts. Do not reopen the math from this step inside repositories or widgets. If a later UI gesture wants a different visual feel, the animation layer may adapt how it gets to the target rectangle, but the target rectangle itself should still come from the policies written here. This keeps the migration behavior traceable to the legacy implementation and makes regression testing practical.
