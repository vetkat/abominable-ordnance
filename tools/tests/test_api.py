import json
import os
import pathlib
import subprocess

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
    assert 'type "unit"' in text and "EntityWithOwnerPrototype" in text
    assert "movement_speed" in text


def test_a_prototype_property_shows_type_and_default():
    text = find("UnitPrototype.dying_trigger_effect")
    assert "dying_trigger_effect?: TriggerEffect" in text
    assert "default: none" in text


def test_a_prototype_type_renders_dictionary():
    assert "TriggerEffect = dictionary<string, double>" in find("TriggerEffect")


def test_an_unknown_name_suggests_close_matches():
    text = find("LuaSurface.create_entty")
    assert "no match" in text and "close: " in text and "LuaSurface.create_entity" in text


def test_an_unknown_name_with_nothing_close_says_so():
    text = find("zzzzqqq")
    assert "no match" in text and "close:" not in text


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


def lookup_in(proto, query, runtime=None):
    return api.lookup(runtime or {}, proto, query)


def test_a_parent_loop_in_the_data_ends():
    proto = {"prototypes": [
        {"name": "A", "parent": "B", "properties": [{"name": "p", "type": "x"}]},
        {"name": "B", "parent": "A", "properties": [{"name": "q", "type": "x"}]},
    ], "types": []}
    assert "inherited by A" in lookup_in(proto, "A.q")


def test_the_nearest_parent_wins():
    proto = {"prototypes": [
        {"name": "A", "parent": None, "properties": [
            {"name": "p", "type": "x", "description": "from A"}]},
        {"name": "B", "parent": "A", "properties": [
            {"name": "p", "type": "x", "description": "from B"}]},
        {"name": "C", "parent": "B", "properties": []},
    ], "types": []}
    text = lookup_in(proto, "C.p")
    assert "from B" in text and "from A" not in text


def test_an_own_property_beats_an_inherited_one():
    proto = {"prototypes": [
        {"name": "A", "parent": None, "properties": [
            {"name": "p", "type": "x", "description": "from A"}]},
        {"name": "B", "parent": "A", "properties": [
            {"name": "p", "type": "x", "description": "from B"}]},
    ], "types": []}
    text = lookup_in(proto, "B.p")
    assert "from B" in text and "inherited" not in text


def test_a_summary_ends_with_dots_at_exactly_the_cap():
    text = api.summary("x" * 1000)
    assert text.endswith("...") and len(text) == api.SUMMARY
    assert api.summary("y" * api.SUMMARY) == "y" * api.SUMMARY


def test_a_summary_joins_lines_with_a_space():
    assert api.summary("one\ntwo\n\nthree") == "one two"


def test_a_default_of_zero_is_shown():
    proto = {"prototypes": [{"name": "A", "parent": None, "properties": [
        {"name": "n", "type": "int", "default": 0}]}], "types": []}
    assert "default: 0" in lookup_in(proto, "A.n")


def test_a_write_only_attribute_shows_w():
    runtime = {"classes": [{"name": "C", "attributes": [
        {"name": "w", "write_type": "string"}]}]}
    assert "C.w: string [W]" in lookup_in({}, "C.w", runtime)


def test_main_with_two_names_prints_usage(tmp_path, capsys):
    assert api.main(["a", "b"], tmp_path) == 2
    assert "usage" in capsys.readouterr().err


def test_main_with_an_empty_name_prints_usage(tmp_path, capsys):
    assert api.main([" "], tmp_path) == 2
    assert "usage" in capsys.readouterr().err


def test_main_with_corrupt_json_says_how_to_get_it(tmp_path, capsys):
    (tmp_path / "runtime-api.json").write_text("{nope")
    (tmp_path / "prototype-api.json").write_text("{}")
    assert api.main(["ForceID"], tmp_path) == 1
    assert "make lua" in capsys.readouterr().err


def test_main_with_an_unknown_name_exits_one(tmp_path, capsys):
    (tmp_path / "runtime-api.json").write_text(json.dumps(RUNTIME))
    (tmp_path / "prototype-api.json").write_text(json.dumps(PROTOTYPE))
    assert api.main(["zzzzqqq"], tmp_path) == 1
    assert "no match" in capsys.readouterr().out


DEFINES = {"defines": [
    {"name": "events", "values": [{"name": "on_tick", "description": "Each tick."}]},
    {"name": "control_behavior", "subkeys": [
        {"name": "lamp", "subkeys": [
            {"name": "color_mode", "values": [{"name": "packed_rgb"}]}]}]},
    {"name": "big", "values": [{"name": f"v{n}"} for n in range(25)]},
]}


def test_a_define_value_is_found_with_its_description():
    text = find_in(DEFINES, "defines.events.on_tick")
    assert "defines.events.on_tick" in text and "Each tick." in text


def test_a_define_subkey_value_is_found():
    assert "packed_rgb" in find_in(DEFINES, "defines.control_behavior.lamp.color_mode")
    assert "defines.control_behavior.lamp.color_mode.packed_rgb" in find_in(
        DEFINES, "defines.control_behavior.lamp.color_mode.packed_rgb")
    assert "subkeys: lamp" in find_in(DEFINES, "defines.control_behavior")


