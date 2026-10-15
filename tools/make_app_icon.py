#!/usr/bin/env python3
"""Generate the final, opaque 1024px Polyroom iOS icon and asset-catalog copy."""
from pathlib import Path
import shutil

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SIZE = 1024
SCALE = 4
HI = SIZE * SCALE
BACKGROUND = (243, 237, 228)
INK = (105, 73, 54)


def pt(x, y):
    return (round(x * SCALE), round(y * SCALE))


def polygon(draw, points, fill, outline=INK, width=7):
    coords = [pt(x, y) for x, y in points]
    draw.polygon(coords, fill=fill)
    if outline:
        draw.line(coords + [coords[0]], fill=outline, width=width * SCALE, joint="curve")


def line(draw, points, fill=INK, width=7):
    draw.line([pt(x, y) for x, y in points], fill=fill, width=width * SCALE, joint="curve")


def ellipse(draw, box, fill, outline=None, width=4):
    scaled = tuple(round(v * SCALE) for v in box)
    draw.ellipse(scaled, fill=fill, outline=outline, width=width * SCALE)


def draw_icon():
    # Warm radial-like background with a large light disc, then a tiny isometric room.
    image = Image.new("RGB", (HI, HI), BACKGROUND)
    shadow = Image.new("RGBA", (HI, HI), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    ellipse(shadow_draw, (126, 112, 898, 900), (255, 250, 241, 255))
    image = Image.alpha_composite(image.convert("RGBA"), shadow).convert("RGB")
    draw = ImageDraw.Draw(image)

    # Room shell: two warm walls and a pale timber floor.
    apex_top = (512, 205)
    apex_floor = (512, 514)
    left_top, right_top = (180, 392), (844, 392)
    left_floor, right_floor, front_floor = (180, 700), (844, 700), (512, 885)
    polygon(draw, [left_top, apex_top, apex_floor, left_floor], (252, 247, 238), width=8)
    polygon(draw, [apex_top, right_top, right_floor, apex_floor], (235, 223, 206), width=8)
    polygon(draw, [left_floor, apex_floor, right_floor, front_floor], (218, 193, 164), width=8)

    # A quiet window on the left wall.
    polygon(draw, [(252, 423), (344, 371), (344, 490), (252, 542)], (170, 203, 213), width=6)
    line(draw, [(298, 397), (298, 516)], (250, 247, 238), 8)
    line(draw, [(252, 482), (344, 430)], (250, 247, 238), 8)

    # Bed frame and mattress, built from clean low-poly planes.
    polygon(draw, [(275, 629), (428, 543), (638, 644), (482, 744)], (129, 91, 66), width=6)
    polygon(draw, [(482, 744), (638, 644), (638, 685), (482, 788)], (119, 79, 58), width=6)
    polygon(draw, [(275, 629), (482, 744), (482, 788), (275, 670)], (158, 111, 78), width=6)
    polygon(draw, [(292, 610), (428, 534), (620, 626), (480, 705)], (250, 246, 237), width=6)

    # Sage pillows at the head of the bed.
    polygon(draw, [(325, 600), (382, 568), (444, 599), (386, 632)], (221, 231, 214), width=5)
    polygon(draw, [(387, 630), (444, 599), (504, 628), (447, 662)], (203, 218, 198), width=5)

    # Terracotta quilt, leaving the pillows visible.
    polygon(draw, [(300, 639), (431, 566), (595, 647), (461, 721)], (196, 123, 93), width=5)
    line(draw, [(330, 649), (461, 722)], (224, 157, 125), 5)
    line(draw, [(376, 624), (506, 689)], (224, 157, 125), 5)

    # Small nightstand on the right, with a single drawer and a potted plant.
    polygon(draw, [(630, 700), (706, 657), (779, 692), (704, 735)], (161, 112, 78), width=5)
    polygon(draw, [(630, 700), (704, 735), (704, 786), (630, 750)], (138, 94, 67), width=5)
    polygon(draw, [(704, 735), (779, 692), (779, 743), (704, 786)], (119, 81, 60), width=5)
    polygon(draw, [(646, 699), (706, 666), (762, 693), (704, 726)], (221, 181, 139), width=4)
    ellipse(draw, (704, 700, 715, 711), (103, 72, 54))

    # Pot and three leaves; simple enough to read at small icon sizes.
    polygon(draw, [(721, 676), (752, 659), (779, 672), (748, 690)], (184, 115, 83), width=4)
    polygon(draw, [(721, 676), (748, 690), (748, 718), (721, 703)], (158, 91, 67), width=4)
    polygon(draw, [(748, 690), (779, 672), (779, 699), (748, 718)], (138, 78, 59), width=4)
    line(draw, [(750, 672), (748, 625)], (87, 119, 82), 6)
    ellipse(draw, (714, 617, 753, 646), (121, 155, 111))
    ellipse(draw, (744, 602, 784, 631), (143, 173, 127))
    ellipse(draw, (756, 630, 791, 657), (99, 139, 93))

    # Downsample with antialiasing; keep RGB and let iOS apply the icon mask.
    image = image.resize((SIZE, SIZE), Image.Resampling.LANCZOS).convert("RGB")
    output = ROOT / "ios-app/Polyroom/Resources/AppIcon-1024.png"
    asset_copy = ROOT / "ios-app/Polyroom/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
    output.parent.mkdir(parents=True, exist_ok=True)
    asset_copy.parent.mkdir(parents=True, exist_ok=True)
    image.save(output, format="PNG", optimize=True)
    shutil.copyfile(output, asset_copy)
    print(f"wrote {output.relative_to(ROOT)} ({image.size}, {image.mode})")
    print(f"wrote {asset_copy.relative_to(ROOT)}")


if __name__ == "__main__":
    draw_icon()
