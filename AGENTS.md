# AGENTS.md

ZMK user config for a wireless Corne (nice!nano v2 + nice!view, split). Colemak-DH base, macOS shortcuts (`LG` = Cmd). ZMK is pinned to `v0.3` in `config/west.yml`; read the v0.3 docs at zmk.dev, since `main` docs describe behaviors and Kconfig options this build lacks.

## Build and verify

There is no local toolchain. GitHub Actions builds on every push (`.github/workflows/build.yml` → `build.yaml` matrix). A change is done when the run for its commit goes green: `gh run watch` or `gh run list --limit 1`. Firmware ships as the run's `firmware` artifact (one `.uf2` per half).

The left half is the central: it alone carries the `studio-rpc-usb-uart` snippet, and it is the half that must be flashed after any keymap change. Kconfig or overlay changes need both halves.

## Keymap (`config/corne.keymap`)

**Key positions** run 0–41: rows of 12 (0–11, 12–23, 24–35), thumbs 36–41. Combos and every `hold-trigger-key-positions` list address keys by these numbers, so a moved key means re-checking them.

**Layers** are referenced through the `#define BASE 0 …` block; those indices must match the order of layer nodes in `keymap {}`. Insert a layer → renumber the defines.

How layers are reached (not obvious from bindings alone):

- `SYM` / `NUM`: thumb layer-taps (`lt_bal`).
- `NAV`: tri-layer, `SYM` + `NUM` held together (`conditional_layers`).
- `UTIL`, `GAMING`: one-way `&to` from `NAV`; both return with `&to BASE`.

**Home-row mods** (`hml`/`hmr`) use `balanced` + `hold-trigger-on-release` + `require-prior-idle-ms`. These are tuned values; change timing only when asked.

**Layer diagram comments** above each `bindings` block are the human-readable map. Update the diagram in the same edit as its bindings.

`ZMK_POINTING_DEFAULT_*` defines must stay above the `#include` lines, or the defaults win.

## Power and wake

`config/corne.conf` enables idle/sleep and soft-off. Soft-off fires from combo positions `0 + 11` (hold 2.5 s) or `&soft_off` on `UTIL`. Wake is wired in hardware terms in `corne_left.overlay` / `corne_right.overlay` (row-0 GPIO + all column pins); it does not follow the combo, so moving the combo leaves wake on the old keys.

## ZMK Studio

Studio is on and unlocked (`CONFIG_ZMK_STUDIO_LOCKING=n`). Bindings changed in Studio live in the keyboard's flash and override this file until "Restore Stock Settings". When the device disagrees with the repo, suspect a Studio edit before a build bug.

## Commits

Conventional commits (`feat:`, `fix:`, `chore:`), straight to `main`.
