# Step 11 - Run Regression, Traceability, and Release Readiness

## Mission

Perform the final integration pass that proves the Flutter rebuild is internally coherent, traceable back to the legacy inventory, explicit about platform differences, and ready for continued maintenance. This step is not about inventing new features. It is about verifying that every previous step has landed cleanly and that the repository now contains enough tests, documentation, and traceability for future AI or human contributors to keep moving without re-discovering architectural intent.

## Why This Step Exists

The migration documents do not define success as "the app looks mostly finished." They define success through traceability, lossless migration discipline, explicit platform degradation, branch coverage, and preserved constants. Without a dedicated readiness pass, even a feature-complete codebase can remain fragile: tests may not cover critical branches, platform differences may be hidden in code instead of documented, and the link between legacy entries and Flutter modules may be lost. This final step turns the project from "a collection of implemented files" into "a maintainable migration product."

## Required Outputs

Produce a final verification and documentation pass that includes:

- A test sweep across unit, controller, widget, and adapter or integration layers
- Updated traceability artifacts tying Flutter modules back to `LEGACY_FEATURE_INVENTORY.md`
- Documentation of platform degradation and intentional differences
- A debug contracts page or equivalent verification surface if it was routed earlier
- Cleanup of any placeholder notes that should now become real implementation comments or docs

## Exact Implementation Instructions

1. Run or complete the full test pyramid expected by the migration spec. That includes domain tests, controller tests, widget tests, and adapter or integration tests. If some tests were stubbed earlier, finish them now. The purpose is not to maximize test count; it is to ensure every business constant and important branch is protected somewhere in the suite.
2. Create or update a traceability document inside `Flutter_Project/docs` that maps each inventory item to the corresponding Flutter module, controller, page, repository, or adapter. The file can be named something like `TRACEABILITY_MATRIX.md` if no equivalent exists yet. This document should help the next maintainer answer, "Where did legacy feature X go in Flutter?" without opening ten files.
3. Create or update a platform-differences document that explicitly records iOS degradation for system-wide overlay, foreground keep-alive, and APK installation. If a control is Android-only or an iOS flow is in-app only, write that down. The architecture docs already say silent deletion is forbidden, so this step must turn that rule into visible repository documentation.
4. Implement the `/debug/contracts` page promised by the route map if it still does not exist. It does not need production polish. Its purpose is to make important state and behavior visible for manual verification: current settings defaults, overlay geometry values, platform capability flags, and perhaps the last emitted command types. Keep it development-only or guarded if appropriate.
5. Review the repository for leftover temporary markers from earlier steps. Resolve anything that should now be concrete, such as placeholder route stubs, fake labels, or unfinished provider wiring. Leave real configuration placeholders only where the product genuinely lacks a documented value, such as repository identifiers or store URLs that were never provided.
6. Confirm that every non-negotiable branch from `AI_DEVELOPMENT_SPEC.md` is either covered by tests or visibly documented as platform-specific behavior. This includes permission failure, hide fade timing, transparency toggle rules, keep-alive fallback, import atomicity, ignored-version logic, and Android update fallback.
7. Update any remaining README or project-level guidance inside `Flutter_Project` so a future AI can bootstrap, test, and extend the codebase without hunting through historical context. Keep the guidance concise and factual.

## Important Constraints

- Do not add new product scope in this step.
- Do not weaken tests just to get green results.
- Do not leave platform differences implicit.
- Do not close the migration with undocumented TODOs that hide missing behavior.

## Acceptance Criteria

This step is complete only when the repository demonstrates readiness rather than hope:

- The test suite covers the promised migration behavior.
- Traceability back to the legacy inventory is explicit.
- Platform degradation is documented and honest.
- Debug verification tooling exists where promised.
- Future contributors can understand what was migrated, what differs by platform, and what remains configurable.

## Handoff Notes for the Next AI

After this step, the project should no longer need a migration bootstrap mindset. It should behave like a normal, maintainable Flutter product with clear architecture and preserved history. If something still feels ambiguous at the end of this step, do not hide it in silence. Document it plainly so the workflow remains lossless even after the initial implementation sequence is complete.
