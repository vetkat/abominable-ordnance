"""Print one Factorio API entry in a few lines.

An agent reads this short entry and skips the whole library file.

    make api NAME=LuaSurface.create_entity
    python3 -m tools.api on_entity_died

A name can be a class, a class member, an event, a concept, a define, a
prototype, a prototype property or a prototype type. A name that exists
in both stages gives the runtime entry. Ask for the prototype one as
prototype:<name>. An unknown name gives the closest names and exit 1.
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
    if name == "table":
        return "{" + ", ".join(field(item) for item in kind.get("parameters", [])) + "}"
    if name == "tuple":
        return "[" + ", ".join(render(item) for item in kind.get("values", [])) + "]"
    if name == "struct":
        return "struct (see members)"
    if name == "LuaStruct":
        return "struct {" + ", ".join(a["name"] for a in kind.get("attributes", [])) + "}"
    return str(name) if name else "?"


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


def label(stage: str, found: dict[str, str]) -> dict[str, str]:
    return {key: f"[{stage}] {text}" for key, text in found.items()}


def limited(items: list[dict], cap: int = 20) -> str:
    """Name the items, and only the first few of a long list."""
    if len(items) <= cap:
        return names(items)
    return f"{len(items)} values: " + ", ".join(i["name"] for i in items[:cap]) + ", ..."


def defines(items: list[dict], prefix: str = "defines") -> dict[str, str]:
    """Index every define group, subgroup and value by its dotted name."""
    found: dict[str, str] = {}
    for item in items:
        key = f"{prefix}.{item['name']}"
        values, subkeys = item.get("values") or [], item.get("subkeys") or []
        lines = [f"{key}: " + limited(values) if values else key,
                 summary(item.get("description"))]
        if subkeys:
            lines.append("subkeys: " + names(subkeys))
        found[key] = "\n".join(line for line in lines if line)
        for value in values:
            found[f"{key}.{value['name']}"] = "\n".join(
                line for line in (f"{key}.{value['name']}", summary(value.get("description")))
                if line)
        found.update(defines(subkeys, key))
    return found


def runtime_entries(runtime: dict) -> dict[str, str]:
    found: dict[str, str] = {}
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
    for item in runtime.get("concepts", []):
        found[item["name"]] = (f"{item['name']} = {render(item.get('type'))}\n"
                               + summary(item.get("description")))
        for member in item.get("properties") or []:
            found[f"{item['name']}.{member['name']}"] = prop(item["name"], member)
    found.update(defines(runtime.get("defines", [])))
    return found


def prototype_entries(proto: dict) -> dict[str, str]:
    found: dict[str, str] = {}
    own: dict[str, dict[str, str]] = {}
    parents: dict[str, str | None] = {}
    for item in proto.get("types", []):
        found[item["name"]] = (f"{item['name']} = {render(item.get('type'))}\n"
                               + summary(item.get("description")))
        for member in item.get("properties") or []:
            found[f"{item['name']}.{member['name']}"] = prop(item["name"], member)
    for item in proto.get("prototypes", []):
        found[item["name"]] = prototype(item)
        parents[item["name"]] = item.get("parent")
        own[item["name"]] = {member["name"]: prop(item["name"], member)
                             for member in item.get("properties") or []}
        for key, text in own[item["name"]].items():
            found[f"{item['name']}.{key}"] = text
    return {**inherited(own, parents), **found}


def entries(runtime: dict, proto: dict) -> dict[str, str]:
    """Map every name an agent can ask for to its text.

    A runtime name beats a prototype name of the same name. The prototype
    one stays reachable as prototype:<name>.
    """
    prototypes = label("prototype", prototype_entries(proto))
    runtimes = label("runtime", runtime_entries(runtime))
    found = {**prototypes, **{
        key: text + (f"\n(also a prototype type: prototype:{key})" if key in prototypes else "")
        for key, text in runtimes.items()}}
    for item in proto.get("prototypes", []):
        if item.get("typename"):
            found.setdefault(item["typename"], prototypes[item["name"]])
    return {**{f"prototype:{key}": text for key, text in prototypes.items()}, **found}


def inherited(own: dict[str, dict[str, str]], parents: dict[str, str | None]) -> dict[str, str]:
    """Give each prototype the properties of its parents, nearest first."""
    found: dict[str, str] = {}
    for child in parents:
        seen = {child}
        parent = parents[child]
        while parent in own and parent not in seen:  # a loop in the data ends here
            seen.add(parent)
            for key, text in own[parent].items():
                found.setdefault(f"{child}.{key}", f"{text}\n(inherited by {child})")
            parent = parents[parent]
    return found


def resolve(found: dict[str, str], query: str) -> str | None:
    """The text for a name, ignoring case and a trailing dot, or None."""
    query = query.strip().rstrip(".")
    if query in found:
        return found[query]
    folded: dict[str, str] = {}
    for key in found:
        folded.setdefault(key.lower(), key)
    return found[folded[query.lower()]] if query.lower() in folded else None


def miss(found: dict[str, str], query: str) -> str:
    close = difflib.get_close_matches(query.strip(), found.keys(), n=8, cutoff=0.6)
    return f"no match for {query}" + ("; close: " + ", ".join(close) if close else "")


def lookup(runtime: dict, proto: dict, query: str) -> str:
    found = entries(runtime, proto)
    text = resolve(found, query)
    return miss(found, query) if text is None else text


def main(argv: list[str], folder: pathlib.Path = API) -> int:
    if len(argv) != 1 or not argv[0].strip():
        print("usage: python3 -m tools.api NAME", file=sys.stderr)
        return 2
    try:
        runtime = json.loads((folder / "runtime-api.json").read_text(encoding="utf-8"))
        proto = json.loads((folder / "prototype-api.json").read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        print(f"api: cannot read {folder}: {error}. Run `make lua` once to "
              "download it.", file=sys.stderr)
        return 1
    found = entries(runtime, proto)
    text = resolve(found, argv[0])
    print(miss(found, argv[0]) if text is None else text)
    return 0 if text is not None else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
