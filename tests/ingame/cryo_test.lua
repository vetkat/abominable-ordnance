local Names = require("core.names")
local Stasis = require("core.prototypes.stasis")

tags("space-age")
test("the cryo ward, its warded items, recipes and research exist", function()
  assert(prototypes.item[Names.CRYO_WARD], Names.CRYO_WARD)
  assert(prototypes.recipe[Names.CRYO_WARD], "recipe " .. Names.CRYO_WARD)
  assert(prototypes.technology[Names.CRYO_TECH], Names.CRYO_TECH)
  for _, name in ipairs(Stasis.lifecycle_names()) do
    assert(prototypes.item[Stasis.warded_name(Stasis.CRYO, name)], name)
    assert(prototypes.recipe[Stasis.pack_recipe(Stasis.CRYO, name)], name)
    assert(prototypes.recipe[Stasis.unpack_recipe(Stasis.CRYO, name)], name)
  end
end)

tags("base")
test("without Space Age there is no cryo ward", function()
  assert(not prototypes.item[Names.CRYO_WARD], "the cryo ward exists")
  assert(not prototypes.technology[Names.CRYO_TECH], "the cryo research exists")
  assert(prototypes.item[Names.WARD], "the base ward is missing")
end)
