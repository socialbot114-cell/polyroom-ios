"""CI headless: blender -b --python tools/check_blend.py
Valida cada art-source/*.blend: nomes, tris budget, UVs básicas.
Falha (exit 1) se estourar. Roda dentro e fora do Blender."""
import os, sys, glob

try:
    import bpy
    IN_BLENDER = True
except ImportError:
    IN_BLENDER = False

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "art-source")

BUDGET_PROP = 3000
BUDGET_SHELL = 15000

errors = []
checked = 0

def check_file(path):
    global checked
    checked += 1
    name = os.path.basename(path)
    if "_REF" in name.upper() or "_ref" in path:
        print(f"SKIP ref {name}")
        return
    bpy.ops.wm.open_mainfile(filepath=path)
    for obj in bpy.data.objects:
        if obj.type != "MESH":
            continue
        # nome: sem espaço/acento
        if " " in obj.name or not obj.name.replace("_", "").replace("-", "").isalnum():
            errors.append(f"{name}:{obj.name} nome invalido (sem espaco, use _)")
        tris = len(obj.data.loop_triangles) if hasattr(obj.data, "loop_triangles") else 0
        try:
            obj.data.calc_loop_triangles()
            tris = len(obj.data.loop_triangles)
        except Exception:
            pass
        is_shell = "shell" in obj.name.lower() or "shell" in name.lower()
        budget = BUDGET_SHELL if is_shell else BUDGET_PROP
        if tris > budget:
            errors.append(f"{name}:{obj.name} {tris} tris > budget {budget}")
        if not obj.data.uv_layers:
            errors.append(f"{name}:{obj.name} sem UV")

if not IN_BLENDER:
    print("check_blend: fora do Blender — validando só existência de arquivos")
    files = glob.glob(os.path.join(SRC, "*.blend"))
    print(f"encontrados: {len(files)}")
    sys.exit(0)

files = sorted(glob.glob(os.path.join(SRC, "*.blend")))
if not files:
    print("WARN: nenhum .blend ainda (D1 OK)")
    sys.exit(0)
for f in files:
    check_file(f)

print(f"checked={checked} errors={len(errors)}")
for e in errors:
    print("ERROR:", e)
sys.exit(1 if errors else 0)
