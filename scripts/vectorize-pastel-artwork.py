#!/usr/bin/env python3
"""Trace the user-supplied tart references into editable, path-only SVG artwork."""
from pathlib import Path
from copy import deepcopy
import xml.etree.ElementTree as ET

from PIL import Image, ImageDraw, ImageFilter
import vtracer

ROOT = Path(__file__).resolve().parents[1]
DESIGN = ROOT / "design"
NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", NS)


def write_svg(path, title):
    tree = ET.parse(path)
    svg = tree.getroot()
    svg.set("viewBox", "0 0 1024 1024")
    svg.insert(0, ET.Element(f"{{{NS}}}title"))
    svg[0].text = title
    tree.write(path, encoding="unicode", xml_declaration=True)


def main():
    cream = Image.open(DESIGN / "reference/cream-tart.png").convert("RGBA")
    # The first reference has an opaque black surround. Clear it without
    # touching the dark brown caramel inside the tart.
    cream.putdata([(r, g, b, 0 if max(r, g, b) < 45 else a) for r, g, b, a in cream.get_flattened_data()])
    ImageDraw.floodfill(cream, (cream.width // 2, 100), (0, 0, 0, 0), thresh=85)
    # Remove the one-pixel fringe of the original rounded-square background.
    cream.putalpha(cream.getchannel("A").filter(ImageFilter.MinFilter(5)).filter(ImageFilter.MaxFilter(5)))
    foreground = cream.crop(cream.getbbox())
    foreground.thumbnail((860, 720), Image.Resampling.LANCZOS)
    layer = Image.new("RGBA", (1024, 1024))
    layer.alpha_composite(foreground, ((1024 - foreground.width) // 2, (1024 - foreground.height) // 2 + 10))
    trace_input = DESIGN / "layers/tart-trace-input.png"
    layer.save(trace_input)
    vector = DESIGN / "pastel-tart.svg"
    vtracer.convert_image_to_svg_py(str(trace_input), str(vector), colormode="color",
        hierarchical="stacked", mode="spline", filter_speckle=24, color_precision=5,
        layer_difference=32, corner_threshold=60, length_threshold=6,
        splice_threshold=45, path_precision=2)
    write_svg(vector, "Pastel it！ — cream egg tart foreground")
    app = ET.Element(f"{{{NS}}}svg", {"width": "1024", "height": "1024", "viewBox": "0 0 1024 1024"})
    ET.SubElement(app, f"{{{NS}}}title").text = "Pastel it！ — cream tart app icon"
    ET.SubElement(app, f"{{{NS}}}rect", {"width": "1024", "height": "1024", "rx": "225", "fill": "#FFF7E5"})
    for path in ET.parse(vector).getroot().findall(f"{{{NS}}}path"):
        app.append(deepcopy(path))
    ET.ElementTree(app).write(DESIGN / "pastel-app-icon.svg", encoding="unicode", xml_declaration=True)

    gold = Image.open(DESIGN / "reference/gold-tart.png").convert("RGBA")
    # White details become transparent cut-outs for system template tinting.
    mask = Image.new("L", gold.size)
    mask.putdata([255 if a > 220 and r > 150 and g > 70 and b < 160 else 0
                  for r, g, b, a in gold.get_flattened_data()])
    mask = mask.filter(ImageFilter.MedianFilter(5))
    mask = mask.crop(mask.getbbox())
    mask.thumbnail((940, 800), Image.Resampling.LANCZOS)
    monochrome = Image.new("L", (1024, 1024), 255)
    monochrome.paste(0, ((1024 - mask.width) // 2, (1024 - mask.height) // 2), mask)
    menu_input = DESIGN / "layers/menubar-trace-input.png"
    monochrome.save(menu_input)
    menu_vector = DESIGN / "pastel-menubar.svg"
    vtracer.convert_image_to_svg_py(str(menu_input), str(menu_vector), colormode="binary",
        mode="spline", filter_speckle=36, corner_threshold=60,
        length_threshold=8, splice_threshold=45, path_precision=2)
    write_svg(menu_vector, "Pastel it！ — template egg tart")


if __name__ == "__main__":
    main()
