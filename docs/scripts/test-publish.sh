#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/_sean" "$TMP/_data"; : > "$TMP/_data/navigation.yml"

python3 "$HERE/publish.py" "$TMP" > "$TMP/out.txt" 2>&1 || { echo "publish.py è uscito con errore:"; cat "$TMP/out.txt"; exit 1; }
P="$TMP/_sean/index.md"

EXPECTED_CHECKS=12
fail=0; checks=0
ok()  { checks=$((checks+1)); echo "  ok   $1"; }
bad() { checks=$((checks+1)); echo "  FAIL $1"; fail=1; }

if [ -f "$P" ]; then ok "pagina generata"; else bad "pagina generata"; fi
if grep -q '^permalink: /sean/$' "$P"; then ok "permalink"; else bad "permalink"; fi
if grep -q '^generated_from: sean$' "$P"; then ok "provenienza"; else bad "provenienza"; fi
if grep -qF '<svg' "$P"; then ok "svg inline"; else bad "svg inline"; fi
if grep -q 'currentColor' "$P"; then ok "glifi con currentColor"; else bad "glifi con currentColor"; fi
if grep -q '<code>gmic</code>' "$P"; then ok "gmic in tabella"; else bad "gmic in tabella"; fi
if grep -q '<code>preamp</code>' "$P"; then ok "estensioni GS in tabella"; else bad "estensioni GS in tabella"; fi
# La colonna "GS from" dichiara da quale font viene davvero il glifo:
# <code>wb</code> quando GS eredita, <code>gs</code> quando lo ridefinisce.
if grep -qF '<th>GS from</th>' "$P"; then ok "colonna di provenienza"; else bad "colonna di provenienza"; fi

# gli id devono restare unici anche dopo l'inlining di tutti i glifi insieme
dup="$(grep -oE 'id="[^"]*"' "$P" | sort | uniq -d | head -3)"
if [ -z "$dup" ]; then ok "nessun id duplicato nella pagina"; else bad "nessun id duplicato nella pagina ($dup)"; fi

# WB e la radice e non eredita: non deve avere una colonna di provenienza.
if ! grep -qF '<th>WB from</th>' "$P"; then ok "nessuna colonna per la radice"; else bad "nessuna colonna per la radice"; fi
if grep -q '# BEGIN sean' "$TMP/_data/navigation.yml"; then ok "blocco nav"; else bad "blocco nav"; fi
python3 "$HERE/publish.py" "$TMP" >/dev/null 2>&1
n="$(grep -c '# BEGIN sean' "$TMP/_data/navigation.yml")"
if [ "$n" -eq 1 ]; then ok "publish idempotente sul nav"; else bad "publish idempotente sul nav (blocchi: $n)"; fi

if [ "$checks" -ne "$EXPECTED_CHECKS" ]; then echo "  FAIL check eseguiti: $checks, attesi: $EXPECTED_CHECKS"; fail=1; fi
[ $fail -eq 0 ] && echo "TEST PUBLISH OK ($checks check)" || { echo "TEST PUBLISH FAIL"; exit 1; }
