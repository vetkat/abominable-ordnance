"""Print one Factorio API entry in a few lines.

An agent reads this short entry and skips the whole library file.

    make api NAME=LuaSurface.create_entity
    python3 -m tools.api on_entity_died

A name can be a class, a class member, an event, a concept, a define, a
prototype, a prototype property or a prototype type. An unknown name
gives the closest names.
"""
from __future__ import annotations

import difflib
import json
import pathlib
import sys

API = pathlib.Path(__file__).resolve().parents[1] / ".factorio-api"
SUMMARY = 240


def summary(text: str | None) -> str:
    first = (text or "").strip().split("\n\n")[0].replace("\n", " ")
    return first if len(first) <= SUMMARY else first[:SUMMARY - 3] + "..."


def render(kind: object) -> str:
    if isinstance(kind, str):
        return kind
    if not isinstance(kind, dict):
        return "?"
    name = kind.get("complex_type")
    if name == "union":
        return " | ".join(render(option) for option in kind.get("options", []))
    if name == "array":
        return render(kind.get("value")) + "[]"
    if name in ("dictionary", "LuaCustomTable"):
        return f"{name}<{render(kind.get('key'))}, {render(kind.get('value'))}>"
    if name == "literal":
        return json.dumps(kind.get("value"))
    if name == "type":
        return render(kind.get("value"))
    if name in ("table", "tuple"):
        return "{" + ", ".join(field(item) for item in kind.get("parameters", [])) + "}"
    return str(name)


def field(item: dict) -> str:
    mark = "?" if item.get("optional") else ""
    return f"{item.get('name')}{mark}: {render(item.get('type'))}"


def method(owner: str, item: dict) -> str:
    params = ", ".join(field(p) for p in item.get("parameters", []))
    table = (item.get("format") or {}).get("takes_table")
    call = f"{owner}.{item['name']}" + ("{" + params + "}" if table else f"({params})")
    returns = [render(r.get("type")) + ("?" if r.get("optional") else "")
               for r in item.get("return_values", [])]
    lines = [call + (" -> " + ", ".join(returns) if returns else ""),
             summary(item.get("description"))]
    lines += [f"  {group['name']}: " + ", ".join(field(p) for p in group.get("parameters", []))
              for group in item.get("variant_parameter_groups", [])]
    raises = [event["name"] for event in item.get("raises", [])]
    return "\n".join(lines + (["raises: " + ", ".join(raises)] if raises else []))


def attribute(owner: str, item: dict) -> str:
    access = ("R" if "read_type" in item else "") + ("W" if "write_type" in item else "")
    kind = render(item.get("read_type", item.get("write_type")))
    return f"{owner}.{item['name']}: {kind} [{access}]\n{summary(item.get('description'))}"


def names(items: list[dict]) -> str:
    return ", ".join(item["name"] for item in items)


def klass(item: dict) -> str:
    return "\n".join([f"class {item['name']}", summary(item.get("description")),
                      "methods: " + names(item.get("methods", [])),
                      "attributes: " + names(item.get("attributes", []))])


def prototype(item: dict) -> str:
    return "\n".join([f"prototype {item['name']} (type \"{item.get('typename')}\", "
                      f"parent {item.get('parent')})", summary(item.get("description")),
                      "properties: " + names(item.get("properties") or [])])


def prop(owner: str, item: dict) -> str:
    default = f" (default: {item['default']})" if "default" in item else ""
    return f"{owner}.{field(item)}{default}\n{summary(item.get('description'))}"


def entries(runtime: dict, proto: dict) -> dict[str, str]:
    """Map every name an agent can ask for to its text."""
    found: dict[str, str] = {}  # built here, so filling it in place is safe
    for item in runtime.get("classes", []):
        found[item["name"]] = klass(item)
        for member in item.get("methods", []):
            found[f"{item['name']}.{member['name']}"] = method(item["name"], member)
        for member in item.get("attributes", []):
            found[f"{item['name']}.{member['name']}"] = attribute(item["name"], member)
    for item in runtime.get("events", []):
        found[item["name"]] = "\n".join(
            [f"event {item['name']}", summary(item.get("description"))]
            + ["  " + field(data) for data in item.get("data", [])])
    for item in runtime.get("concepts", []) + proto.get("types", []):
        found[item["name"]] = (f"{item['name']} = {render(item.get('type'))}\n"
                               + summary(item.get("description")))
        for member in item.get("properties") or []:
            found[f"{item['name']}.{member['name']}"] = prop(item["name"], member)
    for item in runtime.get("defines", []):
        found[f"defines.{item['name']}"] = (f"defines.{item['name']}: "
                                            + names(item.get("values", [])))
    own: dict[str, dict[str, str]] = {}  # built here, so filling it in place is safe
    for item in proto.get("prototypes", []):
        found[item["name"]] = prototype(item)
        own[item["name"]] = {member["name"]: prop(item["name"], member)
                             for member in item.get("properties") or []}
        for key, text in own[item["name"]].items():
            found[f"{item['name']}.{key}"] = text
    parents = {item["name"]: item.get("parent") for item in proto.get("prototypes", [])}
    return {**inherited(own, parents), **found}


def inherited(own: dict[str, dict[str, str]], parents: dict[str, str | None]) -> dict[str, str]:
    """Give each prototype the properties of its parents, nearest first."""
    found: dict[str, str] = {}  # built here, so filling it in place is safe
    for child in parents:
        seen = {child}
        parent = parents[child]
        while parent in own and parent not in seen:  # a loop in the data ends here
            seen.add(parent)
            for key, text in own[parent].items():
                found.setdefault(f"{child}.{key}", f"{text}\n(inherited by {child})")
            parent = parents[parent]
    return found


def lookup(runtime: dict, proto: dict, query: str) -> str:
    found = entries(runtime, proto)
    if query in found:
        return found[query]
    close = difflib.get_close_matches(query, found.keys(), n=8, cutoff=0.6)
    return f"no match for {query}" + ("; close: " + ", ".join(close) if close else "")


def main(argv: list[str], folder: pathlib.Path = API) -> int:
    if len(argv) != 1:
        print("usage: python3 -m tools.api NAME", file=sys.stderr)
        return 2
    try:
        runtime = json.loads((folder / "runtime-api.json").read_text(encoding="utf-8"))
        proto = json.loads((folder / "prototype-api.json").read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        print(f"api: cannot read {folder}: {error}. Run `make lua` once to "
              "download it.", file=sys.stderr)
        return 1
    print(lookup(runtime, proto, argv[0]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