def test_a_long_define_group_shows_a_count_and_the_first_twenty():
    text = find_in(DEFINES, "defines.big")
    assert "25 values" in text and "v19" in text and "v20" not in text
    assert text.splitlines()[0].endswith("...")


def find_in(runtime, query):
    return api.lookup(runtime, {}, query)


BOTH_RUNTIME = {"concepts": [{"name": "Color", "description": "Runtime colour.",
                              "type": "table"}]}
BOTH_PROTO = {"prototypes": [], "types": [{"name": "Color", "description": "Proto colour.",
                                           "type": "table"}]}


def test_a_runtime_concept_beats_a_prototype_type_of_the_same_name():
    text = api.lookup(BOTH_RUNTIME, BOTH_PROTO, "Color")
    assert "Runtime colour." in text and "[runtime]" in text
    assert "also a prototype type: prototype:Color" in text


def test_the_prototype_type_is_found_with_its_prefix():
    text = api.lookup(BOTH_RUNTIME, BOTH_PROTO, "prototype:Color")
    assert "Proto colour." in text and "[prototype]" in text


def test_a_name_in_one_stage_only_has_no_also_note():
    assert "also a" not in api.lookup(RUNTIME, PROTOTYPE, "ForceID")


def test_a_tuple_renders_its_values_in_square_brackets():
    kind = {"complex_type": "tuple", "values": ["double", "string", "LuaEntity"]}
    assert api.render(kind) == "[double, string, LuaEntity]"


def test_a_struct_does_not_render_as_a_bare_word():
    assert api.render({"complex_type": "struct"}) == "struct (see members)"


def test_a_table_with_nested_parameters_renders_them():
    inner = {"complex_type": "table", "parameters": [
        {"name": "x", "type": "double", "optional": False}]}
    outer = {"complex_type": "table", "parameters": [
        {"name": "pos", "type": inner, "optional": True}]}
    assert api.render(outer) == "{pos?: {x: double}}"


def test_an_unknown_type_renders_as_a_question_mark():
    assert api.render({}) == "?"
    assert api.render(None) == "?"


def test_a_prototype_is_found_by_its_type_string():
    assert "UnitPrototype" in find("unit")


def test_a_type_string_never_shadows_a_runtime_name():
    proto = {"prototypes": [{"name": "UnitPrototype", "typename": "LuaSurface",
                             "parent": None, "properties": []}], "types": []}
    assert "class LuaSurface" in api.lookup(RUNTIME, proto, "LuaSurface")


def test_a_name_matches_ignoring_case_and_a_trailing_dot():
    assert "LuaSurface.pollute(" in find("luasurface.POLLUTE.")


ROOT = pathlib.Path(__file__).resolve().parents[2]


def make_api(env_extra, *args):
    env = {k: v for k, v in os.environ.items() if k != "NAME"} | env_extra
    return subprocess.run(["make", "-s", "-o", ".factorio-api/stamp", "api", *args],
                          cwd=ROOT, capture_output=True, text=True, env=env)


def test_make_api_does_not_run_shell_code_in_the_name():
    payload = 'x"; echo PWNED; "'
    done = make_api({}, f"NAME={payload}")
    assert done.returncode in (0, 1, 2)
    assert "PWNED" not in done.stdout.splitlines()
    assert f"no match for {payload}" in done.stdout


def test_make_api_ignores_a_name_from_the_environment():
    done = make_api({"NAME": "myhost"})
    assert "usage" in done.stderr and "myhost" not in done.stdout + done.stderr


def test_make_api_takes_a_name_from_the_command_line():
    done = make_api({"NAME": "myhost"}, "NAME=defines.direction.north")
    assert "defines.direction.north" in done.stdout


def test_a_cycle_that_leaves_out_the_child_ends():
    proto = {"prototypes": [
        {"name": "A", "parent": "B", "properties": []},
        {"name": "B", "parent": "C", "properties": []},
        {"name": "C", "parent": "B", "properties": [{"name": "p", "type": "x"}]},
    ], "types": []}
    text = lookup_in(proto, "A.p")
    assert text.count("inherited") == 1 and "inherited by A" in text


def test_a_property_without_a_description_has_no_blank_last_line():
    proto = {"prototypes": [{"name": "A", "parent": None, "properties": [
        {"name": "n", "type": "int"}]}], "types": []}
    assert not lookup_in(proto, "A.n").endswith("\n")


def test_an_event_define_says_it_is_an_event():
    runtime = {"events": [{"name": "on_tick", "data": []}],
               "defines": [{"name": "events", "values": [{"name": "on_tick"}]}]}
    assert "(event on_tick)" in lookup_in({}, "defines.events.on_tick", runtime)


def test_a_miss_reports_the_query_as_asked_without_the_dot_or_spaces():
    assert "no match for zzzz" in find(" zzzz. ")
