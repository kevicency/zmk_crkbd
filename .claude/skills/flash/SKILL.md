---
name: flash
description: Build the Corne firmware and flash whichever halves changed, prompting the user to plug in each one. Use when the user wants to flash, deploy, or try a change on the keyboard.
---

Each half takes its turn: the user connects it, the script waits for the bootloader volume, copies, and confirms.

1. **Build.** Run `scripts/build.sh`. Done when it prints both `.uf2` names; on a build error, stop and show the error.
2. **Pick the halves.** Run `scripts/flash.sh left --check` and `scripts/flash.sh right --check`; exit 0 means that half needs flashing. No half needs it → tell the user the keyboard is already current and stop.
3. **Flash each half that needs it, left first.** For each:
   - Tell the user, in one line, before the tool call: "Plug the **<side>** half into USB and double-tap its reset button."
   - Run `scripts/flash.sh <side>` with a 180 s timeout. It waits up to 2 min for `/Volumes/NICENANO`.
   - Done when it prints `flashed <side>`. On `timed out`, ask whether to retry or skip that half; on `still mounted`, retry once, then report the failure.
4. **Report** which halves were flashed and which were already current.

Only one half can be in the bootloader at a time: both mount as `NICENANO`, so the script cannot tell them apart and relies on the user connecting the side it named.
