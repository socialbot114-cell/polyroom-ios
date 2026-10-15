#!/usr/bin/env python3
"""Converte GLB do catálogo para USDZ usando OpenUSD (`usd-core`).

Converte geometria estática, hierarquia/translations, normals, vertex colors
e cores PBR básicas. GLBs usam Y-up após exportação Blender (`export_yup`).
Não faz bake de texturas; os assets Polyroom usam vertex colors/PBR.

Instalação: python3 -m pip install usd-core
Uso:
  python3 tools/convert_glb_usdz.py --ids liv_moveis_sofa
  python3 tools/convert_glb_usdz.py --all
  python3 tools/convert_glb_usdz.py --all --force
"""
import argparse
import json
import os
import struct
import sys
import tempfile
import zipfile

try:
    from pxr import Gf, Sdf, Usd, UsdGeom, UsdShade, UsdUtils, Vt
except ImportError:
    raise SystemExit("ERRO: instale OpenUSD com `python3 -m pip install usd-core`.")

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOG = os.path.join(ROOT, "catalog.json")
ART = os.path.join(ROOT, "art-ios")

COMPONENTS = {
    5120: ("b", 1), 5121: ("B", 1), 5122: ("h", 2),
    5123: ("H", 2), 5125: ("I", 4), 5126: ("f", 4),
}
WIDTHS = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def read_glb(path):
    with open(path, "rb") as f:
        header = f.read(12)
        if len(header) != 12 or header[:4] != b"glTF":
            raise ValueError("header GLB inválido")
        version, length = struct.unpack("<II", header[4:12])
        if version != 2 or length > os.path.getsize(path):
            raise ValueError("GLB não é versão 2 ou tamanho inválido")
        doc, binary = None, b""
        while f.tell() < length:
            chunk_header = f.read(8)
            if len(chunk_header) != 8:
                break
            chunk_length, chunk_type = struct.unpack("<II", chunk_header)
            chunk = f.read(chunk_length)
            if chunk_type == 0x4E4F534A:
                doc = json.loads(chunk.decode("utf-8"))
            elif chunk_type == 0x004E4942:
                binary = chunk
    if doc is None:
        raise ValueError("GLB sem JSON chunk")
    return doc, binary


def accessor_data(doc, binary, index):
    accessor = doc["accessors"][index]
    component = accessor["componentType"]
    code, component_size = COMPONENTS[component]
    width = WIDTHS[accessor["type"]]
    count = accessor["count"]
    if "bufferView" not in accessor:
        return [(0,) * width for _ in range(count)]
    view = doc["bufferViews"][accessor["bufferView"]]
    stride = view.get("byteStride", component_size * width)
    start = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    fmt = "<" + code * width
    normalized = accessor.get("normalized", False)
    output = []
    for i in range(count):
        offset = start + i * stride
        values = struct.unpack_from(fmt, binary, offset)
        if normalized and component != 5126:
            if component == 5120:
                values = tuple(max(-1.0, v / 127.0) for v in values)
            elif component == 5121:
                values = tuple(v / 255.0 for v in values)
            elif component == 5122:
                values = tuple(max(-1.0, v / 32767.0) for v in values)
            elif component == 5123:
                values = tuple(v / 65535.0 for v in values)
            elif component == 5125:
                values = tuple(v / 4294967295.0 for v in values)
        output.append(values)
    return output


def informative_color(doc, binary, attributes):
    candidates = []
    for semantic, accessor_index in attributes.items():
        if not semantic.startswith("COLOR_"):
            continue
        colors = accessor_data(doc, binary, accessor_index)
        signature = {tuple(round(float(c), 2) for c in color[:3]) for color in colors[:1024]}
        candidates.append((len(signature), colors))
    return max(candidates, key=lambda candidate: candidate[0])[1] if candidates else None


