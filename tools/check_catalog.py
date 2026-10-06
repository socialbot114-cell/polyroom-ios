"""Valida catalog.json contra schema + arquivos."""
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CAT = os.path.join(ROOT, "catalog.json")
VALID_CAT = {"moveis", "acessorios", "sub_itens", "iluminacao", "texteis", "plantas", "eletronicos", "arte", "kids", "piso", "cama_mesa", "pets", "office", "eletrodomesticos", "parede"}
VALID_ROOMS = {"quarto", "cozinha", "sala"}
VALID_FOOTPRINT = {"S", "M", "L"}
BUDGET_PROP = 3000
BUDGET_SHELL = 15000
LIMIT_USDZ = 3 * 1024 * 1024
LIMIT_SHELL = 8 * 1024 * 1024

STRICT = os.environ.get("STRICT", "0") == "1"
ALLOW_MISSING = os.environ.get("ALLOW_MISSING", "1") == "1"

with open(CAT, encoding="utf-8") as f:
    data = json.load(f)

assert "items" in data, "catalog sem items"
ids = set()
errors = []
for it in data["items"]:
    for k in ["id", "nome", "categoria", "rooms", "usdz", "thumb", "footprint", "tintable"]:
        if k not in it:
            errors.append(f"{it.get('id','?')} falta {k}")
    if it["id"] in ids:
        errors.append(f"duplicado {it['id']}")
    ids.add(it["id"])
    if it.get("categoria") not in VALID_CAT:
        errors.append(f"{it['id']} categoria invalida {it.get('categoria')}")
    for r in it.get("rooms", []):
        if r not in VALID_ROOMS:
            errors.append(f"{it['id']} room invalido {r}")
    for key in ["usdz", "thumb"]:
        p = os.path.join(ROOT, it.get(key, ""))
        # D1-D3: arquivo pode não existir ainda -> warn, não falha, se env ALLOW_MISSING=1
        if not os.path.exists(p):
            msg = f"{it['id']} {key} ausente: {it.get(key)}"
            if ALLOW_MISSING:
                print("WARN:", msg)
            else:
                errors.append(msg)
        elif STRICT and key == "usdz":
            # STRICT: tamanho usdz<3MB / shell<8MB quando arquivo existir
            try:
                sz = os.path.getsize(p)
                is_shell = "shell" in str(it.get("id", "")).lower()
                limit = LIMIT_SHELL if is_shell else LIMIT_USDZ
                if sz > limit:
                    errors.append(
                        f"{it['id']} {key} {sz} bytes > limite {limit} "
                        f"({'shell 8MB' if is_shell else 'usdz 3MB'})"
                    )
            except OSError as e:
                errors.append(f"{it['id']} {key} stat falhou: {e}")
    if STRICT:
        # footprint só S/M/L
        fp = it.get("footprint")
        if fp not in VALID_FOOTPRINT:
            errors.append(f"{it['id']} footprint invalido {fp!r} (esperado S/M/L)")
        # tintable bool
        if not isinstance(it.get("tintable"), bool):
            errors.append(f"{it['id']} tintable nao-bool: {it.get('tintable')!r}")
        # extensões
        if not str(it.get("usdz", "")).endswith(".usdz"):
            errors.append(f"{it['id']} usdz deve terminar .usdz: {it.get('usdz')!r}")
        if not str(it.get("thumb", "")).endswith(".png"):
            errors.append(f"{it['id']} thumb deve terminar .png: {it.get('thumb')!r}")
        # tris budget: prop >3000 ERROR, shell >15000 ERROR
        tris = it.get("tris")
        if not isinstance(tris, (int, float)) or isinstance(tris, bool):
            errors.append(f"{it['id']} tris ausente ou nao-numerico: {tris!r}")
        else:
            is_shell = "shell" in str(it.get("id", "")).lower()
            budget = BUDGET_SHELL if is_shell else BUDGET_PROP
            if float(tris) > budget:
                errors.append(f"{it['id']} {int(tris)} tris > budget {budget} ({'shell' if is_shell else 'prop'})")

print(f"itens={len(data['items'])} erros={len(errors)}")
for e in errors:
    print("ERROR:", e)
sys.exit(1 if errors else 0)
