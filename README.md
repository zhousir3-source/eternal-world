# Eternal World

Eternal World is a customized role-playing game project based on [Source of Mana](https://github.com/sourceofmana/sourceofmana), an open-source 2D MMORPG built with Godot 4.

This repository keeps the upstream project history and adds a separate adaptation branch for a mobile-first, Chinese-localized RPG experience.

## Current development status

- Engine baseline: Godot 4.7 (as configured by the upstream project).
- Target clients: Android first; Web export will be evaluated after the Android build is reproducible.
- Current branch: `ew/mobile-first`.
- Current milestone: project identity, mobile input audit, build and runtime verification.
- This is an active development fork. A working Android APK has not yet been produced from this branch.

## Development principles

1. Preserve upstream functionality unless a change is required and tested.
2. Keep custom work on the `ew/mobile-first` branch.
3. Verify gameplay state changes, not just UI appearance.
4. Test save/load compatibility whenever player data formats change.
5. Do not mark a platform or feature complete until it has been built and tested on a real device.

## Upstream and licensing

The upstream project is maintained by the Source of Mana contributors:
- Upstream repository: https://github.com/sourceofmana/sourceofmana
- Upstream project page: https://manasource.itch.io/source-of-mana

The upstream `LICENSE.md` describes MIT licensing for most code and CC BY-SA 4.0 licensing for artistic/design resources, with a resource attribution list. Check that file and each relevant asset's provenance before redistributing modified builds. Preserve required copyright notices, credits, and ShareAlike obligations.

## Planned milestones

- [ ] Verify Android export environment and produce a baseline debug APK.
- [ ] Test virtual joystick, multi-touch action buttons, UI scaling, and touch interaction on a physical phone.
- [ ] Localize the core login, character, HUD, inventory, equipment, skill, quest, and dialogue flows.
- [ ] Audit gameplay systems and client/server authority before expanding RPG mechanics.
- [ ] Add and test the Eternal World character, companion, equipment, loot, and progression content.

