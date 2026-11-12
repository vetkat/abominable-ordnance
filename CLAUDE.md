# Abominable Ordnance

Load the functional-core skill before you change code.

## Rules

- The target is Factorio 2.1, with and without Space Age.
- Read `docs/design.md` and `docs/architecture.md` before you work on the
  mod.
- Use `superpowers:test-driven-development` for all code, `tools/`
  included.
- Before each commit, run `/ste80-humanizer` in British English on
  changed prose and comments, and `/simplify` on changed code. Stage the
  result, then run `make stamp`, then commit. The git hook refuses an
  agent commit without a current stamp. Do not use `git commit -a` or
  paths after `git commit`.
- A change to mod code gets an entry under Unreleased in `CHANGELOG.md`.
  Update `ROADMAP.md` when a change affects it.
- A new spec: superpowers brainstorming writes it, `/egm:egm-review`
  reviews it, and superpowers writing-plans turns it into a plan.
- Change `main` only through a PR. A PR title is a Conventional Commit,
  for example `feat: add larvae`. PRs are squash merged.
- Before a release: run `/egm:egm-drift-report docs/` and `make check`,
  then set the version by the version rules in
  `docs/superpowers/specs/2026-11-12-repo-and-ci-design.md`.
- Never commit `docs/archive/`. It holds old chat logs.
