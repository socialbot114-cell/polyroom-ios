#!/usr/bin/env python3
"""Pipeline deterministico de thumbnails do catalogo (Blender 4.2 headless).

Gera 1 PNG 256x256 por id de catalog.json a partir da geometria real de
art-ios/<id>.glb: enquadramento automatico por bounding box, fundo cozy
claro, luz de estudio suave (3 areas), override de material por categoria
quando a cor de vertice e plana/clara (leitura e contraste), silhueta
preservada (nenhuma alteracao de geometria).

Uso (fora do Blender):
    python3 tools/render_catalog_thumbnails.py --sample          # 5 ids de amostra
    python3 tools/render_catalog_thumbnails.py --ids a,b,c       # ids especificos
    python3 tools/render_catalog_thumbnails.py --all             # 480 itens (padrao)
    python3 tools/render_catalog_thumbnails.py --all --workers 2 --samples 64
    python3 tools/render_catalog_thumbnails.py --verify          # checa PNGs gerados

O driver verifica o binario Blender antes de usar (padrao
/tmp/blender-4.2.1-linux-x64/blender, --blender ou $BLENDER_BIN) e dispara
1..N processos `blender -b --python <este arquivo> -- --inner ...` (shards).
Dentro do Blender (--inner) o mesmo arquivo executa o job de render.
"""

import argparse
import concurrent.futures
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CATALOG = os.path.join(ROOT, "catalog.json")
ARTIOS = os.path.join(ROOT, "art-ios")
THUMBS = os.path.join(ROOT, "thumbnails")

DEFAULT_BLENDER = os.environ.get(
    "BLENDER_BIN", "/tmp/blender-4.2.1-linux-x64/blender"
)
EXPECTED_BLENDER = "4.2"
SIZE = 256

# Amostra canonica: movel, planta, item de parede, luz, eletronico pequeno.
SAMPLE_IDS = [
    "liv_moveis_sofa",      # movel
    "liv_planta_grande",    # planta
    "parede_quadro_triplo",  # item de parede
    "bed_ilum_abajur",      # luz
    "elet_fone",            # eletronico pequeno
]


def load_catalog():
    with open(CATALOG, encoding="utf-8") as f:
        return json.load(f)["items"]


def verify_blender(blender_bin):
    """Verifica o binario antes de usar (existe, executa, versao 4.2.x)."""
    if not (os.path.isfile(blender_bin) and os.access(blender_bin, os.X_OK)):
        raise SystemExit(f"ERRO: binario Blender nao encontrado/executavel: {blender_bin}")
    try:
        out = subprocess.check_output(
            [blender_bin, "--version"], text=True, timeout=60
        )
    except Exception as e:
        raise SystemExit(f"ERRO: falha ao executar {blender_bin} --version: {e}")
    first = out.strip().splitlines()[0] if out.strip() else ""
    print(f"blender: {first}")
    if "Blender" not in first or EXPECTED_BLENDER not in first:
        raise SystemExit(
            f"ERRO: esperado Blender {EXPECTED_BLENDER}.x, obtido: {first!r}"
        )
    return True


# --------------------------------------------------------------------------
# Job interno Blender (somentee executado com bpy disponivel via --inner).
# --------------------------------------------------------------------------
INNER_CODE_HINT = " rode dentro do Blender com --inner "

try:
    import bpy  # noqa: F401  (disponivel so dentro do Blender)

    HAS_BPY = True
except ImportError:
    HAS_BPY = False


