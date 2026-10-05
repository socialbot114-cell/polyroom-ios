"""Valida demo_save_v1.json contra catalog.json + regras RoomSave/Snap.

Checa: decode campos (version/rooms/coins + PlacedItem), catalogIds existem,
posicoes dentro 6x6 ([-3,3]), snap 0.25, rotacao multipla de 45.
Uso: python3 tools/demo_load.py [demo_save_v1.json]
"""
import json
import os
import sys
import uuid

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CAT_PATH = os.path.join(ROOT, "catalog.json")
SAVE_PATH = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "demo_save_v1.json")

VALID_ROOMS = {"quarto", "cozinha", "sala"}
HALF = 3.0
STEP = 0.25
EPS = 1e-6

errors = []
warns = []


def err(msg):
    errors.append(msg)


def warn(msg):
    warns.append(msg)


# --- catalog ---
try:
    with open(CAT_PATH, encoding="utf-8") as f:
        cat = json.load(f)
except Exception as e:
    print(f"ERROR: nao abriu catalog.json: {e}")
    sys.exit(1)

cat_ids = {}
for it in cat.get("items", []):
    cat_ids[it.get("id")] = it

# --- save ---
try:
    with open(SAVE_PATH, encoding="utf-8") as f:
        save = json.load(f)
except Exception as e:
    print(f"ERROR: nao abriu {SAVE_PATH}: {e}")
    sys.exit(1)

# top-level
if save.get("version") != 1:
    err(f"version invalida: {save.get('version')!r} (esperado 1)")
rooms = save.get("rooms")
if not isinstance(rooms, dict):
    err("campo 'rooms' ausente ou nao-dict")
    rooms = {}
if not isinstance(save.get("coins"), int):
    err(f"campo 'coins' invalido: {save.get('coins')!r}")

for k in rooms.keys():
    if k not in VALID_ROOMS:
        err(f"room chave invalida: {k}")
for r in sorted(VALID_ROOMS):
    if r not in rooms:
        warn(f"room '{r}' ausente no save (esperado 3 rooms)")
    elif not isinstance(rooms[r], list):
        err(f"rooms.{r} nao-lista")
    elif not (2 <= len(rooms[r]) <= 3):
        warn(f"rooms.{r} tem {len(rooms[r])} itens (esperado 2-3)")

seen_ids = set()
total = 0
for room_key, lst in rooms.items():
    if not isinstance(lst, list):
        continue
    for i, p in enumerate(lst):
        where = f"{room_key}[{i}]"
        total += 1
        for k in ["id", "catalogId", "room", "x", "z", "rotationY", "colorIndex"]:
            if k not in p:
                err(f"{where} falta campo '{k}'")
        # id UUID
        pid = p.get("id", "?")
        try:
            uuid.UUID(str(pid))
        except Exception:
            err(f"{where} id nao-UUID: {pid!r}")
        if pid in seen_ids:
            err(f"{where} id duplicado: {pid}")
        seen_ids.add(pid)
        # catalogId
        cid = p.get("catalogId")
        if cid not in cat_ids:
            err(f"{where} catalogId inexistente: {cid!r}")
        else:
            # compatibilidade room x catalog.rooms -> WARN
            allowed = cat_ids[cid].get("rooms", [])
            if p.get("room") not in allowed:
                warn(f"{where} {cid} nao lista '{p.get('room')}' em catalog.rooms {allowed}")
        # room coerencia chave vs campo
        if p.get("room") != room_key:
            err(f"{where} room campo '{p.get('room')}' != chave '{room_key}'")
        if p.get("room") not in VALID_ROOMS:
            err(f"{where} room invalido: {p.get('room')!r}")
        # x/z
        for axis in ["x", "z"]:
            v = p.get(axis)
            if not isinstance(v, (int, float)) or isinstance(v, bool):
                err(f"{where} {axis} nao-numerico: {v!r}")
                continue
            if not (-HALF - EPS <= float(v) <= HALF + EPS):
                err(f"{where} {axis}={v} fora de [-3,3] (6x6)")
            # snap 0.25
            q = round(float(v) / STEP) * STEP
            if abs(float(v) - q) > 1e-4:
                warn(f"{where} {axis}={v} fora do snap 0.25")
        # rotationY
        r = p.get("rotationY")
        if not isinstance(r, (int, float)) or isinstance(r, bool):
            err(f"{where} rotationY nao-numerico: {r!r}")
        else:
            if abs((float(r) / 45.0) - round(float(r) / 45.0)) > 1e-4:
                warn(f"{where} rotationY={r} nao multiplo de 45")
        # colorIndex
        c = p.get("colorIndex")
        if not isinstance(c, int) or isinstance(c, bool):
            err(f"{where} colorIndex nao-int: {c!r}")
        else:
            if c < 0:
                err(f"{where} colorIndex negativo: {c}")
            elif c > 5:
                warn(f"{where} colorIndex={c} > 5 (6 swatches)")

print(f"itens={total} erros={len(errors)} warns={len(warns)}")
for w in warns:
    print("WARN:", w)
for e in errors:
    print("ERROR:", e)
sys.exit(1 if errors else 0)
