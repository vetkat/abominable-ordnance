# Abominable Ordnance

Load the functional-core skill before you change code.

## Setup

On a fresh clone, run `npm ci` and `make setup`. `README.md` lists the
other tools. `make fast` runs the gates that the git hook runs. It must
stay under about 10 seconds.

## Workflow

1. Create a branch from `main`.
2. Work test-first with `superpowers:test-driven-development`, for all
   code, `tools/` included.
3. Commit in this order. Run each command as a Bash call of its own:
   1. Run `/ste80-humanizer` in British English on changed prose and
      comments.
   2. Run `/simplify` on changed code. Choose the number of reviewers
      from the table below.
   3. `git add` the files, then `make stamp`, then `git commit`. Do not
      use `git commit -a` or paths after `git commit`. The git hook
      refuses an agent commit without a current stamp.
4. Push the branch and open a PR. The PR title is a Conventional Commit,
   for example `feat: add larvae`.
5. When `all-checks` passes, squash merge the PR. Nothing goes to `main`
   in any other way.

| Change | Reviewers for `/simplify` and code review |
| --- | --- |
| Docs, config, or under about 50 lines in one file in an existing pattern | 1, or a pass by the author |
| About 50 to 200 lines, or one new module | 2: simplification and altitude |
| Over about 200 lines, many files, or anything that other work depends on (hooks, CI, release, shared core modules) | 4 |

## Rules

- The target is Factorio 2.1, with and without Space Age.
- Read `docs/design.md` and `docs/architecture.md` before you work on the
  mod.
- A change to mod code gets an entry under Unreleased in `CHANGELOG.md`.
  Update `ROADMAP.md` when a change affects it.
- A new spec: superpowers brainstorming writes it, `/egm:egm-review`
  reviews it, and superpowers writing-plans turns it into a plan. You can
  start an EGM review on your own, but not after a small edit.
- Specs, plans and EGM reports go in `docs/superpowers/specs/`,
  `docs/superpowers/plans/` and `docs/superpowers/reviews/`, with the date
  and the project in the file name.
- Before a release: run `/egm:egm-drift-report docs/` and `make check`,
  then set the version by the version rules in
  `docs/superpowers/specs/2026-11-12-repo-and-ci-design.md`.
- Never commit `docs/archive/`. It holds old chat logs.