if HAS_BPY:
    import math
    import mathutils

    # Fundo cozy claro (mundo) e chao levemente mais escuro; valores lineares.
    BG_COLOR = (0.953, 0.929, 0.886, 1.0)    # ~#F3EDE4
    FLOOR_COLOR = (0.925, 0.898, 0.848, 1.0)
    CAM_LENS = 40
    CAM_FOV_DEG = 40.0
    CAM_DIR = mathutils.Vector((1.0, -1.0, 0.65)).normalized()
    FIT_MARGIN = 1.12

    # Override por categoria (leitura/contraste sobre fundo claro).
    # So aplicado quando a cor de vertice e plana e clara (ex.: tudo branco);
    # modelos com cores proprias informativas sao preservados.
    CATEGORY_COLORS = {
        "moveis": (0.60, 0.44, 0.30, 1.0),
        "acessorios": (0.72, 0.36, 0.22, 1.0),
        "sub_itens": (0.55, 0.52, 0.30, 1.0),
        "iluminacao": (0.85, 0.62, 0.25, 1.0),
        "texteis": (0.75, 0.50, 0.52, 1.0),
        "plantas": (0.28, 0.52, 0.28, 1.0),
        "eletronicos": (0.27, 0.38, 0.55, 1.0),
        "arte": (0.30, 0.52, 0.50, 1.0),
        "kids": (0.85, 0.42, 0.28, 1.0),
        "piso": (0.55, 0.50, 0.44, 1.0),
        "cama_mesa": (0.72, 0.58, 0.38, 1.0),
        "pets": (0.72, 0.48, 0.24, 1.0),
        "office": (0.32, 0.38, 0.46, 1.0),
        "eletrodomesticos": (0.50, 0.54, 0.58, 1.0),
        "parede": (0.42, 0.33, 0.45, 1.0),
    }
    SHADE_FACTORS = (1.0, 0.80, 1.14)  # variacao por parte (preserva leitura)
    FLAT_LUMA = 0.80                   # acima disso = "claro"
    UNIQUE_ROUND = 2

    def _unique_colors(attr, cap=2048):
        n = len(attr.data)
        if n == 0:
            return {}
        step = max(1, n // cap)
        seen = {}
        for i in range(0, n, step):
            c = attr.data[i].color
            key = (round(c[0], UNIQUE_ROUND), round(c[1], UNIQUE_ROUND),
                   round(c[2], UNIQUE_ROUND))
            seen[key] = seen.get(key, 0) + 1
        return seen

    def _luma(rgb):
        return 0.2126 * rgb[0] + 0.7152 * rgb[1] + 0.0722 * rgb[2]

    def clear_scene():
        bpy.ops.object.select_all(action="SELECT")
        bpy.ops.object.delete()
        for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.lights,
                     bpy.data.cameras, bpy.data.images):
            for x in list(coll):
                try:
                    coll.remove(x)
                except Exception:
                    pass

    def setup_world():
        world = bpy.context.scene.world
        if world is None:
            world = bpy.data.worlds.new("ThumbWorld")
            bpy.context.scene.world = world
        world.use_nodes = True
        bg = world.node_tree.nodes.get("Background")
        if bg is None:
            bg = world.node_tree.nodes.new("ShaderNodeBackground")
            out = world.node_tree.nodes.get("Material Output") or \
                world.node_tree.nodes.get("World Output")
            if out is not None:
                world.node_tree.links.new(bg.outputs[0], out.inputs[0])
        bg.inputs["Color"].default_value = BG_COLOR
        bg.inputs["Strength"].default_value = 1.0

    def fix_vertex_colors_and_override(mesh_objs, categoria, item_id):
        """Escolhe o atributo de cor mais informativo; override so se plano."""
        base = CATEGORY_COLORS.get(categoria, (0.6, 0.5, 0.4, 1.0))
        for idx, obj in enumerate(mesh_objs):
            data = obj.data
            if not data.color_attributes:
                _apply_override(obj, base, idx, item_id, categoria)
                continue
            scored = []
            for attr in data.color_attributes:
                uniq = _unique_colors(attr)
                scored.append((len(uniq), attr, uniq))
            scored.sort(key=lambda t: t[0], reverse=True)
            best_n, best_attr, best_uniq = scored[0][0], scored[0][1], scored[0][2]
            # ativa o mais informativo para o no Color Attribute usar
            try:
                data.color_attributes.active_color = best_attr
                if hasattr(data.color_attributes, "render_color_index"):
                    for i, a in enumerate(data.color_attributes):
                        if a == best_attr:
                            data.color_attributes.render_color_index = i
                            break
            except Exception:
                pass
            if best_n == 0:
                _apply_override(obj, base, idx, item_id, categoria)
                continue
            total = sum(best_uniq.values())
            dom = max(best_uniq, key=lambda k: best_uniq[k])
            frac = best_uniq[dom] / max(1, total)
            if (best_n <= 2 and _luma(dom) >= FLAT_LUMA) or (
                    best_n == 1 and frac > 0.98 and _luma(dom) >= 0.75):
                _apply_override(obj, base, idx, item_id, categoria)
            else:
                _normalize_kept_materials(obj)

    def _apply_override(obj, base, idx, item_id, categoria):
        shade = SHADE_FACTORS[idx % len(SHADE_FACTORS)]
        color = (min(1.0, base[0] * shade), min(1.0, base[1] * shade),
                 min(1.0, base[2] * shade), 1.0)
        mat = bpy.data.materials.new(f"TH_{item_id}_{idx}")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes.get("Principled BSDF")
        bsdf.inputs["Base Color"].default_value = color
        try:
            bsdf.inputs["Roughness"].default_value = 0.8
            bsdf.inputs["Metallic"].default_value = 0.0
        except KeyError:
            pass
        if categoria == "iluminacao":  # lampada legivel como fonte quente
            try:
                bsdf.inputs["Emission Color"].default_value = (1.0, 0.85, 0.6, 1.0)
                bsdf.inputs["Emission Strength"].default_value = 0.35
            except KeyError:
                pass
        data = obj.data
        for s in range(len(data.materials)):
            data.materials[s] = mat
        if len(data.materials) == 0:
            data.materials.append(mat)

    def _normalize_kept_materials(obj):
        for mat in list(obj.data.materials):
            if mat is None or not mat.use_nodes:
                continue
            for node in mat.node_tree.nodes:
                if node.type == "BSDF_PRINCIPLED":
                    try:
                        node.inputs["Metallic"].default_value = 0.0
                    except KeyError:
                        pass
                    try:
                        r = node.inputs["Roughness"].default_value
                        if r < 0.55:
                            node.inputs["Roughness"].default_value = 0.55
                    except KeyError:
                        pass

    def render_one(item_id, categoria, glb_path, out_path, samples):
        clear_scene()
        if not os.path.isfile(glb_path):
            return False, f"glb ausente: {glb_path}"
        bpy.ops.import_scene.gltf(filepath=glb_path)
        mesh_objs = [o for o in bpy.context.scene.objects if o.type == "MESH"]
        if not mesh_objs:
            return False, "nenhuma malha importada"
        # bounding box -> recentra na origem (silhueta intacta, so translacao)
        corners = []
        for o in mesh_objs:
            for c in o.bound_box:
                corners.append(o.matrix_world @ mathutils.Vector(c))
        xs = [c.x for c in corners]
        ys = [c.y for c in corners]
        zs = [c.z for c in corners]
        mn = mathutils.Vector((min(xs), min(ys), min(zs)))
        mx = mathutils.Vector((max(xs), max(ys), max(zs)))
        size = mx - mn
        radius = max(size.length / 2.0, 0.05)
        center = (mn + mx) / 2.0
        for o in bpy.context.scene.objects:
            o.matrix_world.translation -= center
        floor_z = -size.z / 2.0

        fix_vertex_colors_and_override(mesh_objs, categoria, item_id)

        # camera com fit esferico deterministico
        cam_data = bpy.data.cameras.new(f"Cam_{item_id}")
        cam_data.type = "PERSP"
        cam_data.lens = CAM_LENS
        try:
            cam_data.angle = math.radians(CAM_FOV_DEG)
        except Exception:
            pass
        cam_obj = bpy.data.objects.new(f"Cam_{item_id}", cam_data)
        bpy.context.scene.collection.objects.link(cam_obj)
        bpy.context.scene.camera = cam_obj
        dist = radius * FIT_MARGIN / math.sin(math.radians(CAM_FOV_DEG / 2.0))
        cam_obj.location = CAM_DIR * dist
        cam_data.clip_start = max(dist / 100.0, 0.001)
        cam_data.clip_end = dist * 50.0
        empty = bpy.data.objects.new(f"Tgt_{item_id}", None)
        bpy.context.scene.collection.objects.link(empty)
        con = cam_obj.constraints.new("TRACK_TO")
        con.target = empty
        con.track_axis = "TRACK_NEGATIVE_Z"
        con.up_axis = "UP_Y"

        # estudio suave: key/fill/rim proporcionais ao tamanho (lei do inverso)
        def add_area(name, loc, energy, sz):
            bpy.ops.object.light_add(type="AREA", location=loc)
            lamp = bpy.context.active_object
            lamp.name = name
            lamp.data.energy = energy
            lamp.data.size = sz
            return lamp

        s = radius
        add_area("Key", (s * 2.2, -s * 2.2, s * 3.0), 120.0 * s * s, s * 2.0)
        add_area("Fill", (-s * 2.5, -s * 1.0, s * 1.5), 45.0 * s * s, s * 2.5)
        add_area("Rim", (-s * 1.0, s * 2.5, s * 2.0), 60.0 * s * s, s * 2.0)
        setup_world()

        # chao fosco (recebe sombra, ancora o objeto)
        bpy.ops.mesh.primitive_plane_add(size=radius * 12.0,
                                         location=(0, 0, floor_z - radius * 0.002))
        floor = bpy.context.active_object
        floor.name = "Floor"
        fmat = bpy.data.materials.new(f"Floor_{item_id}")
        fmat.use_nodes = True
        fbsdf = fmat.node_tree.nodes.get("Principled BSDF")
        fbsdf.inputs["Base Color"].default_value = FLOOR_COLOR
        try:
            fbsdf.inputs["Roughness"].default_value = 0.95
            fbsdf.inputs["Metallic"].default_value = 0.0
        except KeyError:
            pass
        floor.data.materials.append(fmat)

        scene = bpy.context.scene
        scene.render.engine = "BLENDER_EEVEE_NEXT"
        scene.render.resolution_x = SIZE
        scene.render.resolution_y = SIZE
        scene.render.resolution_percentage = 100
        scene.render.film_transparent = False
        scene.render.image_settings.file_format = "PNG"
        scene.render.image_settings.color_mode = "RGB"
        try:
            scene.eevee.taa_render_samples = samples
        except AttributeError:
            pass
        try:
            scene.cycles.seed = 0
        except AttributeError:
            pass
        scene.render.use_motion_blur = False
        scene.render.filepath = out_path
        bpy.ops.render.render(write_still=True)
        return True, "ok"

    def inner_main(argv):
        ap = argparse.ArgumentParser()
        ap.add_argument("--ids", required=True)
        ap.add_argument("--samples", type=int, default=64)
        ap.add_argument("--root", default=ROOT)
        ap.add_argument("--cat-map", default="")
        args = ap.parse_args(argv)
        ids = [i for i in args.ids.split(",") if i]
        cat_map = json.loads(args.cat_map) if args.cat_map else {}
        ok, fail = [], []
        for item_id in ids:
            categoria = cat_map.get(item_id, "moveis")
            glb = os.path.join(args.root, "art-ios", item_id + ".glb")
            out = os.path.join(args.root, "thumbnails", item_id + ".png")
            try:
                good, msg = render_one(item_id, categoria, glb, out, args.samples)
            except Exception as e:  # noqa: BLE001 - segue p/ proximo id
                good, msg = False, f"{type(e).__name__}: {e}"
            print(f"[{'OK' if good else 'FAIL'}] {item_id}: {msg}", flush=True)
            (ok if good else fail).append(item_id)
        print(f"INNER_DONE ok={len(ok)} fail={len(fail)}", flush=True)
        if fail:
            print("FAILED_IDS=" + ",".join(fail), flush=True)
        return 1 if fail else 0


