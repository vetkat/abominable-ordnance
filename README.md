# Abominable Ordnance

A Factorio mod. You breed the planet's monsters in your base, stuff them
with ordnance, and fire them at the natives. A biter loaded with an
explosive rocket blows up on death. Late in the game, you crossbreed
everything into one final Abomination.

## Status

Version 0.1.0 is an empty mod: the repository, its checks and its release
workflow. The first features arrive in 1.0.0 (design version 1). See the
[roadmap](ROADMAP.md).

## Install

The mod is not on the mod portal yet. Download the zip from the GitHub
releases page and put it in your Factorio `mods` folder. The mod needs
Factorio 2.1. Space Age is optional.

## Development

The tools, on Arch Linux:

```bash
sudo pacman -S lua52 lua52-busted luacheck luarocks lychee lua-language-server
sudo pacman -S ruby nodejs npm python-pytest poppler
gem install mdl
luarocks --lua-version 5.2 install --local luacov
npm ci
make setup
```

`make setup` turns on the git hook in `.githooks/`, which runs
`make fast` before each commit.

| Target | What it runs | When it runs |
| --- | --- | --- |
| `make setup` | Sets `core.hooksPath` to `.githooks` | once, after a clone |
| `make text` | mdl, the text check, lychee in offline mode | in `make fast`, CI job `text` |
| `make lua` | Builds the API folder if needed, then luacheck, StyLua, LuaLS, busted under Lua 5.2, the coverage floor | in `make fast`, CI job `lua` |
| `make tools` | pytest without the gate tests, `check_version.py` without a tag | in `make fast`, CI job `tools` |
| `make gates` | The gate tests that need LuaLS, StyLua and the API folder | in `make check`, CI job `lua` |
| `make format` | Rewrites the Lua files in the repository's format | before you stage Lua |
| `make fast` | `make text`, `make lua`, `make tools` | every commit (git hook) |
| `make ingame` | The in-game tests in the headless server, base game only and with Space Age | CI job `ingame`, by hand |
| `make check` | `make fast`, `make gates`, `make ingame` | before a PR |
| `make stamp` | Writes the review stamp for the staged files | after the review skills |
| `make package` | Generates `changelog.txt` and builds the zip in `build/` | release |

`make lua` builds `.factorio-api/` the first time, and again after a
change to `.factorio-version` or `package-lock.json`. That needs the
network. The folder holds the Factorio API JSON for the pinned version
and the type library that FMTK builds from it.

For VS Code, the FMTK extension (Factorio Modding Tool Kit) gives a
debugger and a profiler for the running game. If it offers to write
`.luarc.json`, keep the committed file.

To move to a new FMTK version:

1. Change the version of `factoriomod-debug` in `package.json`.
2. Run `npm install`, then `make lua`.
3. Compare the `settings` object in
   `.factorio-api/factorio/config.json` with `.luarc.json`. Copy any
   change.

After a factorio-test upgrade, compare its globals in `.luacheckrc` with
`diagnostics.globals` in `.luarc.json` in the same way.

The in-game tests use the `factorio-test` mod. Its zip is in
`tools/vendor/`, because the mod portal needs a login to download it.
`THIRD_PARTY.md` lists its source and licence.

## Documents

- [The design document](docs/design.md)
- [The architecture rules](docs/architecture.md)
- [The changelog](CHANGELOG.md) and [the roadmap](ROADMAP.md)
- [The repository and CI spec][ci-spec]

[ci-spec]: docs/superpowers/specs/2026-11-12-repo-and-ci-design.md
