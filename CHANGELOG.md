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

### Fixed

- In Space Age, a warded spitter egg and a warded spitter larva weighed less
  than the plain item. Every lifecycle item now has an explicit weight, and
  a warded item has the same weight.
- The mod still loads when another mod removes the centrifuge, the
  assembling machine 3, the chemical plant or the biochamber. Its machines
  then borrow the look of the assembling machine 2.
