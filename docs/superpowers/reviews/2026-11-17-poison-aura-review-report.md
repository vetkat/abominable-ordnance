# Poison aura spec: EGM review

Target: `docs/superpowers/specs/2026-11-17-poison-aura-design.md`.

## Round 1

Zoom out, comprehension and design critic. No Blocker. The Majors:

- The spec said the acid trail tests pass unchanged. The rename breaks
  six tests, and one test (a poison monster is not in the trail list)
  must invert. Fixed: the Architecture table lists each one.
- The puff could not shrink as written. The vanilla cloud gets most of
  its size from 21 extra smokes in its `created_effect`. Fixed: the puff
  drops `created_effect` and sets its own particle count and spread. The
  existing `cloud` builder makes both look-alikes.
- The UPS answer counted monsters, not targets, and "once a second" holds
  only up to 300 monsters. Fixed: both stated, with a measured target.
- Alternatives lacked an aura field beside the trail field, and a hazard
  with a moving anchor. Fixed: both rows added with reasons.
- Many terms needed the code to understand them. Fixed: the force rules,
  batch size, feral radius, puddle name, balance table and test build are
  defined in the spec.
- The doc updates missed `README.md` and `docs/architecture.md`. Fixed.

## Round 2

The same three reviewers. The comprehension and zoom out reviewers found
no Blocker or Major. The design critic found one Major: the fallback
"add a target budget like the hazard pass" was not designed, because the
trail pass cannot stop in the middle of a batch. Fixed: each aura hit
passes `limit = 20` to its entity search, which bounds the work at 100
damage calls a tick with no change to the pass. Cheap Nits fixed: an
existing test destroys its poison monster, the puff size is a target for
the probe, and the tree test accepts a dead tree as hurt.

## Round 3

A narrow check of the target limit by the design critic found no
Blocker or Major. The limit is correct and multiplayer-safe. Fixed one
Nit: the Architecture table names `limit` on `Damage.hit` and
`Damage.targets`.
