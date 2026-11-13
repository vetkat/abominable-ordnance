# Stage 6: Comprehension Test

Target: `docs/superpowers/specs/2026-11-14-ordnance-design.md`, the whole
file (draft of 2026-11-14). Reviewer: `egm-comprehension`, with the
document alone and no document standard. Verdict: no Blocker, 5 Major,
8 Nit.

## What this proposes

Slice 2 turns monster eggs into ammunition. An incubator makes one larva
from 10 eggs. A loading chamber then combines a larva with one of three
payload items (explosive rocket, sulfuric acid barrel or poison capsule)
to make a loaded larva. That gives six items: 2 species × 3 payloads. A
plain larva that spoils hatches a wild monster, as an egg does. A loaded
larva that spoils becomes a "loaded monster": a vanilla unit that the
script creates on a new force, `ao-tamed`, which is hostile to the
natives and at peace with players. The script records the monster's
payload in `storage` by unit number. When the monster dies, the script
creates vanilla entities at the spot (a rocket projectile, a poison cloud
or an acid puddle). While an acid monster is alive, the script also drops
a small acid puddle under it every 60 ticks. A new technology, Ordnance
loading, unlocks the chamber. Slice 2 has no launcher, so the player
delivers a loaded larva by carrying it to the target and letting it spoil
there. Seven questions (Q1 to Q7) wait for the maintainer, and the work
is split into three PRs.

## How the existing system works, per this document

Slice 1 already added species (biter and spitter), eggs that native
spawners drop, and spoiling eggs that hatch a wild monster. The slice 1
hatch handler, `Hatching.pick` and the species table choose the unit by
enemy evolution, using a table that has four sizes per species. A
technology called Monster husbandry already exists. Balance numbers live
in `core/balance.lua`, and the species data lives in `core/species.lua`.
Slice 1 also set an "egg ratio" of 10, though this document never says
what that ratio measures. `docs/design.md` holds the overall design, the
research tree and a warning about prototype count.

## Findings

- **C1. Major.** "Terms are as in the slice 1 spec" gives no path, and
  "egg ratio of 10" is never defined. Q1 rests on it. Fix: give the path
  and define the egg ratio in one sentence.
- **C2. Major.** The tamed force: Terms say "at peace with every player
  force", the Force row says "hostile only to `enemy`", and Q4 asks
  whether loaded monsters may attack the player's buildings. "Natives" is
  not defined as the `enemy` force. The force of the death-effect
  entities is not given, so it is unclear whether they can hurt the
  player.
- **C3. Major.** Two mechanisms are missing. What makes the created unit
  attack (a command, a target or default behaviour)? Where does the
  monster appear when a loaded larva spoils in the player's inventory, a
  chest, a machine output or on a belt? With hand delivery and a 5-minute
  spoil time, the inventory looks like the common case.
- **C4. Major.** `Effects` takes a size, but the death effects are fixed
  entities. What does size change: the number of entities, the acid
  splash variant or the damage?
- **C5. Major.** The status says the maintainer approved no design, yet
  only some Decisions rows carry a question number. Do the other rows
  (death effects, acid cloud, research, item generation, platforms) also
  need approval?
- **C6. Nit.** "payload cap" in Q3 is not defined.
- **C7. Nit.** "effect IDs" and `larva_effect_id` assume the reader knows
  how slice 1 routes spoil triggers to the script.
- **C8. Nit.** The Research row does not show which technologies unlock
  the poison capsule and the acid barrel.
- **C9. Nit.** "Acid cloud" in Purpose, but the design builds a trail of
  puddles.
- **C10. Nit.** Versions and slices: the relation is not explained beyond
  "slices make up version 1".
- **C11. Nit.** "Both modes" is not defined.
- **C12. Nit.** Space platforms: is the item used up or does it stay?
- **C13. Nit.** PR 2 ships loaded larvae, but their spoil behaviour comes
  in PR 3. What does a loaded larva do between the two PRs?