def create_material(stage, path, pbr, colors):
    path = str(path)
    material = UsdShade.Material.Define(stage, path)
    shader = UsdShade.Shader.Define(stage, path + "/PreviewSurface")
    shader.CreateIdAttr("UsdPreviewSurface")
    shader.CreateInput("roughness", Sdf.ValueTypeNames.Float).Set(float(pbr.get("roughnessFactor", 0.8)))
    shader.CreateInput("metallic", Sdf.ValueTypeNames.Float).Set(float(pbr.get("metallicFactor", 0.0)))
    shader.CreateInput("opacity", Sdf.ValueTypeNames.Float).Set(1.0)
    base = pbr.get("baseColorFactor", [1.0, 1.0, 1.0, 1.0])
    if colors:
        reader = UsdShade.Shader.Define(stage, path + "/ColorReader")
        reader.CreateIdAttr("UsdPrimvarReader_float3")
        reader.CreateInput("varname", Sdf.ValueTypeNames.Token).Set("displayColor")
        reader.CreateOutput("result", Sdf.ValueTypeNames.Float3)
        shader.CreateInput("diffuseColor", Sdf.ValueTypeNames.Color3f).ConnectToSource(
            reader.ConnectableAPI(), "result"
        )
    else:
        shader.CreateInput("diffuseColor", Sdf.ValueTypeNames.Color3f).Set(Gf.Vec3f(*base[:3]))
    shader.CreateOutput("surface", Sdf.ValueTypeNames.Token)
    material.CreateSurfaceOutput().ConnectToSource(shader.ConnectableAPI(), "surface")
    return material


def add_primitive(stage, doc, binary, mesh_path, primitive, material_path):
    attributes = primitive["attributes"]
    points = accessor_data(doc, binary, attributes["POSITION"])
    if "indices" in primitive:
        indices = [int(v[0]) for v in accessor_data(doc, binary, primitive["indices"])]
    else:
        indices = list(range(len(points)))
    if len(indices) % 3:
        raise ValueError(f"triangle index count not divisible by 3: {mesh_path}")

    mesh = UsdGeom.Mesh.Define(stage, mesh_path)
    mesh.CreatePointsAttr(Vt.Vec3fArray([Gf.Vec3f(*map(float, p[:3])) for p in points]))
    face_count = len(indices) // 3
    mesh.CreateFaceVertexCountsAttr(Vt.IntArray([3] * face_count))
    mesh.CreateFaceVertexIndicesAttr(Vt.IntArray(indices))
    mesh.CreateSubdivisionSchemeAttr(UsdGeom.Tokens.none)

    if "NORMAL" in attributes:
        normals = accessor_data(doc, binary, attributes["NORMAL"])
        mesh.CreateNormalsAttr(Vt.Vec3fArray([Gf.Vec3f(*map(float, n[:3])) for n in normals]))
        mesh.SetNormalsInterpolation(UsdGeom.Tokens.vertex)

    colors = informative_color(doc, binary, attributes)
    pbr = {}
    if "material" in primitive:
        source_material = doc.get("materials", [])[primitive["material"]]
        pbr = source_material.get("pbrMetallicRoughness", {})
    if colors:
        rgb = [Gf.Vec3f(*[float(v) for v in color[:3]]) for color in colors]
        primvar = UsdGeom.PrimvarsAPI(mesh).CreatePrimvar(
            "displayColor", Sdf.ValueTypeNames.Color3fArray, UsdGeom.Tokens.vertex
        )
        primvar.Set(Vt.Vec3fArray(rgb))
    material = create_material(stage, material_path, pbr, colors)
    UsdShade.MaterialBindingAPI(mesh.GetPrim()).Bind(material)
    return face_count


def set_node_transform(xformable, node):
    if "matrix" in node:
        raise ValueError("matrix-only node transforms are not supported by this converter")
    if "translation" in node:
        xformable.AddTranslateOp().Set(Gf.Vec3d(*map(float, node["translation"])))
    if "rotation" in node:
        x, y, z, w = node["rotation"]
        xformable.AddOrientOp().Set(Gf.Quatf(float(w), Gf.Vec3f(float(x), float(y), float(z))))
    if "scale" in node:
        xformable.AddScaleOp().Set(Gf.Vec3f(*map(float, node["scale"])))


