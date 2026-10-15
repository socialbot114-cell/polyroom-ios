#!/usr/bin/env bash
# Compatibility wrapper: USDZ conversion is now cross-platform via OpenUSD.
#
#   bash tools/convert_glb_usdz_mac.sh           # convert missing USDZs
#   bash tools/convert_glb_usdz_mac.sh --force  # regenerate all
#
# Install the pinned Python dependency once:
#   python3 -m pip install --user -r tools/requirements-usdz.txt
#
# The implementation also works on Linux; the historical name is retained so
# old project docs/commands keep working.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"

if ! "$PYTHON_BIN" -c 'from pxr import Usd, UsdUtils' >/dev/null 2>&1; then
  echo "ERRO: OpenUSD ausente. Instale com:" >&2
  echo "  $PYTHON_BIN -m pip install --user -r tools/requirements-usdz.txt" >&2
  exit 1
fi

if [[ "${1:-}" == "--force" ]]; then
  exec "$PYTHON_BIN" "$ROOT/tools/convert_glb_usdz.py" --all --force
fi
exec "$PYTHON_BIN" "$ROOT/tools/convert_glb_usdz.py" --all
