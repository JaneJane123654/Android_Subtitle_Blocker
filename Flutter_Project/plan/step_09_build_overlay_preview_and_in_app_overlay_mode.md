# Step 09 - Build the Overlay Preview and In-App Overlay Mode

## Mission

Implement the shared overlay presentation layer: the preview or calibration page, the overlay canvas, the gesture system, minimized-dot behavior, transparency behavior, and the in-app overlay mode that both Android preview flows and iOS product flows can share. This step is where the most product-specific Flutter UI work happens, and it must faithfully consume the domain rules and controller contracts created earlier.

## Why This Step Exists

The central product behavior is the subtitle-blocking overlay. Even though iOS cannot provide a system-wide overlay over third-party apps, both platforms still share the underlying overlay geometry, preview editing, and in-app visual representation. The architecture docs explicitly say that Android and iOS should share the widget tree while platform differences stay in adapters and hosts. This step turns that architectural promise into code. If it is delayed until after platform adapters, too much logic will leak into native layers. If it is built earlier, it would lack the tested domain rules and controllers it depends on.

## Required Outputs

Create the full shared overlay presentation feature with the following pieces:

- `OverlayPreviewPage`
- Shared overlay widgets such as `OverlayCanvas`, `OverlayGestureLayer`, and minimized-dot presentation
- Gesture handling for drag, resize, tap-to-toggle-transparency, and restore from minimized state
- Animation handling for move, resize, fade-out, and restore flows
- Widget tests for drag, snap, resize, transparency, and minimized behavior

## Exact Implementation Instructions

1. Under `features/overlay/presentation`, create the page that hosts preview and calibration behavior. It should provide a bounded surface that mimics the visible screen area and makes the overlay editable in-app. This page is shared infrastructure for Android preview and the primary mode for iOS, so write it as a durable product screen rather than a debug-only toy.
2. Build a reusable overlay widget stack. A good decomposition is a visual canvas widget, a gesture layer widget, and small subcomponents such as resize handles, close button, minimized-dot view, and optional overlay content decoration. The gesture layer should be as dumb as possible: it turns pointer input into intents, and the controller decides the resulting state.
3. Use the overlay state and constraint engine from earlier steps. Dragging and resizing must round-trip through controller methods and domain sanitization rather than mutating local `Positioned` values directly. This ensures that safe-area clamping, snap threshold, and min or max size remain consistent with the migration spec.
4. Implement transparent mode behavior in the shared UI. Tapping the overlay should only toggle transparency when the master setting allows it. The visual state change should be animated or at least clearly rendered, but the timer and legality of the transition belong to controller logic. Likewise, fade-out on hide should be driven by controller commands and consumed in the widget layer.
5. Implement minimized behavior using the documented dot-size boundaries. The minimized representation should be restorable, visually clear, and still constrained to screen-safe bounds. If the legacy app had optional rotation animation for the minimized state, preserve it as a controllable setting rather than hardcoding motion into the widget.
6. Build widget tests that simulate drag, resize, edge snap, transparency toggle, and minimized restore. These tests are especially important because they are the shared guarantee that Flutter behavior matches the old app's interaction expectations before native adapters are added.
7. Keep this entire step shared. Do not implement system-window host behavior here. The output should be a Flutter overlay scene that can be embedded by different hosts later: normal page preview, iOS in-app overlay mode, or Android platform-driven container.

## Important Constraints

- Do not move geometry logic into gesture handlers.
- Do not build Android `SYSTEM_ALERT_WINDOW` behavior here.
- Do not use local mutable widget state as the source of truth for overlay layout.
- Do not fake iOS parity by claiming system-wide overlay support that does not exist.

## Acceptance Criteria

This step is complete only when the shared overlay experience is credible:

- The preview page exists and is controller-driven.
- Drag, resize, snap, transparency, and minimize behaviors are visible and testable.
- The widget tree is reusable for both Android preview flows and iOS in-app mode.
- Fade and restore behavior follow controller commands rather than widget guesswork.
- Widget tests cover the core interactions that define the product.

## Handoff Notes for the Next AI

The next step will finally connect this shared overlay experience to platform-specific ports and adapters. That means the Flutter overlay scene created here should already be clean enough to embed without modification. Keep it host-agnostic. The native layer should mount or coordinate it, not rewrite its internal interaction rules.
