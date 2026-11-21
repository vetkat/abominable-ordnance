from PIL import Image

import pack_sheets as P

PLAN = {
    "name": "pod", "tiles": [1, 1], "headroom_px": 0, "pitch_deg": 45,
    "frame_count": 2, "direction_count": 2, "line_length": 4,
    "layers": ["main", "shadow"],
}


def solid(colour):
    return Image.new("RGBA", (64, 64), colour)


def fake_cells(layer, direction, frame):
    # A different colour for each cell, so a test can find it in the sheet.
    return solid(((layer == "shadow") * 200, direction * 100, frame * 100, 255))


def test_pack_names_files_and_places_cells():
    files, err = P.pack(PLAN, fake_cells)
    assert err is None
    assert sorted(files) == ["pod-shadow.lua", "pod-shadow.png", "pod.lua", "pod.png"]
    sheet = files["pod.png"]
    assert sheet.size == (256, 64)
    # Cell order: d0f0, d0f1, d1f0, d1f1.
    assert sheet.getpixel((64 + 5, 5)) == (0, 0, 100, 255)
    assert sheet.getpixel((128 + 5, 5)) == (0, 100, 0, 255)
    assert "line_length = 4" in files["pod.lua"]


def test_pack_returns_the_layout_error():
    plan = {**PLAN, "line_length": 0}
    assert P.pack(plan, fake_cells) == (None, "line_length must be 1 or more")


def test_icon_strip_has_four_mipmaps():
    strip = P.icon_strip(solid((9, 9, 9, 255)), 64, 4)
    assert strip.size == (120, 64)
    assert strip.getpixel((112, 0)) == (9, 9, 9, 255)


def test_square_icon_crops_to_the_picture_and_centres_it():
    img = Image.new("RGBA", (100, 50), (0, 0, 0, 0))
    img.paste((255, 0, 0, 255), (10, 10, 50, 30))  # a 40 x 20 box
    icon = P.square_icon(img)
    assert icon.size == (40, 40)
    assert icon.getpixel((20, 9)) == (0, 0, 0, 0)
    assert icon.getpixel((20, 10)) == (255, 0, 0, 255)


def test_square_icon_of_an_empty_frame_is_empty():
    assert P.square_icon(Image.new("RGBA", (8, 4))).size == (1, 1)
