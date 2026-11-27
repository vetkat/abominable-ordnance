# Third-party code and art

## ste80-humanizer checker

- File: `tools/vendor/ste_check.py`, unchanged
- Source: <https://github.com/Dodaios/ste80-humanizer>, file
  `scripts/ste_check.py` at commit
  `6a69c447a3eb24c7d403aea5fc04f965ad6dafcc`
- Licence: MIT, copyright (c) 2026 Dodaios
- Use: the text check (`tools/text_check.py`). It does not ship in the
  mod.

## factorio-test

- File: `tools/vendor/factorio-test_3.2.0.zip`, unchanged
- Source: <https://mods.factorio.com/mod/factorio-test> by GlassBricks
  (<https://github.com/GlassBricks/FactorioTest>)
- Licence: MIT
- Use: the in-game tests (`make ingame`). It does not ship in the mod.

## Pathogen lab (breeding pod)

- Files: `graphics/entity/breeding-pod/`, and
  `graphics/icons/breeding-pod.png` (scaled down from the original icon)
- Source: Hurricane046, "Factorio Buildings"
  (<https://www.figma.com/proto/y1IQG08ZG2jIeJ5sTyF4MP/Factorio-Buildings>),
  as packed in the Mod Framework graphics
  (<https://github.com/SimonBrodtmann/mod-framework>, folder
  `mf-buildings-graphics-1/graphics/pathogen-lab/`)
- Licence: CC BY 4.0
  (<https://creativecommons.org/licenses/by/4.0/>), © Hurricane046
- Changes: none, except that we resized the icon to 64 px.

## Oxidizer (incubator)

- Files: `graphics/entity/incubator/` and `graphics/icons/incubator.png`
- Source: Hurricane046, "Factorio Buildings" (link above), as split and
  repacked by Nullius: Hurricane Reskins (brickbrycebrick), folder
  `graphics/entity/oxidizer/`
- Licence: CC BY 4.0
  (<https://creativecommons.org/licenses/by/4.0/>), © Hurricane046
- Changes: the repack split the original into base, emission and shadow
  sheets. We resized the icon to 64 px.

## Simulation chamber (loading chamber)

- Files: `graphics/entity/loading-chamber/`,
  `graphics/icons/loading-chamber.png` and `sound/loading-chamber/`
- Source: snouz, Panglia mods on the Factorio mod portal
  (<https://mods.factorio.com/user/snouz>)
- Licence: MIT, as the mod portal states. The download had no licence
  file. Confirm before merge. The building contains parts of
  Hurricane046's art, so those parts are also under CC BY 4.0
  (<https://creativecommons.org/licenses/by/4.0/>), © Hurricane046.
- Changes: new file names. The sounds have no other change.

## Rocket turret (larva launcher)

- Files: `graphics/entity/larva-launcher/` and
  `graphics/icons/larva-launcher.png`
- Source: hl-Rocket-turret 0.1.2 by hlittlezero
  (<https://mods.factorio.com/mod/hl-Rocket-turret>)
- Licence: MIT, as the mod portal states. The download had no licence
  file. Confirm before merge.
- Changes: we removed the "Hlittlezero" lettering from every frame of
  the attack sheet. New file names. We resized the icon to 64 px.

## Own art

We made the item icons in `graphics/icons/` that the sections above do
not name, and the technology icons in `graphics/technology/`, for this
mod. They have the same licence as the mod.
