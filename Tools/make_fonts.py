"""Собирает из кадров шрифты: в шрифте BulkXxx цифры 0-9 — это 10 кадров занятия xxx.

Запуск: python make_fonts.py <папка с png> <папка для ttf>
"""
import glob
import os
import sys

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import newTable
from fontTools.ttLib.tables.sbixGlyph import Glyph as SbixGlyph
from fontTools.ttLib.tables.sbixStrike import Strike

frames_dir, out_dir = sys.argv[1], sys.argv[2]
os.makedirs(out_dir, exist_ok=True)

UPM = 1000
ADVANCE = 1400  # кадр 112x80 -> ширина 1.4 em
PPEM = 240      # высота png в пикселях = 1 em

actions = sorted({os.path.basename(p).rsplit("_", 1)[0] for p in glob.glob(os.path.join(frames_dir, "*.png"))})
for act in actions:
    name = "Bulk" + act[0].upper() + act[1:]
    order = [".notdef", "space", "colon"] + [f"d{i}" for i in range(10)]
    cmap = {ord(" "): "space", ord(":"): "colon"}
    cmap.update({ord(str(i)): f"d{i}" for i in range(10)})

    fb = FontBuilder(UPM, isTTF=True)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap(cmap)
    empty = TTGlyphPen(None).glyph()
    fb.setupGlyf({g: empty for g in order})
    fb.setupHorizontalMetrics({g: (ADVANCE, 0) for g in order})
    fb.setupHorizontalHeader(ascent=UPM, descent=0)
    fb.setupNameTable({"familyName": name, "styleName": "Regular", "psName": name})
    fb.setupOS2(sTypoAscender=UPM, sTypoDescender=0, sTypoLineGap=0, usWinAscent=UPM, usWinDescent=0)
    fb.setupPost()

    sbix = newTable("sbix")
    strike = Strike(ppem=PPEM, resolution=72)
    for i in range(10):
        with open(os.path.join(frames_dir, f"{act}_{i}.png"), "rb") as fh:
            strike.glyphs[f"d{i}"] = SbixGlyph(glyphName=f"d{i}", graphicType="png ", imageData=fh.read())
    sbix.strikes = {PPEM: strike}
    fb.font["sbix"] = sbix
    fb.save(os.path.join(out_dir, f"{name}.ttf"))
    print("font:", name)
