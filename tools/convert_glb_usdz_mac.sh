#!/usr/bin/env bash
# tools/convert_glb_usdz_mac.sh — GLB -> USDZ no Mac (45 ids do catalog.json)
#
# Uso:
#   bash tools/convert_glb_usdz_mac.sh           # converte faltantes, pula se .usdz já existe
#   bash tools/convert_glb_usdz_mac.sh --force  # reconverte tudo
#
# Requer: macOS + Xcode Command Line Tools (xcrun usdz_converter).
#   xcode-select --install
#
# Origem dos IDs: catalog.json (campo items[].id, esperado 45).
#   src: art-ios/<id>.glb  (existe no Linux, 45 arquivos)
#   dst: art-ios/<id>.usdz (0/45 no repo — gerar no Mac, D2)
#
# Comportamento:
#   - loop sobre os 45 ids do catalog.json (via python3, sem depender de jq)
#   - pula se .usdz já existe (salvo --force)
#   - loga tamanhos .glb -> .usdz (du -h) + resumo final
#
# Fallback (sem Xcode / sem Mac):
#   Reality Converter (Apple, GUI gratuita, Mac App Store):
#     1. Abrir Reality Converter no Mac
#     2. Arrastar art-ios/<id>.glb (ou .usdc exportado do Blender)
#     3. Export > .usdz para art-ios/<id>.usdz
#   Ver docs/PIPELINE.md §3 e ios-app/Polyroom/Resources/README-ASSETS.md.
#   No Linux, manter .glb como fallback — S2 importa no Xcode e converte p/ .scn/.usdz.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ART="$ROOT/art-ios"
CAT="$ROOT/catalog.json"
FORCE=0

if [[ "${1:-}" == "--force" ]]; then
  FORCE=1
fi

if [[ ! -f "$CAT" ]]; then
  echo "ERRO: catalog.json não encontrado em $CAT" >&2
  exit 1
fi

if ! command -v xcrun >/dev/null 2>&1; then
  echo "ERRO: 'xcrun' não encontrado. Rode este script no Mac com Xcode instalado." >&2
  echo "Fallback: abra cada .glb no Reality Converter e exporte como .usdz (ver cabeçalho)." >&2
  exit 1
fi

if ! xcrun usdz_converter --help >/dev/null 2>&1; then
  echo "AVISO: 'xcrun usdz_converter' não respondeu a --help; tentando mesmo assim..." >&2
fi

# Lista de ids via python3 (sem jq)
mapfile -t IDS < <(python3 -c "import json; d=json.load(open('$CAT')); print('\n'.join(it['id'] for it in d['items']))")
echo "ids catalog.json: ${#IDS[@]} (esperado 45)"

ok=0
skipped=0
failed=0
missing_glb=0

for id in "${IDS[@]}"; do
  SRC="$ART/$id.glb"
  DST="$ART/$id.usdz"
  if [[ ! -f "$SRC" ]]; then
    echo "SKIP $id: .glb ausente ($SRC)"
    missing_glb=$((missing_glb+1))
    continue
  fi
  if [[ -f "$DST" && "$FORCE" -eq 0 ]]; then
    SZ_SRC=$(du -h "$SRC" | cut -f1)
    SZ_DST=$(du -h "$DST" | cut -f1)
    echo "SKIP $id: .usdz já existe (glb $SZ_SRC -> usdz $SZ_DST)"
    skipped=$((skipped+1))
    continue
  fi
  echo "CONV $id: $SRC -> $DST"
  if xcrun usdz_converter "$SRC" "$DST"; then
    SZ_SRC=$(du -h "$SRC" | cut -f1)
    SZ_DST=$(du -h "$DST" | cut -f1)
    echo "  OK $id: glb $SZ_SRC -> usdz $SZ_DST"
    ok=$((ok+1))
  else
    echo "  FAIL $id" >&2
    failed=$((failed+1))
  fi
done

echo "---- resumo ----"
echo "convertidos=$ok pulados=$skipped falhas=$failed glb_ausente=$missing_glb total_ids=${#IDS[@]}"
ls -lh "$ART"/*.usdz 2>/dev/null || echo "(nenhum .usdz ainda — esperado antes de rodar no Mac: 0/45)"
