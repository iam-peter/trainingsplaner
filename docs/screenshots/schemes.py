"""week-schemes.png: the week in the light, dark and classic schemes,
cut diagonally into three strips, from take_screenshots.qml's shots."""
from pathlib import Path

from PIL import Image, ImageDraw

here = Path(__file__).parent
light = Image.open(here / "week.png").convert("RGB")
dark = Image.open(here / "week-dark.png").convert("RGB")
classic = Image.open(here / "week-classic.png").convert("RGB")
W, H = light.size


def band(x0top, x0bot, x1top, x1bot):
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).polygon([(x0top, 0), (x1top, 0), (x1bot, H), (x0bot, H)], fill=255)
    return mask


out = light.copy()
out.paste(dark, (0, 0), band(524, 386, 978, 840))
out.paste(classic, (0, 0), band(978, 840, W + 400, W + 400))
out.save(here / "week-schemes.png")
for name in ("week-dark.png", "week-classic.png"):
    (here / name).unlink()
