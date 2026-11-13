# Each CI job calls one of these targets, so a check works the same way
# on the maintainer's machine and in CI. The spec is
# docs/superpowers/specs/2026-11-12-repo-and-ci-design.md.

# On Arch, lua52-busted installs busted outside PATH. Use a busted on PATH
# if there is one (CI). If not, use the Arch rock path.
LUA         := lua5.2
ARCH_BUSTED := $(lastword $(wildcard /usr/lib/luarocks/rocks-5.2/busted/*/bin/busted))
BUSTED      := $(shell command -v busted 2>/dev/null)
ifeq ($(BUSTED),)
  RUN_BUSTED := $(LUA) $(ARCH_BUSTED) --lua=$(LUA)
else
  RUN_BUSTED := $(BUSTED)
endif

# StyLua comes from npm, so the maintainer and CI use the same version.
STYLUA := node_modules/.bin/stylua

# The Factorio API for the pinned version, and the LuaLS type library
# that FMTK builds from it. Make rebuilds it when .factorio-version or
# package-lock.json (and so FMTK) changes. The spec is
# docs/superpowers/specs/2026-11-13-lua-tooling-design.md.
API      := .factorio-api
FACTORIO := $(shell tr -d '[:space:]' < .factorio-version)
DOCS     := https://lua-api.factorio.com/$(FACTORIO)
FMTK     := node_modules/.bin/fmtk

# Lua modules that luarocks installed for this user, such as luacov. The
# _5_2 names reach Lua 5.2 only. Arch's luacheck runs on Lua 5.4 and must
# not load 5.2 modules.
ifneq ($(shell command -v luarocks 2>/dev/null),)
  export LUA_PATH_5_2  := $(shell luarocks --lua-version 5.2 path --lr-path);;
  export LUA_CPATH_5_2 := $(shell luarocks --lua-version 5.2 path --lr-cpath);;
  export PATH          := $(HOME)/.luarocks/bin:$(PATH)
endif

MARKDOWN = $(shell git ls-files '*.md')

.PHONY: setup fast check text lua tools gates format ingame stamp package

## once, after a clone: turn on the git hook
setup:
	git config core.hooksPath .githooks

## every commit (the git hook)
fast: text lua tools

## before a PR
check: fast gates ingame

text:
	mdl $(MARKDOWN)
	python3 -m tools.text_check
	lychee --offline --no-progress $(MARKDOWN)

# The recipe deletes the old folder first, so no class from an old
# version stays. It writes the stamp last, so a run that stops part way
# starts again next time.
$(API)/stamp: .factorio-version package-lock.json
	@test -x $(FMTK) || \
	  { echo "fmtk is missing: run \`npm ci\`, then try again"; exit 1; }
	rm -rf $(API)
	mkdir $(API)
	curl -fsSL -o $(API)/runtime-api.json $(DOCS)/runtime-api.json
	curl -fsSL -o $(API)/prototype-api.json $(DOCS)/prototype-api.json
	$(FMTK) docs -d $(API)/runtime-api.json -p $(API)/prototype-api.json $(API)
	echo "factorio $(FACTORIO)" > $@

lua: $(API)/stamp
	mkdir -p build
	luacheck .
	$(STYLUA) --check .
	lua-language-server --check . --checklevel=Warning --logpath build/luals
	$(RUN_BUSTED) --coverage
	luacov
	python3 -m tools.coverage_floor build/luacov.report.out

## rewrites the Lua files in the repository's format
format:
	$(STYLUA) .

tools:
	python3 -m pytest -m "not gates"
	python3 -m tools.check_version

## the gate tests that need LuaLS, StyLua and the API folder
gates: $(API)/stamp
	python3 -m pytest -m gates

## MODE=base or MODE=space-age runs one mode; empty runs both
ingame:
	tools/ingame.sh $(MODE)

## after /ste80-humanizer and /simplify: lets the Claude Code hook pass
stamp:
	python3 -m tools.review_stamp stamp

package:
	python3 -m tools.package
