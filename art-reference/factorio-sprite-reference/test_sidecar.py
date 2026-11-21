import sidecar as S

VANILLA = """return
{
  width = 398,
  height = 310,
  shift = util.by_pixel( -1.0, -5.0),
  line_length = 8,
}
"""


def test_reads_size_shift_and_line_length():
    assert S.parse(VANILLA) == {"width": 398, "height": 310, "line_length": 8,
                                "shift": (-1.0, -5.0)}


def test_missing_shift_is_zero_and_missing_size_is_none():
    assert S.parse("return { width = 4, height = 2 }")["shift"] == (0.0, 0.0)
    assert S.parse("return {}") is None
