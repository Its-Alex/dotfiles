# Scripts

Every `run_*` script lives in [`.chezmoiscripts/linux/`](../.chezmoiscripts/linux).

`.chezmoiscripts/` is a chezmoi
[special directory](https://www.chezmoi.io/reference/special-directories/chezmoiscripts/):
its scripts are executed like any other script, and no corresponding directory or
file is created in the home directory. A subdirectory inside it is only
organisation — chezmoi has no OS or architecture filtering there, so on a
non-Linux machine everything under `linux/` must be made a no-op by its own
template guard.

## Numbering

Script names are `run_<lifecycle>_<NNN>-<slug>.<ext>`, with a 3-digit `NNN`:

| Range | Contents |
|---|---|
| `01x` | Packages |
| `02x` | Machine bootstrap |
| `04x` | Secrets |
| `05x` | Services |
| `06x` | Machine-specific setup |
| `07x` | Fixups |

Take the next free number inside the range of the script you add, and leave gaps
between ranges (they absorb growth without renumbering). Renumbering is not free:
see [State](#state).

## Lifecycle

The lifecycle attribute is chezmoi's and is unchanged by the numbering:

| Prefix | When it runs |
|---|---|
| `run_once_` | Once per unique rendered content, ever |
| `run_once_before_` | Same, before files are updated |
| `run_once_after_` | Same, after files are updated |
| `run_onchange_` | Whenever the rendered content changes |
| `run_onchange_before_` | Same, before files are updated |
| `run_onchange_after_` | Same, after files are updated |
| `run_` | Every apply |
| `run_before_` / `run_after_` | Every apply, before / after files are updated |

Order inside a phase is the alphabetical order of the script's target path, which
is why the numeric prefix matters: `.chezmoiscripts/linux/010-...` runs before
`.chezmoiscripts/linux/020-...`.

## State

- `run_once_` scripts are keyed by the SHA256 of their **rendered content**, so
  renaming or renumbering one does not re-run it.
- `run_onchange_` scripts are keyed by **name**, so renaming or renumbering one
  makes it run again on the next apply. They must stay idempotent.

Clear that state when it gets in the way: `chezmoi state delete-bucket
--bucket=scriptState` (once) or `--bucket=entryState` (onchange).

## Adding a script

1. Pick the range and the next free number.
2. Guard the whole file with a template condition when it only applies to some
   machines, and keep a `#!/usr/bin/env bash` line plus `set -euo pipefail`.
3. Make it idempotent: it will be re-run by anyone who renumbers it.
4. The executable bit is unnecessary — chezmoi copies the script to a temporary
   file and sets it itself.
