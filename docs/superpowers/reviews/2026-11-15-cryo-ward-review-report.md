# Cryo ward spec: EGM review

Target: `docs/superpowers/specs/2026-11-15-cryo-ward-design.md`.

## Round 1

Zoom out, comprehension and design critic. One Blocker: the spec said
cold fluoroketone can't go in a barrel. Vanilla data gives it a barrel,
so the ward could be made anywhere. Fixed: the ward recipe needs a
pressure of exactly 300, as the Aquilo science pack does. This is a call
for the maintainer. Other fixes: the ward recipe can't be recycled, so
lithium plates can't be raised in quality through it. The builder makes
the subgroup once. A test checks the spoil progress through both wards.

## Round 2

The design critic and the zoom out reviewer found no Blocker. Fixed: the
exact surface condition (min and max 300), one builder call with a list
of ward kinds, a pure `Stasis.kinds` that picks the kinds, and the edits
to `docs/design.md`.

## Round 3 and final check

Round 3 found one Major in a test: an unheated cryogenic plant freezes on
Aquilo. Fixed: the test heats it with a heating tower. A final narrow
check found no new Blocker or Major issue.
