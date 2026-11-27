# Art brief: the last pieces for release 1.0.0

Release 1.0.0 waits for six pieces of art. The play test of 2026-11-27
found four of them. Make them in the style of the v1 icons: grimy
Blender renders, gunmetal grey and rust, lit from the top left. The
scripts in `scripts/` made the v1 icons, and `README.md` says how to run
them.

| Piece | File | Size | Notes |
| --- | --- | --- | --- |
| Monster chow | `graphics/icons/monster-chow.png` | 64 × 64 | Feed for biters, made from coal, sulfur and water. Brown, lumpy and organic. |
| Spitter chow | `graphics/icons/spitter-chow.png` | 64 × 64 | Monster chow soaked in sulfuric acid. Same shape, a sickly yellow-green. |
| Larva targeting remote | `graphics/icons/larva-targeting-remote.png` | 64 × 64 | A hand-held remote in the rocket's gunmetal grey, with an orange band. It must not look like the vanilla artillery remote. |
| Larva flare | `graphics/icons/larva-flare.png` | 64 × 64 | The icon of the flare that the remote throws. The flare in the world keeps the vanilla picture. |
| Breeding pod rubble | `graphics/entity/breeding-pod/pathogen-lab-remnants.png` | 384 × 384, one frame | The wreck of the pod, seen from the game camera. It covers about 5 × 5 tiles at scale 0.5. |
| Incubator rubble | `graphics/entity/incubator/oxidizer-remnants.png` | 320 × 320, one frame | The wreck of the incubator, about 4 × 4 tiles at scale 0.5. |

Every file is a PNG with a transparent background. The rubble may carry
its own shadow, because Factorio draws remnants as one picture.

The rubble may start from a frame of the building's own art (CC BY 4.0,
Hurricane046). Then `THIRD_PARTY.md` must name it as a change of that
art.

When the files exist, the code side is small. The four items get their
icons. The pod and the incubator each get a corpse prototype, like the
loading chamber's.
