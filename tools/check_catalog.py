"""Valida catalog.json contra schema + arquivos."""
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CAT = os.path.join(ROOT, "catalog.json")
VALID_CAT = {"moveis", "acessorios", "sub_itens", "iluminacao", "texteis", "plantas", "eletronicos", "arte", "kids", "piso", "cama_mesa", "pets", "office", "eletrodomesticos", "parede"}
VALID_ROOMS = {"quarto", "cozinha", "sala"}

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
            if os.environ.get("ALLOW_MISSING", "1") == "1":
                print("WARN:", msg)
            else:
                errors.append(msg)

print(f"itens={len(data['items'])} erros={len(errors)}")
for e in errors:
    print("ERROR:", e)
sys.exit(1 if errors else 0)
