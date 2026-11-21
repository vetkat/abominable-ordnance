# CMA Graphics (CC0 machine sprites)

Public-domain dieselpunk building graphics for Factorio 2.0 modders, made to sit naturally next to
the vanilla art. The machines are deliberately vague about what they do: give them a
name, a recipe category and stats in your own mod.

Every machine ships with an animated base sheet, an additive glow (emission) sheet, a shadow, an
idle frame, Space Age frozen patches where useful, icons (64 px + 512 px), and the exact sizes and
shifts, so you never have to measure a sprite.

## Machines

| machine | size | sets (`variant-direction`) | glow | notes |
|---|---|---|---|---|
| `diesel-generator` | 4x4 | single set | warm orange | V-engine, flywheel, exhaust stacks. No frozen patch. |
| `field-emitter` | 3x3 | `mk1..mk3` x `north/east/south/west` | **neutral white** (tintable) | Rotating coil head; tiers add horns, node ring, gyro rings. |
| `kinetic-turbine` | 3x5 | `mk1..mk3` x `north/east` | orange / cyan / violet | `north` = vertical, `east` = horizontal (generator orientations). Pipe flanges at the vanilla steam turbine's connections. |
| `process-reactor` | 3x3 | `mk1..mk3` x `north/east/south/west` | **neutral white** (tintable) | Crafting machine with a **recipe-tint layer** (`G.tint`: the liquid, use `apply_recipe_tint`). Fluid flanges at the vanilla chemical plant's connections. |
| `industrial-press` | 3x3 | `mk1..mk3` x `north/east/south/west` | **neutral white** (tintable) | Item crafter (assembling machine 2 base). **Recipe-tint layer** (`G.tint`): the workpiece on the bed. Crank press / hydraulic press with feed arm / field-forming gantry. |
| `arc-smelter` | 3x3 | `mk1..mk3` | orange melt | Furnace. Mk1 brick beehive with chimney (burner; smoke position in the showcase), Mk2 electrode arc furnace, Mk3 levitating melt. |
| `deep-extractor` | 3x3 | `mk1..mk3` x `north/east/south/west` | neutral white | Mining drill: output auger on the drop side (vanilla `vector_to_place_result`), fluid flanges at the vanilla inputs. **Resource-tint layer** (`G.tint`, the ore): use `apply_tint = "resource-color"`. |
| `pressure-tank` | 3x3 | `mk1..mk3` x `north/east` | cyan (Mk3) | Storage tank, static (1 frame; use the layers as Sprites). The sight glass is a transparent hole: set `window_bounding_box = {{-0.109, 0.609}, {0.109, 1.094}}` and the game's fluid level shows through. |
| `pump-station` | 1x2 | `mk1..mk3` x `north/east/south/west` | cyan (Mk3) | Pump (vanilla connections), impeller spinning on top. |
| `research-array` | 3x3 | `mk1..mk3` | neutral white | Lab (`on_animation = G.working`, `off_animation = G.idle`). |
| `capacitor-bank` | 2x2 | `mk1..mk3` | blue / green / violet | Accumulator, 24 frames: energy rises while charging; play the same sheets with `run_mode = "backward"` for discharge. |
| `crusher` | 2x2 | `mk1..mk3` | neutral white | Small item crafter. **Recipe-tint layer**: the feed. Jaw / roll / disc crusher. |
| `coal-kiln` | 2x2 | `mk1..mk3` | orange fire | Coal-age furnace: bottle kiln / brick vault kiln / gas kiln (chimney smoke positions in the showcase). |
| `inline-processor` | 3x5 | `mk1..mk3` x `north/east/south/west` | neutral white | Directional crafter: intake at the north end, output at the south end (+ fluid flanges at the assembler positions). **Recipe-tint layer**: the parts on the line. |
| `steam-boiler` | 3x2 | `mk1..mk3` x `north/east/south/west` | orange fire / cyan | Boiler (vanilla connections): use `G.base`+`G.shadow` as `structure`, `G.emission` as `fire_glow`. Pairs with the kinetic turbine. |
| `logistics-hub` | 4x4 | `mk1..mk3` | amber / cyan / violet | Roboport: `base` = idle frame (hatch open), `base_animation = G.emission`, door leaves = `G.tint` (16 frames open -> closed; use `run_mode = "backward"`). Charging pylons at the vanilla charging offsets. |
| `crane-inserter` | 1x1 | `mk1..mk3` x `north/east/south/west` (platform) | violet (Mk3) | Inserter: platform per direction (`MG(...).base`, 1 frame) + arm sprites `crane-inserter-<tier>-hand-{base,open,closed}[-shadow].png`, same layout and sizes as the vanilla fast inserter (`scale = 0.25`). |
| `signal-mast` | 3x3 | `mk1..mk3` | neutral white | Radar: 64 frames = one clockwise antenna turn, use as a `RotatedSprite` with `direction_count = 64` (shadow: `signal-mast-<tier>-hr-shadow64.png`). |
| `tesseract-compressor` | 3x3 | `mk1..mk3` | neutral white | Exotic item crafter. **Recipe-tint layer**: the hypercube rods, which turn inside out through themselves. Lab rig / production / perfected. |
| `singularity-press` | 5x5 | `mk1..mk3` | neutral white | Exotic flagship crafter: a black sphere in a lensing shell, held by four clamp arms. **Recipe-tint layer**: the spiral accretion disc. |
| `armillary-stabilizer` | 3x3 | `mk1..mk3` | neutral white | Exotic lab (or beacon/crafter): three nested gimbal rings tumbling round a perfectly still mote. Lab rig / production / perfected. |
| `containment-torus` | 5x5 | `mk1..mk3` | orange / cyan / violet | Exotic reactor (12 vanilla heat connections). Plasma knots race round a windowed torus; the motion is all in the light, so it suits the reactor's static picture plus animated working light. |
| `rift-tap` | 4x4 | `mk1..mk3` x 4 dirs | resource colour | Exotic mining drill: a tear in space between pylons, always facing the camera. **Resource-tint layer**: rim, swirl and the ore chunks flying into the chute. |
| `orbital-receiver` | 4x4 | `mk1..mk3` | neutral white | Exotic power source (electric-energy-interface showcase): a beam from orbit into a dish, beads riding down it. Tall sprite (the beam fades ~3 tiles up). |
| `matter-printer` | 4x4 | `mk1..mk3` | neutral white | Exotic item crafter: a light sheet rises through a turning hologram, leaving a solid print below it. **Recipe-tint layer**: hologram + print. 48 frames. |
| `neural-vat` | 3x3 | `mk1..mk3` | neutral white | Exotic crafter (or lab): pulses running through a glowing filament tree in a vat of murky fluid. **Recipe-tint layer**: the fluid. |

