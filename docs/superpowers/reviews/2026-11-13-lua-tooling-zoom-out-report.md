# Lua tooling: Stage 5 zoom-out report

Target: `docs/superpowers/specs/2026-11-13-lua-tooling-design.md`, lines
1 to 288. Reviewers: `egm-zoom-out` and `egm-inventive-catalyst`. Both
completed.

## Zoom-out reviewer

The context is enough. The spec stays on the root problem.

| ID | Severity | Lines | Finding |
| --- | --- | --- | --- |
| ZO-1 | 🟡 Major | 69-86, 191-194 | `.factorio-api/` holds about 1,171 generated `.lua` files inside the repository. `luacheck .` does not read `.gitignore`, and `.luacheckrc` does not exclude the folder. `.styluaignore` copies `exclude_files`, so StyLua has the same gap. `make lua` fails after the first `make api`. |
| ZO-2 | 🟡 Major | 167-169, 269-271 | The pytest that compares `.luarc.json` with FMTK's `config.json` skips without the cache. CI runs pytest only in the `tools` job, which has no cache. So the check never runs in CI. Suggestion: do the comparison in `make api`. |
| ZO-3 | 🟢 Nit | 88-106 | `plan()` returns a step list with only one path. A "stale or current" check is simpler. Function names are plan detail. |
| ZO-4 | 🟢 Nit | 93-112 | `tools/factorio_version.py` already has `SEMVER`, the pin read and a `urllib` download. Reuse them. |
| ZO-5 | 🟢 Nit | 125-127, 219 | Grep and Glob skip hidden and ignored folders by default. The CLAUDE.md rule must name the path `.factorio-api/factorio/library/`. |
| ZO-6 | 🟢 Nit | 156-157 | The factorio-test globals are copied from `.luacheckrc` with no check that the two copies agree. |
| ZO-7 | 🟢 Nit | 136 | `make setup` running `make api` repeats the trigger in `make lua`, and makes `setup` need the network. |

## Inventive catalyst

No Blockers. All findings are advisory.

| ID | Severity | Lines | Finding |
| --- | --- | --- | --- |
| IC-1 | 🟡 Major | 257-271, 276 | The new gate tests and the drift test skip in CI, because the `tools` job has neither the tools nor the cache. Acceptance criterion 2 is not enforced in CI. |
| IC-2 | 🟡 Major | 211-213, 242-244 | A formatter that floats locally (pacman) but is pinned in CI can make `make format` write code that CI rejects. Suggestion: pin StyLua through npm (`@johnnymorganz/stylua-bin`), and warn when the local LuaLS version differs from a pin. |
| IC-3 | 🟡 Major | 245-247 | The fallback "the hook checks only staged files" does not fit LuaLS, which reads the whole workspace. Suggestion: the hook runs LuaLS only when Lua or its settings are staged, or LuaLS leaves the hook if the budget breaks. |
| IC-4 | 🟡 Major | 133-139 | `make lua` runs `make api`, so a commit can need the network and a full `fmtk docs` run. Suggestion: `make lua` only checks the stamp and says "run `make api`". |
| IC-5 | 🟢 Nit | 146-158, 191-194 | Settings are copied in four places, and only one copy has a drift test. Probe whether LuaLS applies the addon's `config.json` by itself. |
| IC-6 | 🟢 Nit | 201-202 | The CI cache key hashes all of `package-lock.json`. The stamp text is the exact key. |
| IC-7 | 🟢 Nit | 234-235 | GitHub evicts unused caches after 7 days, so the site is hit more often than the risk says. Name a second source or accept the risk. |
| IC-8 | 🟢 Nit | 62, 114-123 | Each worktree gets its own cache. A shared cache, like `FACTORIO_CACHE`, avoids repeat downloads. |
