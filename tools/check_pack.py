"""Fast check sem Blender: nomes + glb/thumb existem + tamanhos. Para CI rápida.
Uso: python3 tools/check_pack.py [--changed-only]
"""
import json, os, sys, glob, subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
d = json.load(open(os.path.join(ROOT, "catalog.json")))
changed = None
if "--changed-only" in sys.argv:
    try:
        out = subprocess.check_output(["git", "diff", "--name-only", "HEAD~1", "HEAD"], cwd=ROOT, text=True)
        changed = set(out.split())
    except Exception:
        changed = None

errors, warns, checked = [], [], 0
total_glb = 0
for it in d["items"]:
    if changed is not None and f"art-source/" not in str(changed) and it["id"] not in str(changed):
        continue
    checked += 1
    for key in ["usdz", "thumb"]:
        p = os.path.join(ROOT, it[key].replace(".usdz", ".glb") if key == "usdz" else it[key])
        if not os.path.exists(p):
            msg = f"{it['id']} {key} ausente"
            (warns if os.environ.get("ALLOW_MISSING", "1") == "1" else errors).append(msg)
        elif key != "thumb":
            total_glb += os.path.getsize(p)
            if os.path.getsize(p) > 3 * 1024 * 1024:
                errors.append(f"{it['id']} glb >3MB")
print(f"pack: itens={checked} erros={len(errors)} warns={len(warns)} glb_total={total_glb/1048576:.1f}MB")
for e in errors[:20]: print("ERROR:", e)
sys.exit(1 if errors else 0)