Animations are seamless loops (32 frames unless noted above), 8 frames per row, rendered at 64 px/tile ("hr", `scale = 0.5`).

## Using the assets from your mod

`info.json`:
```json
"dependencies": ["base >= 2.0", "cma-graphics >= 0.1.0"]
```
Then, in your data stage:
```lua
local MG = require("__cma-graphics__/lib/machine_graphics")
local G = MG("field-emitter", {variant = "mk2", direction = "east", animation_speed = 0.5})

-- G.working  base + emission + shadow (layered Animation)
-- G.idle     first frame + shadow, same frame count (burner-generator & co. require that)
-- G.base, G.emission, G.shadow, G.idle_base   individual layers
-- G.frozen   frozen_patch Sprite (nil if the set has none)
-- G.tint     recipe-tint layer (greyscale liquid etc.; nil if the machine has none)
-- G.icon, G.icon_big   icon paths (64 / 512 px)
```
Examples:
```lua
-- a rotatable crafting machine on the field-emitter art, glow tinted by the recipe
local A, F = {}, {}
for _, d in pairs({"north", "east", "south", "west"}) do
  local g = MG("field-emitter", {variant = "mk1", direction = d})
  A[d] = {layers = {g.base, g.shadow}}
  F[d] = g.frozen
end
my_machine.graphics_set = {
  animation = A,                              -- Animation4Way
  frozen_patch = F,                           -- Sprite4Way
  working_visualisations = {{
    fadeout = true, apply_recipe_tint = "primary",
    north_animation = MG("field-emitter", {variant = "mk1", direction = "north"}).emission,
    east_animation  = MG("field-emitter", {variant = "mk1", direction = "east"}).emission,
    south_animation = MG("field-emitter", {variant = "mk1", direction = "south"}).emission,
    west_animation  = MG("field-emitter", {variant = "mk1", direction = "west"}).emission,
  }},
}

-- a generator on the turbine art
local V = MG("kinetic-turbine", {variant = "mk3", direction = "north"})
local H = MG("kinetic-turbine", {variant = "mk3", direction = "east"})
my_generator.vertical_animation, my_generator.horizontal_animation = V.working, H.working
my_generator.vertical_frozen_patch, my_generator.horizontal_frozen_patch = V.frozen, H.frozen
```
**Other sizes:** `MG(name, {scale = 0.5 * 2 / 3})` squeezes a 3x3 machine onto a 2x2 footprint
(shifts are scaled too). Going smaller stays crisp; going much larger gets soft.

