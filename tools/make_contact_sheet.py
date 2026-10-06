"""Gera prints do catalogo: contact sheet geral + por categoria + relatorio.

Uso:
  python3 tools/make_contact_sheet.py [--out previews] [--cell 96] [--cols 24]
  python3 tools/make_contact_sheet.py --per-category  # + sheets previews/sheets/<cat>.png

Grade geral e por categoria a partir de thumbnails/<id>.png (256px).
Thumb ausente/corrompida vira celula cinza com X (WARN, nao falha).
Saidas commitaveis: previews/contact-sheet-480.png + previews/relatorio-480.md
"""
import argparse
import json
import os
import sys
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CAT = os.path.join(ROOT, "catalog.json")
THUMBS = os.path.join(ROOT, "thumbnails")


def load_items():
    with open(CAT, encoding="utf-8") as f:
        return json.load(f)["items"]


def thumb_cell(item, cell):
    from PIL import Image, ImageDraw

    p = os.path.join(ROOT, item.get("thumb", ""))
    try:
        im = Image.open(p).convert("RGBA").resize((cell, cell))
        return im, None
    except Exception as e:
        im = Image.new("RGBA", (cell, cell), (200, 200, 200, 255))
        d = ImageDraw.Draw(im)
        d.line([0, 0, cell, cell], fill=(150, 0, 0, 255), width=3)
        d.line([0, cell, cell, 0], fill=(150, 0, 0, 255), width=3)
        return im, f"{item.get('id')} ({e})"


def sheet(items, cols, cell, pad, title):
    from PIL import Image, ImageDraw

    n = len(items)
    rows = (n + cols - 1) // cols
    W = cols * (cell + pad) + pad
    H = 48 + rows * (cell + pad) + pad
    canvas = Image.new("RGB", (W, H), (30, 30, 32))
    d = ImageDraw.Draw(canvas)
    d.text((pad + 4, 12), title, fill=(255, 255, 255))
    warns = []
    for idx, it in enumerate(items):
        r, c = divmod(idx, cols)
        x = pad + c * (cell + pad)
        y = 48 + pad + r * (cell + pad)
        im, w = thumb_cell(it, cell)
        canvas.paste(im, (x, y), im)
        if w:
            warns.append(w)
    return canvas, warns


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="previews")
    ap.add_argument("--cell", type=int, default=96)
    ap.add_argument("--cols", type=int, default=24)
    ap.add_argument("--per-category", action="store_true")
    args = ap.parse_args()

    items = sorted(load_items(), key=lambda i: i["id"])
    outdir = os.path.join(ROOT, args.out)
    os.makedirs(outdir, exist_ok=True)

    total = len(items)
    img, warns = sheet(items, args.cols, args.cell, 4, f"Polyroom catalog — {total} itens")
    geral = os.path.join(outdir, f"contact-sheet-{total}.png")
    img.save(geral)
    print(f"geral: {geral} ({os.path.getsize(geral)//1024}KB)")

    by_cat = Counter(i["categoria"] for i in items)
    by_room = Counter(r for i in items for r in i.get("rooms", []))
    if args.per_category:
        sdir = os.path.join(outdir, "sheets")
        os.makedirs(sdir, exist_ok=True)
        for cat in sorted(by_cat):
            sub = [i for i in items if i["categoria"] == cat]
            im2, w2 = sheet(sub, min(12, len(sub)), 96, 4, f"{cat} — {len(sub)}")
            warns += w2
            p = os.path.join(sdir, f"{cat}.png")
            im2.save(p)
            print(f"cat: {p}")

    rep = os.path.join(outdir, f"relatorio-{total}.md")
    with open(rep, "w", encoding="utf-8") as f:
        f.write(f"# Prints Polyroom — {total} itens\n\n")
        f.write("| categoria | qtd |\n|---|---|\n")
        for cat, n in sorted(by_cat.items()):
            f.write(f"| {cat} | {n} |\n")
        f.write("\n| room | slots |\n|---|---|\n")
        for room, n in sorted(by_room.items()):
            f.write(f"| {room} | {n} |\n")
        f.write(f"\nThumbs ausentes/corrompidas: {len(warns)}\n")
        for w in warns[:20]:
            f.write(f"- {w}\n")
    print(f"relatorio: {rep}")
    print(f"itens={total} thumbs_problema={len(warns)}")
    return 0 if total else 1


if __name__ == "__main__":
    sys.exit(main())
