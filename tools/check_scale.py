#!/usr/bin/env python3
"""Sentinela de escala do footprint S/M/L usando dimensões XZ dos GLBs.

Sem dependências externas; roda local e no Ubuntu CI. A regra base é
S<0.5m, M<1.2m, L>=1.2m (docs/CATALOG-SCHEMA.md), com epsilon de 1cm.
Diferenças semânticas são WARN: itens de parede e objetos altos/finos usam
footprint de colocação/uso, não necessariamente sua maior dimensão XZ.
Anomalias físicas grosseiras (bbox vazio, unidade/escala extrema ou item L
degenerado) são ERROR.

Uso: python3 tools/check_scale.py [--ids a,b,c] [--eps 0.01]
"""
import argparse
import json
import math
import os
import struct
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EPS_DEFAULT = 0.01
WALL_CATS = {"arte", "parede"}


def identity():
    return [[1.0 if r == c else 0.0 for c in range(4)] for r in range(4)]


def matmul(a, b):
    return [[sum(a[r][k] * b[k][c] for k in range(4)) for c in range(4)]
            for r in range(4)]


def node_matrix(node):
    if "matrix" in node:
        # glTF stores column-major 4x4 matrices; our representation is row-major.
        flat = node["matrix"]
        return [[float(flat[c * 4 + r]) for c in range(4)] for r in range(4)]

    x, y, z = node.get("scale", (1.0, 1.0, 1.0))
    scale = [[x, 0, 0, 0], [0, y, 0, 0], [0, 0, z, 0], [0, 0, 0, 1]]
    qx, qy, qz, qw = node.get("rotation", (0.0, 0.0, 0.0, 1.0))
    rotation = [
        [1 - 2 * (qy*qy + qz*qz), 2 * (qx*qy - qz*qw), 2 * (qx*qz + qy*qw), 0],
        [2 * (qx*qy + qz*qw), 1 - 2 * (qx*qx + qz*qz), 2 * (qy*qz - qx*qw), 0],
        [2 * (qx*qz - qy*qw), 2 * (qy*qz + qx*qw), 1 - 2 * (qx*qx + qy*qy), 0],
        [0, 0, 0, 1],
    ]
    tx, ty, tz = node.get("translation", (0.0, 0.0, 0.0))
    translation = [[1, 0, 0, tx], [0, 1, 0, ty], [0, 0, 1, tz], [0, 0, 0, 1]]
    return matmul(translation, matmul(rotation, scale))


def transform_point(matrix, point):
    x, y, z = point
    p = (x, y, z, 1.0)
    out = [sum(matrix[r][c] * p[c] for c in range(4)) for r in range(4)]
    w = out[3] or 1.0
    return (out[0] / w, out[1] / w, out[2] / w)


def glb_size(path):
    with open(path, "rb") as f:
        header = f.read(12)
        if len(header) != 12 or header[:4] != b"glTF":
            raise ValueError("header GLB inválido")
        json_length = struct.unpack("<I", f.read(4))[0]
        chunk_type = f.read(4)
        if chunk_type != b"JSON":
            raise ValueError("primeiro chunk GLB não é JSON")
        doc = json.loads(f.read(json_length).decode("utf-8"))

    mesh_bounds = []
    for mesh in doc.get("meshes", []):
        mins = [math.inf, math.inf, math.inf]
        maxs = [-math.inf, -math.inf, -math.inf]
        for primitive in mesh.get("primitives", []):
            accessor = doc["accessors"][primitive["attributes"]["POSITION"]]
            for axis in range(3):
                mins[axis] = min(mins[axis], float(accessor["min"][axis]))
                maxs[axis] = max(maxs[axis], float(accessor["max"][axis]))
        if all(math.isfinite(v) for v in mins + maxs):
            mesh_bounds.append((mins, maxs))
        else:
            mesh_bounds.append(None)

    nodes = doc.get("nodes", [])
    global_min = [math.inf, math.inf, math.inf]
    global_max = [-math.inf, -math.inf, -math.inf]
    mesh_count = 0

    def visit(node_index, parent_matrix):
        nonlocal mesh_count
        node = nodes[node_index]
        world = matmul(parent_matrix, node_matrix(node))
        if "mesh" in node:
            bound = mesh_bounds[node["mesh"]]
            if bound is None:
                raise ValueError(f"mesh {node['mesh']} sem bounds de POSITION")
            mins, maxs = bound
            corners = [(x, y, z)
                       for x in (mins[0], maxs[0])
                       for y in (mins[1], maxs[1])
                       for z in (mins[2], maxs[2])]
            for corner in corners:
                p = transform_point(world, corner)
                for axis in range(3):
                    global_min[axis] = min(global_min[axis], p[axis])
                    global_max[axis] = max(global_max[axis], p[axis])
            mesh_count += 1
        for child in node.get("children", []):
            visit(child, world)

    scenes = doc.get("scenes", [{}])
    scene_index = doc.get("scene", 0)
    roots = scenes[scene_index].get("nodes", [])
    for root in roots:
        visit(root, identity())
    if not mesh_count:
        raise ValueError("GLB não contém geometria em nós de cena")
    return tuple(global_max[i] - global_min[i] for i in range(3))


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

    with open(os.path.join(ROOT, "catalog.json"), encoding="utf-8") as f:
        items = {i["id"]: i for i in json.load(f)["items"]}
    ids = [i.strip() for i in args.ids.split(",") if i.strip()] or sorted(items)
    warns, errors, wall = [], [], []
    for item_id in ids:
        item = items.get(item_id)
        if item is None:
            errors.append(f"{item_id}: fora do catálogo")
            continue
        path = os.path.join(ROOT, "art-ios", item_id + ".glb")
        if not os.path.isfile(path):
            errors.append(f"{item_id}: GLB ausente")
            continue
        try:
            size = glb_size(path)
        except Exception as exc:  # validação deve reportar erro por id e seguir
            errors.append(f"{item_id}: GLB ilegível ({exc})")
            continue
        fxz, height = max(size[0], size[2]), size[1]
        max_dimension = max(fxz, height)
        expected_footprint = expected(fxz, args.eps)
        if expected_footprint == item.get("footprint"):
            continue

        gross = (not math.isfinite(max_dimension) or max_dimension <= 0
                 or max_dimension > 12.0
                 or (item.get("footprint") == "L" and max_dimension < 0.3))
        message = (f"{item_id}: catalog={item['footprint']} xz={fxz:.2f}m "
                   f"h={height:.2f}m (dimensão sugere {expected_footprint})")
        if gross:
            errors.append("GROSS " + message)
        elif item.get("categoria") in WALL_CATS:
            wall.append(message + " [wall-mounted]")
        else:
            warns.append(message)

    print(f"scale: itens={len(ids)} errors={len(errors)} warns={len(warns)} wall={len(wall)}")
    for message in errors:
        print("ERROR:", message)
    for message in warns[:30]:
        print("WARN:", message)
    if len(warns) > 30:
        print(f"WARN: ... e mais {len(warns) - 30}")
    for message in wall[:10]:
        print("WALL:", message)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
