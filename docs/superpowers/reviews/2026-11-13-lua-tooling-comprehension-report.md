# Lua tooling: Stage 6 comprehension report

Target: `docs/superpowers/specs/2026-11-13-lua-tooling-design.md`, lines
1 to 288. Reviewer: `egm-comprehension`, which read the spec alone. The
review completed.

## What this proposes

The spec adds three Lua checks to the mod's quality gates:

- **API type check.** LuaLS runs headless and checks the mod's Lua
  against type definitions for the pinned Factorio version.
- **Format check.** StyLua checks the format, and `make format` rewrites
  files.
- **Searchable API copy.** A local, git-ignored copy of the Factorio API
  JSON lives in `.factorio-api/`. The agent looks up API names there.

`tools/factorio_api.py` has a pure core and an I/O shell. When the stamp
is stale or missing, it downloads the two JSON files and runs `fmtk docs`.
It writes the stamp last, so a run that stops starts again next time.
`make lua` gains `make api`, `stylua --check` and
`lua-language-server --check`. CI installs pinned LuaLS and StyLua and
caches `.factorio-api/`. `CLAUDE.md` gets two rules.

## How the existing system works, per this document

The repository is a Factorio 2.1 mod. Make targets run its gates, and CI
runs them in `check.yml`. Today the Lua gates are luacheck, busted and a
coverage floor. A slower `ingame` job runs tests in the game.

`make fast` takes 4.4 seconds. A git hook runs something on commit and
checks a "review stamp". The document does not say which targets
`make fast` and `make check` run, or what the git hook runs.

## Findings

| ID | Severity | Lines | Finding |
| --- | --- | --- | --- |
| CO-1 | 🟡 Major | 15-28, 135, 141-142, 222-223, 275-277 | The spec never says how `make fast`, `make lua` and `make check` relate, or what runs at commit time. This matters because `make lua` now needs the network and `npm ci`. |
| CO-2 | 🟡 Major | 222-223 | The paragraph about the git hook's message names a "review stamp" that the spec does not introduce. "Stamp" also means `.factorio-api/stamp`. |
| CO-3 | 🟡 Major | 142, 167-169, 246, 277 | "The plan" means the future implementation plan in some places and the CI spec's fallback in another. |
| CO-4 | 🟢 Nit | 69-86, 260-271 | The Files table does not place the drift test, the planted fixture files, or the five reformatted files. |
| CO-5 | 🟢 Nit | 99 | "Gives a problem" does not say how `plan` reports an error. "Problem" is also LuaLS's word. |
| CO-6 | 🟢 Nit | 148-149 | The settings list does not name `workspace.library` or `runtime.plugin`, so the reader cannot connect the fact at lines 49-52 to a setting. |
| CO-7 | 🟢 Nit | 163-165 | "luacheck still gives the globals of each file" is unclear. |
| CO-8 | 🟢 Nit | 125-127 | The spec does not say why it matters that the class files are smaller than the JSON. |
| CO-9 | 🟢 Nit | 238, 242-244 | The spec does not say what a developer does when local StyLua and CI StyLua disagree. |
| CO-10 | 🟢 Nit | several | Project terms rely only on the link to the CI spec: EGM, the `ingame` job, functional core, factorio-test, `.lua`/`.luarocks`/`.install`, design version 1, coverage floor, `all-checks`. |

No Blockers. The three Majors are about how parts of the existing system
connect. Each needs a few sentences, not a redesign.
