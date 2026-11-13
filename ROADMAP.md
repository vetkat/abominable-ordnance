# Roadmap

Each release ships one design version from
[the design document](docs/design.md). The agent keeps this file up to
date.

## 0.1.0: repository and CI

- [x] The design document in Markdown
- [x] An empty mod that loads in Factorio 2.1, with and without Space Age
- [x] Every gate runs locally and in CI
- [x] A release dry run builds a zip that loads

## 1.0.0: design version 1

- [ ] Breeding pod (slice 1) and incubator (slice 2) for biters and
  spitters ([design][lifecycle])

- [ ] Loading chamber with three payloads: explosive rocket, sulfuric acid,
  poison capsule ([design][ordnance-loading])
- [ ] Generated item and entity prototypes for each species and payload
  ([design][technical])
- [ ] Death effects for the three payloads, and the acid cloud while alive
  ([design][ordnance-loading])
- [ ] Long-range rocket ammo for loaded larvae, and a simple launcher for
  vanilla ([design][logistics-and-delivery])
- [ ] Feral behaviour inside a fixed radius
  ([design][feral-behaviour-and-risks])
- [ ] Spoil outcomes: eggs hatch wild, loaded larvae become loaded monsters
  ([design][lifecycle])
- [ ] Stasis ward that pauses and resumes the spoil timer
  ([design][logistics-and-delivery])
- [ ] The first four research techs ([design][research-tree])
- [ ] Runs on vanilla Factorio 2.1 and with Space Age
  ([design][version-1-feature-list])

## 2.0.0: design version 2

- [ ] Expand Orifices I and II ([design][ordnance-loading])
- [ ] Worms and pentapods ([design][monsters])
- [ ] The remaining payloads: grenades, slowdown, flamethrower, tesla, atomic
  bomb ([design][ordnance-loading])
- [ ] Artillery shells for loaded larvae ([design][logistics-and-delivery])
- [ ] Extractor, embryos, jazz pods with the smooth jazz, and the first
  hybrids ([design][crossbreeding])
- [ ] Facehuggers on enemies, and the pacifier facehugger
  ([design][facehuggers])

## 3.0.0: design version 3

- [ ] Demolisher hatchlings and heated pods ([design][monsters])
- [ ] The remaining hybrids, and the Abomination with its launcher
  ([design][crossbreeding])
- [ ] Pheromone dampener research ([design][feral-behaviour-and-risks])
- [ ] Facehuggers on players ([design][facehuggers])
- [ ] PvP setting for multiplayer ([design][concept])

[lifecycle]: docs/design.md#lifecycle-eggs-embryos-and-larvae
[ordnance-loading]: docs/design.md#ordnance-loading
[technical]: docs/design.md#technical-notes-factorio-21--space-age
[logistics-and-delivery]: docs/design.md#logistics-and-delivery
[feral-behaviour-and-risks]: docs/design.md#feral-behaviour-and-risks
[research-tree]: docs/design.md#research-tree
[version-1-feature-list]: docs/design.md#version-1-feature-list
[monsters]: docs/design.md#monsters
[crossbreeding]: docs/design.md#crossbreeding
[facehuggers]: docs/design.md#facehuggers
[concept]: docs/design.md#concept