Raw files, if you'd rather wire them up yourself:
`graphics/entity/<machine>/<machine>[-<variant>-<direction>]-hr-{animation,emission,idle,shadow,frozen}.png`,
with sizes and shifts in `lib/sprites/<machine>.lua`.

## Showcase

With the startup setting **Showcase machines** turned on (it's off by default), the mod adds working examples
of every machine to a **Machine assets** crafting tab. They have free recipes and are available
from the start, so you can try them right away:
- diesel generator: burns chemical fuel;
- Field Emitter Mk1–3: beacons with 1/2/3 module slots and module-tinted glow;
- Kinetic Turbine Mk1–3: about 10/25/60 MW from 500 °C steam, an upgrade chain over the vanilla steam turbine footprint.
- Process Reactor Mk1–3: chemical plants with crafting speed 1/2/4; the liquid shows the recipe's colour.
- Industrial Press, Crusher, Inline Processor Mk1–3: item crafters (the workpiece takes the recipe colour).
- Arc Smelter, Coal Kiln Mk1–3: furnaces (Mk1 smelter and all kilns burn fuel).
- Deep Extractor Mk1–3: mining drills (the ore takes the resource colour).
- Pressure Tank, Pump Station Mk1–3; Steam Boiler Mk1–3 (feeds the turbines).
- Research Array (labs), Capacitor Bank (accumulators), Logistics Hub (roboports), Signal Mast (radars), Crane Inserter (inserters), Mk1–3 each.
- Exotic row, Mk1–3 each:
  - item crafters: Tesseract Compressor, Singularity Press, Matter Printer, Neural Vat;
  - Armillary Stabilizer (lab);
  - Containment Torus (reactor that burns uranium fuel cells, heat out on all sides);
  - Rift Tap (mining drill whose rift glows in the resource's colour);
  - Orbital Receiver (a free power source: an electric energy interface).

Their balance is a sketch, not a design. With the setting off (the default), the mod only provides the graphics library.
Showcase entity names are prefixed `cma-` so they won't clash with yours.

## License

**CC0 1.0 Universal** (see `LICENSE`): no rights reserved. Use, modify and redistribute the
graphics and code for anything, commercial or not, with no attribution required (credit is
appreciated, though). The textures used while rendering are CC0 Poly Haven assets. Everything else
(models, materials, renders, code) is original to this pack.

Made by trentmkelly & Claude. The models are procedural Blender scripts, rendered with Cycles.
