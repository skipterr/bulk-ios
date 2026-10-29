"""Запасной способ: одноцветные шрифты-слои вместо цветных картинок.

Каждый кадр раскладывается на 3 силуэта (F — всё тело, W — белое, K — чёрное),
силуэты обводятся potrace в векторные контуры и становятся цифрами 0-9 в шрифтах
BulkXxxF / BulkXxxW / BulkXxxK. В виджете три секундомера этими шрифтами накладываются
друг на друга своими цветами.

Запуск: python make_layer_fonts.py <папка с png> <папка для otf>
"""
import glob
import os
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ET

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.t2CharStringPen import T2CharStringPen
from fontTools.pens.transformPen import TransformPen
from fontTools.svgLib.path import parse_path
from PIL import Image, ImageChops

frames_dir, out_dir = sys.argv[1], sys.argv[2]
os.makedirs(out_dir, exist_ok=True)

UPM = 1000
ADVANCE = 1400
FRAME_H = 240
SCALE = UPM / (FRAME_H * 10)  # potrace по умолчанию даёт 10 единиц на пиксель, ось y вверх


def masks(path):
    img = Image.open(path).convert("RGBA")
    alpha = img.getchannel("A").point(lambda v: 255 if v > 128 else 0)
    lum = img.convert("RGB").convert("L")
    white = ImageChops.multiply(alpha, lum.point(lambda v: 255 if v > 215 else 0))
    black = ImageChops.multiply(alpha, lum.point(lambda v: 255 if v < 60 else 0))
    return {"F": alpha, "W": white, "K": black}


def draw_mask(mask, pen, tmp):
    pbm = os.path.join(tmp, "m.pbm")
    svg = os.path.join(tmp, "m.svg")
    # potrace обводит чёрные пиксели
    mask.point(lambda v: 0 if v > 128 else 255).convert("1").save(pbm)
    subprocess.run(["potrace", "-s", "--flat", "-o", svg, pbm], check=True)
    tpen = TransformPen(pen, (SCALE, 0, 0, SCALE, 0, 0))
    for el in ET.parse(svg).getroot().iter():
        if el.tag.endswith("path") and el.get("d"):
            parse_path(el.get("d"), tpen)


actions = sorted({os.path.basename(p).rsplit("_", 1)[0] for p in glob.glob(os.path.join(frames_dir, "*.png"))})
order = [".notdef", "space", "colon"] + [f"d{i}" for i in range(10)]
cmap = {ord(" "): "space", ord(":"): "colon"}
cmap.update({ord(str(i)): f"d{i}" for i in range(10)})

with tempfile.TemporaryDirectory() as tmp:
    for act in actions:
        per_frame = [masks(os.path.join(frames_dir, f"{act}_{i}.png")) for i in range(10)]
        for layer in ("F", "W", "K"):
            name = "Bulk" + act[0].upper() + act[1:] + layer
            charstrings = {}
            for g in order:
                pen = T2CharStringPen(ADVANCE, None)
                if g.startswith("d"):
                    draw_mask(per_frame[int(g[1:])][layer], pen, tmp)
                charstrings[g] = pen.getCharString()
            fb = FontBuilder(UPM, isTTF=False)
            fb.setupGlyphOrder(order)
            fb.setupCharacterMap(cmap)
            fb.setupCFF(name, {"FullName": name}, charstrings, {})
            fb.setupHorizontalMetrics({g: (ADVANCE, 0) for g in order})
            fb.setupHorizontalHeader(ascent=UPM, descent=0)
            fb.setupNameTable({"familyName": name, "styleName": "Regular", "psName": name})
            fb.setupOS2(sTypoAscender=UPM, sTypoDescender=0, sTypoLineGap=0, usWinAscent=UPM, usWinDescent=0)
            fb.setupPost()
            fb.save(os.path.join(out_dir, f"{name}.otf"))
        print("layer fonts:", act)
