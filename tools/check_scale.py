#!/usr/bin/env python3
"""Sentinela de escala (INFORMATIVO, nunca falha): compara o footprint S/M/L
de catalog.json com a extensao XZ real de art-ios/<id>.glb.

Regra (docs/CATALOG-SCHEMA.md): S<0.5m, M<1.2m, L>=1.2m, com epsilon de 1cm
para casos de borda. Divergencias saem como WARN para revisao humana, pois
ha ambiguidade semantica conhecida: itens de parede (arte/parede/quadros) e
pecas altas e finas (cortinas, luminarias de piso) tem footprint de chao ~0
mas extensao >0.5m — o catalog os marca S (peca pequena) por decisao de
gameplay, nao por erro de escala. Erros GROSSEIROS de escala (fator >3x, ex.
GLB em centimetros ou shell com conteudo trocado) sairiam como ERROR.

Uso: python3 tools/check_scale.py [--ids a,b,c] [--eps 0.01]
"""
import argparse
import glob
import json
import os
import struct
import sys

try:
    import numpy as np
except ImportError:
    print("ERRO: numpy necessario (pip install numpy)")
    sys.exit(2)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EPS_DEFAULT = 0.01
WALL_CATS = {"arte", "parede"}  # piso ~0 por design (pendura na parede)


def mat_of(node):
    if "matrix" in node:
        return np.array(node["matrix"], dtype=np.float64).reshape(4, 4).T
    m = np.eye(4)
    if "scale" in node:
        m = m @ np.diag(list(node["scale"]) + [1.0])
    if "rotation" in node:
        x, y, z, w = node["rotation"]
        m = m @ np.array([
            [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w), 0],
            [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w), 0],
            [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y), 0],
            [0, 0, 0, 1]])
    if "translation" in node:
        t = np.eye(4)
        t[:3, 3] = node["translation"]
        m = t @ m
    return m


def glb_size(path):
    with open(path, "rb") as f:
        data = f.read()
    clen = struct.unpack("<I", data[12:16])[0]
    j = json.loads(data[20:20 + clen].decode("utf-8"))
    acc = j.get("accessors", [])
    mesh_box = {}
    for mi, m in enumerate(j.get("meshes", [])):
        mn = np.full(3, np.inf)
        mx = np.full(3, -np.inf)
        for p in m.get("primitives", []):
            a = acc[p["attributes"]["POSITION"]]
            mn = np.minimum(mn, a["min"])
            mx = np.maximum(mx, a["max"])
        mesh_box[mi] = (mn, mx)
    nodes = j.get("nodes", [])
    gmin = np.full(3, np.inf)
    gmax = np.full(3, -np.inf)

    def visit(ni, parent):
        nonlocal gmin, gmax
        n = nodes[ni]
        w = parent @ mat_of(n)
        if "mesh" in n:
            mn, mx = mesh_box[n["mesh"]]
            cs = np.array([[x, y, z] for x in (mn[0], mx[0])
                           for y in (mn[1], mx[1]) for z in (mn[2], mx[2])])
            pts = (w @ np.hstack([cs, np.ones((8, 1))]).T)[:3, :].T
            gmin = np.minimum(gmin, pts.min(0))
            gmax = np.maximum(gmax, pts.max(0))
        for c in n.get("children", []):
            visit(c, w)

    for ni in j.get("scenes", [{}])[0].get("nodes", []):
        visit(ni, np.eye(4))
    return gmax - gmin


def expected(fxz, eps):
    if fxz < 0.5 - eps:
        return "S"
    if fxz < 1.2 - eps:
        return "M"
    return "L"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--ids", default="")
    ap.add_argument("--eps", type=float, default=EPS_DEFAULT)
    args = ap.parse_args(argv)

    items = {i["id"]: i for i in json.load(
        open(os.path.join(ROOT, "catalog.json"), encoding="utf-8"))["items"]}
    ids = [i.strip() for i in args.ids.split(",") if i.strip()] or sorted(items)
    warns, errors, wall = [], [], []
    for gid in ids:
        it = items.get(gid)
        if it is None:
            errors.append(f"{gid}: fora do catalog")
            continue
        p = os.path.join(ROOT, "art-ios", gid + ".glb")
        if not os.path.isfile(p):
            errors.append(f"{gid}: glb ausente")
            continue
        try:
            s = glb_size(p)
        except Exception as e:  # noqa: BLE001
            errors.append(f"{gid}: glb ilegivel ({e})")
            continue
        fxz, h = float(max(s[0], s[2])), float(s[1])
        maxd = float(max(fxz, h))
        exp = expected(fxz, args.eps)
        if exp != it.get("footprint"):
            # GROSS = anomalia fisica quase certa (unidade errada, bbox
            # degenerado ou conteudo trocado), nao divergencia semantica:
            # divergencias de 1 degrau (S<->M<->L) sao WARN p/ revisao humana.
            gross = (
                not np.isfinite(maxd)
                or maxd <= 0.0
                or maxd > 12.0  # quarto tem 6m; 12m+ = unidade errada
                or (it.get("footprint") == "L" and maxd < 0.3)
            )
            entry = f"{gid}: catalog={it['footprint']} xz={fxz:.2f}m h={h:.2f}m (esperado {exp})"
            if gross:
                errors.append("GROSS " + entry)
            elif it.get("categoria") in WALL_CATS:
                wall.append(entry + " [wall-mounted]")
            else:
                warns.append(entry)
    print(f"scale: itens={len(ids)} errors={len(errors)} warns={len(warns)} wall={len(wall)}")
    for e in errors:
        print("ERROR:", e)
    for w in warns[:30]:
        print("WARN:", w)
    if len(warns) > 30:
        print(f"WARN: ... e mais {len(warns) - 30}")
    for w in wall[:10]:
        print("WALL:", w)
    if errors:
        print(f"scale: {len(errors)} anomalia(s) grosseira(s) — investigar")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