def run_shard(blender_bin, ids, cat_map, samples, root, shard_idx):
    cmd = [
        blender_bin, "-b",
        "--python", os.path.join(root, "tools", "render_catalog_thumbnails.py"),
        "--", "--inner",
        "--ids", ",".join(ids),
        "--samples", str(samples),
        "--root", root,
        "--cat-map", json.dumps(cat_map, separators=(",", ":")),
    ]
    print(f"[shard {shard_idx}] {len(ids)} ids -> blender...", flush=True)
    proc = subprocess.run(cmd, text=True, capture_output=True, timeout=3600)
    tail = "\n".join(proc.stdout.splitlines()[-8:])
    print(f"[shard {shard_idx}] rc={proc.returncode}\n{tail}", flush=True)
    if proc.returncode != 0:
        print(f"[shard {shard_idx}] STDERR:\n{proc.stderr[-3000:]}", flush=True)
    return proc.returncode, proc.stdout


def verify_outputs(ids):
    from PIL import Image

    bad = []
    for item_id in ids:
        p = os.path.join(THUMBS, item_id + ".png")
        if not os.path.isfile(p):
            bad.append((item_id, "ausente"))
            continue
        try:
            im = Image.open(p)
            if im.size != (SIZE, SIZE):
                bad.append((item_id, f"tamanho {im.size}"))
                continue
            rgb = im.convert("RGB")
            px = list(rgb.getdata())
            black = sum(1 for r, g, b in px if r < 8 and g < 8 and b < 8)
            if black / len(px) > 0.005:
                bad.append((item_id, f"faixa preta? px pretos={black}"))
                continue
            corner = rgb.getpixel((4, 4))
            if sum(corner) / 3 < 150:
                bad.append((item_id, f"fundo escuro canto={corner}"))
        except Exception as e:  # noqa: BLE001
            bad.append((item_id, f"leitura falhou: {e}"))
    return bad


