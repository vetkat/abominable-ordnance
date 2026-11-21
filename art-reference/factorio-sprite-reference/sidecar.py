"""Parse the .lua sidecar that Factorio ships next to a sprite sheet."""
import re

NUMBER = r"\b{}\s*=\s*(\d+)"
SHIFT = r"by_pixel\(\s*([-\d.]+)\s*,\s*([-\d.]+)"


def parse(text):
    """width, height, line_length and shift, or None without a size."""
    found = {k: int(m.group(1)) for k in ("width", "height", "line_length")
             if (m := re.search(NUMBER.format(k), text))}
    if "width" not in found or "height" not in found:
        return None
    shift = re.search(SHIFT, text)
    found["shift"] = tuple(float(v) for v in shift.groups()) if shift else (0.0, 0.0)
    return found