def convert_one(item_id, force=False):
    source = os.path.join(ART, item_id + ".glb")
    target = os.path.join(ART, item_id + ".usdz")
    if os.path.isfile(target) and not force:
        print(f"SKIP {item_id}: USDZ já existe ({os.path.getsize(target)} bytes)")
        return "skipped"
    if not os.path.isfile(source):
        print(f"FAIL {item_id}: GLB ausente")
        return "failed"

    doc, binary = read_glb(source)
    with tempfile.TemporaryDirectory(prefix="polyroom-usd-") as tmp:
        usd_path = os.path.join(tmp, item_id + ".usdc")
        usdz_temp = os.path.join(tmp, item_id + ".usdz")
        stage = Usd.Stage.CreateNew(usd_path)
        UsdGeom.SetStageUpAxis(stage, UsdGeom.Tokens.y)
        UsdGeom.SetStageMetersPerUnit(stage, 1.0)
        root = UsdGeom.Xform.Define(stage, "/Root")
        stage.SetDefaultPrim(root.GetPrim())

        nodes = doc.get("nodes", [])
        meshes = doc.get("meshes", [])
        scene_index = doc.get("scene", 0)
        scenes = doc.get("scenes", [])
        roots = scenes[scene_index].get("nodes", []) if scenes else [
            i for i, node in enumerate(nodes)
            if not any(i in parent.get("children", []) for parent in nodes)
        ]
        tri_count = 0

        def visit(node_index, parent_path):
            nonlocal tri_count
            node = nodes[node_index]
            raw_name = node.get("name", f"Node_{node_index}")
            safe_name = "".join(c if c.isalnum() or c == "_" else "_" for c in raw_name)
            node_path = parent_path.AppendChild(f"{safe_name}_{node_index}")
            xform = UsdGeom.Xform.Define(stage, node_path)
            set_node_transform(UsdGeom.Xformable(xform), node)
            if "mesh" in node:
                source_mesh = meshes[node["mesh"]]
                for primitive_index, primitive in enumerate(source_mesh.get("primitives", [])):
                    if primitive.get("mode", 4) != 4:
                        raise ValueError(f"non-triangle primitive not supported: {item_id}")
                    mesh_path = node_path.AppendChild(f"Mesh_{primitive_index}")
                    material_path = node_path.AppendChild(f"Material_{primitive_index}")
                    tri_count += add_primitive(stage, doc, binary, mesh_path, primitive, material_path)
            for child_index in node.get("children", []):
                visit(child_index, node_path)

        for node_index in roots:
            visit(node_index, root.GetPath())
        stage.GetRootLayer().Save()
        if tri_count <= 0:
            raise ValueError("GLB contém zero triângulos")
        if not UsdUtils.CreateNewUsdzPackage(stage.GetRootLayer().identifier, usdz_temp):
            raise RuntimeError("OpenUSD não conseguiu empacotar o USDZ")
        check = Usd.Stage.Open(usdz_temp)
        if check is None:
            raise RuntimeError("USDZ gerado não reabre como USD stage")
        if not zipfile.is_zipfile(usdz_temp):
            raise RuntimeError("USDZ gerado não é um ZIP válido")
        os.replace(usdz_temp, target)

    print(f"OK {item_id}: {tri_count} tris, {os.path.getsize(target)} bytes")
    return "converted"


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--all", action="store_true")
    group.add_argument("--ids", default="")
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args(argv)
    with open(CATALOG, encoding="utf-8") as f:
        items = json.load(f)["items"]
    item_ids = [item["id"] for item in items] if args.all else [
        item_id.strip() for item_id in args.ids.split(",") if item_id.strip()
    ]
    valid_ids = {item["id"] for item in items}
    unknown = [item_id for item_id in item_ids if item_id not in valid_ids]
    if unknown:
        raise SystemExit(f"IDs fora do catalog.json: {unknown}")

    totals = {"converted": 0, "skipped": 0, "failed": 0}
    for item_id in item_ids:
        try:
            result = convert_one(item_id, force=args.force)
        except Exception as exc:  # segue o lote; relatório agrega falhas por id
            print(f"FAIL {item_id}: {type(exc).__name__}: {exc}")
            result = "failed"
        totals[result] += 1
    print("USDZ summary: " + " ".join(f"{key}={value}" for key, value in totals.items()))
    return 1 if totals["failed"] else 0


if __name__ == "__main__":
    sys.exit(main())
