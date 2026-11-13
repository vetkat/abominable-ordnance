# Lua tooling: Stage 8 intermediate zoom-out report

Target: `docs/superpowers/specs/2026-11-13-lua-tooling-design.md`, lines
1 to 288. Reviewer: `egm-zoom-out`, with the Stage 5 to 7 reports. The
review completed.

Verdict: the design is sound. The main risk now comes from the reviews.
About a third of the 40 findings propose new mechanisms. If the spec
adopts all of them, a small change becomes a large one.

## New findings

| ID | Severity | Lines | Finding |
| --- | --- | --- | --- |
| ZO8-1 | 🟡 Major | 69-75, 88-112, 133, 251-255 | A Python tool with a pure core, a stamp and a pytest suite answers one question: is `.factorio-api/` older than `.factorio-version` or the FMTK version? A Make file target with those two prerequisites answers it, as `tools/ingame.sh` already does for the server. This removes about eight findings. |
| ZO8-2 | 🟢 Nit | 167-169, 269-271 | Drop the drift test. FMTK changes only through a reviewed PR. Put a comparison step in the FMTK upgrade path. |
| ZO8-3 | 🟢 Nit | 222-223 | Delete the git-hook paragraph. Line 25 already says it. |

## Verdicts on proposed fixes

**Adopt:**

- the `.luacheckrc` and `.styluaignore` exclusion (ZO-1, DC-B1, ST-M2)
- StyLua pinned through npm (first half of IC-2)
- the search path in `CLAUDE.md` (ZO-5)
- `make setup` stays offline (ZO-7)
- a risk for false negatives (DC-M4)
- one acceptance criterion for goal 3 (ST-M4)
- a concrete rule for false problems (ST-M5)
- one sentence on what `make fast` runs (CO-1)
- a short Alternatives table (DC-B2, ST-B1)

**Adopt in a smaller form:** state that the CI spec's staged-file
fallback does not apply to LuaLS (IC-3). Write the LuaLS gate test in
`tmp_path` with its own `.luarc.json`, and measure `make fast` (DC-M2,
DC-M3). Add one security risk, with an optional checksum for the
release downloads (ST-M1, DC-N2).

**Reject:**

- running the gate tests in CI (IC-1, DC-M1), because `test_gates.py`
  already accepts that the `tools` job skips them
- moving or sharing the cache (DC-M5, IC-8)
- `make lua` only checking the stamp (IC-4)
- a stamp-keyed CI cache (IC-6)
- split cache steps (DC-M6)
- a second download source (IC-7)
- stage separation (DC-N5)
- a drift check for the factorio-test globals (ZO-6)
