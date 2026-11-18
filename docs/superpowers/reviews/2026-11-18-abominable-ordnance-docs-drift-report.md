# Drift report: docs/ before release 1.0.0, second run

Date: 2026-11-18. Main at `591e3bc`. Made with `/egm:egm-drift-report docs/`.
The first run on 2026-11-17 checked every document. This run checks the
documents that later changes touch: the poison aura (#51 to #53), the feral
fix (#55), the daily Factorio pin (#54) and `make api` (#48). It also checks
the open findings of the first run. Three read-only checkers did the work.
`make check` passes on the same commit.

## Summary

No finding shows broken code. The release pull request fixes the stale text
below. The maintainer decided that 1.0.0 ships as a GitHub release only. The
mod portal upload is a later change.

## docs/design.md

- The feral force was "hostile to everyone" in two places. Since #55 it is
  at peace with neutral. Fixed in the release pull request.
- The research tree did not show that Larva rockets needs Rocketry
  (`core/prototypes/launcher.lua:188`). Fixed: the box now says "Needs
  Rocketry".
- Every other finding of the first run for this file is resolved.

## docs/architecture.md

- The type annotation rule asks for `---@param event EventData.<name>` on
  named event handlers. No handler has one. Open: a follow-up adds the
  annotations or relaxes the rule. It does not block the release.

## docs/superpowers/specs/2026-11-14-feral-design.md

- The spec says the feral rule returns nil for neutral, and the feral
  force is "hostile to everyone". Since #55 the rule returns true. Fixed
  with a banner at the top. The body stays as history.

## docs/superpowers/specs/2026-11-17-poison-aura-design.md

- The body still has the `spare` field, `max_targets = 20` and the old
  puff size. The section "Changes after the play test" records the new
  values, and the banner now says that every mention in the body is stale.

## docs/superpowers/specs/2026-11-12-repo-and-ci-design.md

- The version rule said the version stays at 0.1.0. Fixed for 1.0.0.
- The spec and `release.yml` said portal uploads arrive with design
  version 1. Fixed: they are a later change.

## README.md and ROADMAP.md

- The README said the mod has no release. Fixed.
- The roadmap item "Runs on vanilla Factorio 2.1 and with Space Age" was
  open. The maintainer finished the play test on 2026-11-18. Ticked.
