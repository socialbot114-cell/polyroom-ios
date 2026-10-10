#!/usr/bin/env python3
"""Simula kill-restore do save (I1/D8-D10): o validador nunca pode crashar.

Cenarios sobre copias em /tmp (nunca toca demo_save_v1.json):
  1. round-trip: load -> dump normalizado -> demo_load deve dar o mesmo
     resultado do original (estabilidade do schema);
  2. kill mid-write: save truncado em 50% -> demo_load deve sair exit 1 com
     ERROR limpo (sem traceback);
  3. corrupto: lixo binario -> idem (espelha SaveManager.load(): arquivo
     corrompido cai no fallback, nunca crasha).

Uso: python3 tools/check_kill_restore.py [--save demo_save_v1.json]
"""
import argparse
import json
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FAIL = []


def run_validator(path):
    p = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "demo_load.py"), path],
                       capture_output=True, text=True, timeout=120)
    return p.returncode, (p.stdout + p.stderr).strip().splitlines()


def check(name, cond, detail=""):
    print(f"[{'OK' if cond else 'FAIL'}] {name} {detail}")
    if not cond:
        FAIL.append(name)


def main(argv=None):
    ap = argparse.ArgumentParser()
    ap.add_argument("--save", default=os.path.join(ROOT, "demo_save_v1.json"))
    args = ap.parse_args(argv)

    rc0, out0 = run_validator(args.save)
    check("baseline valido", rc0 == 0, f"(exit={rc0})")
    if rc0 != 0:
        print("ABORT: demo_save base invalido; corrija antes do kill-restore.")
        return 1

    with tempfile.TemporaryDirectory() as tmp:
        # 1. round-trip
        with open(args.save, encoding="utf-8") as f:
            data = json.load(f)
        rt = os.path.join(tmp, "roundtrip.json")
        with open(rt, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2, sort_keys=True)
        rc1, out1 = run_validator(rt)
        norm = lambda ls: sorted(l for l in ls if l.startswith(("itens=", "WARN:", "ERROR:")))
        check("round-trip estavel", rc1 == 0 and norm(out1) == norm(out0),
              f"(exit={rc1})")

        # 2. kill mid-write (truncado em 50%)
        raw = open(args.save, "rb").read()
        kl = os.path.join(tmp, "killed.json")
        open(kl, "wb").write(raw[:len(raw) // 2])
        rc2, out2 = run_validator(kl)
        crashy = any("Traceback" in l for l in out2)
        check("kill mid-write sem crash", rc2 == 1 and not crashy, f"(exit={rc2})")

        # 3. corrompido (lixo)
        co = os.path.join(tmp, "corrupt.json")
        open(co, "wb").write(b"\x00\xff\xfe garbage {{{ not json")
        rc3, out3 = run_validator(co)
        crashy3 = any("Traceback" in l for l in out3)
        check("corrompido sem crash", rc3 == 1 and not crashy3, f"(exit={rc3})")

    print(f"kill-restore: {'OK' if not FAIL else 'FALHAS=' + str(FAIL)}")
    return 1 if FAIL else 0


if __name__ == "__main__":
    sys.exit(main())
