#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/../.."
D="$ROOT/build/svg"
[ -d "$D" ] || "$HERE/glyphs.sh" >/dev/null 2>&1

EXPECTED_CHECKS=9
fail=0; checks=0
ok()  { checks=$((checks+1)); echo "  ok   $1"; }
bad() { checks=$((checks+1)); echo "  FAIL $1"; fail=1; }

if [ -f "$D/gmic-wb.svg" ]; then ok "gmic-wb reso"; else bad "gmic-wb reso"; fi
if [ -f "$D/gmic-gs.svg" ]; then ok "gmic-gs reso"; else bad "gmic-gs reso"; fi
if [ -f "$D/am-gs.svg" ];   then ok "am-gs reso (ereditato)"; else bad "am-gs reso (ereditato)"; fi
if [ ! -f "$D/preamp-wb.svg" ]; then ok "preamp-wb non reso"; else bad "preamp-wb non reso"; fi

if grep -q 'currentColor' "$D/gmic-wb.svg"; then ok "colore ereditato dal testo"; else bad "colore ereditato dal testo"; fi
if ! grep -q 'rgb(0%, 0%, 0%)' "$D/gmic-wb.svg"; then ok "nessun nero fisso"; else bad "nessun nero fisso"; fi
# -F e la stringa completa: cercare "xml" pescherebbe xmlns dentro il tag <svg>.
if ! grep -qF '<?xml' "$D/gmic-wb.svg"; then ok "niente prologo XML"; else bad "niente prologo XML"; fi
if grep -q 'id="gmic-wb-' "$D/gmic-wb.svg"; then ok "id prefissati"; else bad "id prefissati"; fi

# La collisione di id è l'errore che romperebbe la pagina: nessun id condiviso.
shared="$(comm -12 \
  <(grep -oE 'id="[^"]*"' "$D/gmic-wb.svg" | sort -u) \
  <(grep -oE 'id="[^"]*"' "$D/gmic-gs.svg" | sort -u))"
if [ -z "$shared" ]; then ok "nessun id in comune fra due glifi"; else bad "nessun id in comune fra due glifi ($shared)"; fi

if [ "$checks" -ne "$EXPECTED_CHECKS" ]; then echo "  FAIL check eseguiti: $checks, attesi: $EXPECTED_CHECKS"; fail=1; fi
[ $fail -eq 0 ] && echo "TEST GLYPHS OK ($checks check)" || { echo "TEST GLYPHS FAIL"; exit 1; }
