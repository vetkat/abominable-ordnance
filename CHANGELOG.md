# Changelog

All notable changes to this mod are in this file. The format follows
[Keep a Changelog 1.0.0](https://keepachangelog.com/en/1.0.0/), and the
mod uses [semantic versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- An empty mod that loads in Factorio 2.1, with and without Space Age.
- In-game smoke tests that run in the headless server.
- Biter and spitter eggs, monster chow, spitter chow and the breeding
  pod, unlocked by the Monster husbandry research.
- Eggs hatch when they spoil: every 10 eggs hatch a wild monster of
  their species, sized by enemy evolution. The monster attacks
  everything of yours within 32 tiles of where it hatched.
- Native biter and spitter spawners drop 1 to 3 eggs when a force with
  Monster husbandry destroys them.
  The eggs land beside the corpse, under a floating label.
- Biter and spitter larvae, and the incubator that makes 1 larva from 10
  eggs. A larva that spoils hatches a wild monster.
- The loading chamber and the Ordnance loading research. The chamber loads
  a larva with an explosive rocket, a sulfuric acid barrel or a poison
  capsule.
- Loaded monsters. A loaded larva that spoils becomes a monster on the
  tamed force, which fights the natives and spares players. When it dies,
  its payload goes off: a rocket blast, a poison cloud or five acid
  puddles. Acid burns native units, not nests. Nests that loaded
  monsters kill drop eggs.
- An acid-loaded monster leaves an acid trail, at most 5 monsters per
  tick. With more than 300 acid monsters, each one leaves puddles less
  often.
- Loaded larvae are now larva rockets, the ammo of the larva launcher.
  Loading one takes a larva rocket casing as well: 2 steel plates, 1
  explosives and 1 electronic circuit.
- The larva launcher, an artillery turret that holds 5 larva rockets and
  reaches 64 tiles. The larva targeting remote marks targets for it.
  Both come from the Larva rockets research, and three Larva launcher
  fire rate researches follow. The launcher has a circuit connector,
  its shots sound like artillery, and with Space Age it stays warm on
  cold planets. The remote stays in the inventory when you clear the cursor.
- Larva launcher range research in three levels. Each level adds 16 tiles.
  Placed launchers update to the level of their force and keep their ammo,
  wires and settings. A launcher built later starts at that level.
- The stasis ward and the Stasis ward research. A ward packs an egg, a
  larva or a larva rocket into a warded item that spoils 20 times more
  slowly. An unpack gives the item and the ward back, and the item keeps
  its spoil progress. A warded item that spoils still hatches its
  monster, and its ward is lost. On a space platform no monster hatches, and
  the item is lost with its ward.
- Loaded monsters go feral when a player with a character comes within
  their feral radius: 5 tiles for a small monster, 1 more per size step.
  A feral monster joins its own force, at war with everyone, hunts the
  nearest enemy within 64 tiles, and its payload still goes off when it
  dies. Feral kills drop no nest loot.
- Loaded monsters also go feral after 5 minutes with no natives within
  32 tiles, or by a small unstable chance: 0.2% per minute per payload.
  A feral monster whose attack fails wanders for about 50 s before it
  hunts again. A feral monster whose wander ends hunts again at once.
- The cryo ward and the Cryo ward research, with Space Age only. A
  cryogenic plant on Aquilo makes a cryo ward from 2 lithium plates and
  10 cold fluoroketone, and gives 5 hot fluoroketone back. A cryo ward
  packs an egg, a larva or a larva rocket into an item that spoils 100
  times more slowly. Pack and unpack work anywhere. The research needs
  Stasis ward and the cryogenic science pack.
- A monster loaded with a poison capsule hurts living things within 3
  tiles once a second, with a small green puff. It spares its own side.

### Changed

- The stasis ward builder takes a list of ward kinds, so a second ward
  can share it. Nothing changes in the game.
- Each payload decides what its landing blast and its death effect
  hurt, with its own damage type. Explosive hurts everything, rocks
  included. Poison hurts living things only. Acid hurts everything
  except rocks. Your own buildings, your character and tamed monsters
  count too, so an explosive death next to your wall damages the wall.
- An explosive death is one hit of 150 explosion damage in a 4-tile
  radius. A rocket that lands in water sets its payload off in the same
  way. Vanilla resistances still apply.
- Deaths run through a queue of at most 5 per tick, so a chain of
  deaths never stalls the game.
- If a force has friendly fire off, the natives deal the hits on its
  own buildings and units. Those kills count for them.
- A poison death leaves a cloud for 20 s that hurts living things
  within 11 tiles: natives, your character, tamed monsters and trees.
  An acid death leaves pools for 15 s that hurt everything except
  rocks within 3 tiles, your buildings included. Each hits every
  0.5 s.
- At most 10 cloud and pool hits run per tick, and they damage at most
  200 targets. Above that, a cloud hits less often but catches up, so
  its total damage stays the same.
- If another mod removes the explosion, poison or acid damage type,
  that payload deals no damage and the game goes on.
- Another mod can remove the vanilla poison cloud, an acid puddle or an
  entity that they name. The game still loads. Then the cloud, the pools
  or the trail show less or nothing, and the damage still applies.
- An acid monster's trail hits everything except rocks within 1 tile
  for 5 acid damage, your buildings and other tamed monsters included.
  It never hurts the monster that leaves it.
- Acid pools slow the natives, characters and monsters they hit.
- An acid monster from an old save now leaves the new puddles too.

### Fixed

- In Space Age, a warded spitter egg and a warded spitter larva weighed less
  than the plain item. Every lifecycle item now has an explicit weight, and
  a warded item has the same weight.
- The mod still loads when another mod removes the centrifuge, the
  assembling machine 3, the chemical plant or the biochamber. Its machines
  then borrow the look of the assembling machine 2.
