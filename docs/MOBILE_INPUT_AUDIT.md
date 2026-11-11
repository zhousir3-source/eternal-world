# Mobile Input Audit — Initial Findings

Branch: `ew/mobile-first`

## Confirmed in source

- `presets/gui/Game.tscn` already contains a virtual movement stick and separate TouchScreenButton controls for A/B/X/Y and shoulder actions.
- `sources/gui/Sticks.gd` owns the virtual stick and shows/hides mobile controls through `Enable()`.
- `sources/input/Action.gd` already handles screen touch, screen drag, long-press timing, pinch zoom, and combines the virtual stick vector with gamepad movement.
- `sources/input/DeviceManager.gd` selects a joystick-style control profile on mobile and sends virtual button events into Godot's input system.
- `LauncherCommons.isMobile` detects Android, iOS, and mobile browser user agents.

## Risks requiring device verification

1. The virtual stick updates its knob in `_physics_process()` using `get_local_mouse_position()`. This should be tested with native multi-touch on Android; mouse emulation and simultaneous touch pointers can behave differently across devices.
2. The current stick knob is clamped to a fixed 0–100 local coordinate range. Confirm that the visual travel range matches the actual background texture and remains correct under viewport scaling.
3. Verify that holding the movement stick while pressing an action button does not release movement or cause the wrong virtual gamepad button to remain pressed.
4. Confirm that mobile controls are enabled in the actual in-game state and remain visible after opening/closing windows, changing resolution, and rotating the device.
5. Check long press and pinch zoom while interacting with the virtual controls to avoid gesture conflicts.

## Acceptance checklist

- [ ] Movement works in all eight directions.
- [ ] Releasing the stick immediately stops movement.
- [ ] Movement can be held while an action button is pressed.
- [ ] Every virtual action button produces exactly one press and one release.
- [ ] No stuck movement/action input after app loses focus or resumes.
- [ ] Controls remain inside safe areas on common phone aspect ratios.
- [ ] Touch hit areas are comfortable without obscuring the game world.
- [ ] No regression to mouse and keyboard controls.

## Current status

Source inspection only. No Android runtime test has been performed yet. Do not treat the mobile controls as verified until this checklist is completed on a physical device.
