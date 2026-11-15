import json

from tools import api

RUNTIME = {
    "classes": [{
        "name": "LuaSurface",
        "description": "A surface. Long text follows here.",
        "methods": [{
            "name": "create_entity",
            "description": "Create an entity on this surface.\n\nMore text.",
            "format": {"takes_table": True},
            "parameters": [
                {"name": "name", "type": "EntityID", "optional": False},
                {"name": "force", "type": {"complex_type": "union",
                                           "options": ["LuaForce", "string"]},
                 "optional": True},
            ],
            "variant_parameter_groups": [{
                "name": "item-entity",
                "parameters": [{"name": "stack", "type": "ItemStackIdentification",
                                "optional": False}],
            }],
            "return_values": [{"type": "LuaEntity", "optional": True}],
            "raises": [{"name": "script_raised_built"}],
        }, {
            "name": "pollute",
            "description": "Add pollution.",
            "format": {"takes_table": False},
            "parameters": [{"name": "amount", "type": "double", "optional": False}],
        }],
        "attributes": [{
            "name": "always_day",
            "description": "Sun always shines.",
            "read_type": "boolean",
            "write_type": "boolean",
            "optional": False,
        }, {
            "name": "index",
            "description": "Unique ID.",
            "read_type": "uint32",
            "optional": False,
        }],
    }],
    "events": [{
        "name": "on_entity_died",
        "description": "Called when an entity dies.",
        "data": [{"name": "entity", "type": "LuaEntity", "optional": False},
                 {"name": "cause", "type": "LuaEntity", "optional": True}],
    }],
    "concepts": [{
        "name": "ForceID",
        "description": "A force.",
        "type": {"complex_type": "union",
                 "options": ["LuaForce", {"complex_type": "array", "value": "string"}]},
    }],
    "defines": [{
        "name": "direction",
        "description": "",
        "values": [{"name": "north"}, {"name": "east"}],
    }],
}

PROTOTYPE = {
    "prototypes": [{
        "name": "UnitPrototype",
        "typename": "unit",
        "parent": "EntityWithOwnerPrototype",
        "description": "Entity that moves around and attacks players.",
        "properties": [{
            "name": "movement_speed",
            "description": "Movement speed of the unit in tiles per tick.",
            "type": "float",
            "optional": False,
        }, {
            "name": "dying_trigger_effect",
            "description": "Effect when it dies.",
            "type": "TriggerEffect",
            "optional": True,
            "default": "none",
        }],
    }],
    "types": [{
        "name": "TriggerEffect",
        "description": "Loaded as one or many.",
        "type": {"complex_type": "dictionary", "key": "string", "value": "double"},
        "properties": None,
    }],
}


def find(query):
    return api.lookup(RUNTIME, PROTOTYPE, query)


def test_a_method_shows_its_table_parameters_and_return():
    text = find("LuaSurface.create_entity")
    assert "LuaSurface.create_entity{" in text
    assert "name: EntityID" in text
    assert "force?: LuaForce | string" in text
    assert "-> LuaEntity?" in text
    assert "Create an entity on this surface." in text
    assert "More text." not in text


def test_a_method_lists_its_variant_groups_and_events():
    text = find("LuaSurface.create_entity")
    assert "item-entity: stack: ItemStackIdentification" in text
    assert "raises: script_raised_built" in text


def test_a_positional_method_uses_round_brackets():
    assert "LuaSurface.pollute(amount: double)" in find("LuaSurface.pollute")


def test_an_attribute_shows_type_and_access():
    assert "LuaSurface.always_day: boolean [RW]" in find("LuaSurface.always_day")
    assert "LuaSurface.index: uint32 [R]" in find("LuaSurface.index")


def test_a_class_lists_member_names_only():
    text = find("LuaSurface")
    assert "create_entity" in text and "always_day" in text
    assert "Create an entity" not in text


def test_an_event_lists_its_fields():
    text = find("on_entity_died")
    assert "entity: LuaEntity" in text and "cause?: LuaEntity" in text


def test_a_concept_renders_nested_types():
    assert "ForceID = LuaForce | string[]" in find("ForceID")


def test_a_define_lists_its_values():
    text = find("defines.direction")
    assert "north" in text and "east" in text


def test_a_prototype_shows_typename_parent_and_properties():
    text = find("UnitPrototype")
    assert "unit" in text and "EntityWithOwnerPrototype" in text
    assert "movement_speed" in text


def test_a_prototype_property_shows_type_and_default():
    text = find("UnitPrototype.dying_trigger_effect")
    assert "dying_trigger_effect?: TriggerEffect" in text
    assert "default: none" in text


def test_a_prototype_type_renders_dictionary():
    assert "TriggerEffect = dictionary<string, double>" in find("TriggerEffect")


def test_an_unknown_name_suggests_close_matches():
    text = find("LuaSurface.create_entty")
    assert "no match" in text and "LuaSurface.create_entity" in text


def test_an_unknown_name_with_nothing_close_says_so():
    assert "no match" in find("zzzzqqq")


def test_a_long_description_is_cut():
    long_runtime = {**RUNTIME, "concepts": [{
        "name": "Big", "description": "x" * 1000, "type": "string"}]}
    assert len(api.lookup(long_runtime, PROTOTYPE, "Big")) < 400


def test_main_reads_the_files_and_prints(tmp_path, capsys):
    (tmp_path / "runtime-api.json").write_text(json.dumps(RUNTIME))
    (tmp_path / "prototype-api.json").write_text(json.dumps(PROTOTYPE))
    assert api.main(["ForceID"], tmp_path) == 0
    assert "ForceID" in capsys.readouterr().out


def test_main_without_a_name_prints_usage(tmp_path, capsys):
    assert api.main([], tmp_path) == 2
    assert "usage" in capsys.readouterr().err


def test_main_without_the_api_folder_says_how_to_get_it(tmp_path, capsys):
    assert api.main(["ForceID"], tmp_path / "missing") == 1
    assert "make lua" in capsys.readouterr().err


def test_a_prototype_property_is_found_on_a_parent():
    proto = {"prototypes": PROTOTYPE["prototypes"] + [{
        "name": "EntityWithOwnerPrototype", "typename": None, "parent": None,
        "properties": [{"name": "collision_box", "type": "BoundingBox",
                        "optional": True}],
    }], "types": []}
    text = api.lookup(RUNTIME, proto, "UnitPrototype.collision_box")
    assert "EntityWithOwnerPrototype.collision_box?: BoundingBox" in text
    assert "inherited by UnitPrototype" in text


def test_an_inherited_property_names_only_the_asking_prototype():
    proto = {"prototypes": [
        {"name": "A", "parent": None, "properties": [{"name": "p", "type": "x"}]},
        {"name": "B", "parent": "A", "properties": []},
        {"name": "C", "parent": "B", "properties": []},
    ], "types": []}
    text = api.lookup({}, proto, "C.p")
    assert text.count("inherited") == 1 and "inherited by C" in text