def optimize_outputs(ids):
    """Indexa PNG em paleta 8-bit sem dithering para reduzir o pack.

    Render EEVEE é 24-bit RGB; as imagens finais usam até 256 cores (quase
    sem perda visual em thumbnails low-poly), geralmente reduzindo o arquivo
    ~45%. O canal alpha não é necessário: os renders são opacos.
    """
    from PIL import Image

    dither_none = Image.Dither.NONE if hasattr(Image, "Dither") else Image.NONE
    optimized = 0
    for item_id in ids:
        path = os.path.join(THUMBS, item_id + ".png")
        with Image.open(path) as source:
            indexed = source.convert("RGB").quantize(
                colors=256, method=Image.MEDIANCUT, dither=dither_none
            )
            indexed.save(path, format="PNG", optimize=True)
            optimized += 1
    print(f"png optimize: {optimized} indexed (256-color, no dither)")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__)
    g = ap.add_mutually_exclusive_group()
    g.add_argument("--all", action="store_true", help="todos os ids (padrao)")
    g.add_argument("--sample", action="store_true", help="amostra canonica de 5 ids")
    g.add_argument("--ids", default="", help="lista manual a,b,c")
    ap.add_argument("--blender", default=DEFAULT_BLENDER)
    ap.add_argument("--workers", type=int, default=2)
    ap.add_argument("--samples", type=int, default=64)
    ap.add_argument("--verify", action="store_true")
    args = ap.parse_args(argv)

    items = load_catalog()
    id2cat = {it["id"]: it.get("categoria", "moveis") for it in items}
    if args.sample:
        ids = [i for i in SAMPLE_IDS if i in id2cat]
        missing = [i for i in SAMPLE_IDS if i not in id2cat]
        if missing:
            raise SystemExit(f"ERRO: ids da amostra fora do catalogo: {missing}")
    elif args.ids:
        ids = [i.strip() for i in args.ids.split(",") if i.strip()]
        unknown = [i for i in ids if i not in id2cat]
        if unknown:
            raise SystemExit(f"ERRO: ids fora do catalogo: {unknown}")
    else:  # --all ou padrao
        ids = sorted(id2cat)

    if args.verify:
        bad = verify_outputs(ids)
        print(f"verify: itens={len(ids)} ruins={len(bad)}")
        for b in bad[:20]:
            print("BAD:", b)
        return 1 if bad else 0

    verify_blender(args.blender)
    os.makedirs(THUMBS, exist_ok=True)

    # confere GLBs antes de renderizar
    missing_glb = [i for i in ids if not os.path.isfile(os.path.join(ARTIOS, i + ".glb"))]
    if missing_glb:
        raise SystemExit(f"ERRO: {len(missing_glb)} GLBs ausentes: {missing_glb[:10]}")

    workers = max(1, min(args.workers, len(ids)))
    chunks, shard_maps = [], []
    for k in range(workers):
        chunk = ids[k::workers]
        if chunk:
            chunks.append(chunk)
            shard_maps.append({i: id2cat[i] for i in chunk})
    print(f"render: {len(ids)} ids em {len(chunks)} shards "
          f"(blender {EXPECTED_BLENDER}.x, {args.samples} samples, {SIZE}px)")

    failures = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=len(chunks)) as ex:
        futs = {
            ex.submit(run_shard, args.blender, chunk, cmap, args.samples,
                      ROOT, n): n
            for n, (chunk, cmap) in enumerate(zip(chunks, shard_maps))
        }
        for fut in concurrent.futures.as_completed(futs):
            rc, _ = fut.result()
            if rc != 0:
                failures.append(futs[fut])

    if not failures:
        optimize_outputs(ids)
    bad = verify_outputs(ids)
    print(f"done: itens={len(ids)} shards_falha={len(failures)} thumbs_ruins={len(bad)}")
    for b in bad[:20]:
        print("BAD:", b)
    if failures or bad:
        return 1
    print("OK: todas as thumbnails renderizadas e verificadas.")
    return 0


if __name__ == "__main__":
    if "--inner" in sys.argv:
        if not HAS_BPY:
            raise SystemExit("ERRO: --inner exige Blender (bpy).")
        argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
        sys.exit(inner_main([a for a in argv if a != "--inner"]))
    else:
        sys.exit(main())
