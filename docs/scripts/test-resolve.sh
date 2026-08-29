#!/usr/bin/env bash
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/../.."
out="$(python3 "$HERE/resolve.py" "$ROOT")"

EXPECTED_CHECKS=6
fail=0; checks=0
ok()  { checks=$((checks+1)); echo "  ok   $1"; }
bad() { checks=$((checks+1)); echo "  FAIL $1"; fail=1; }
pair() { awk -F'\t' -v i="$1" -v f="$2" -v s="$3" '$1==i && $2==f && ($3==s||s==""){r=1} END{exit !r}'; }

if echo "$out" | pair gmic wb wb;   then ok "wb disegna gmic";       else bad "wb disegna gmic"; fi
if echo "$out" | pair gmic gs gs;   then ok "gs ridefinisce gmic";   else bad "gs ridefinisce gmic"; fi
if echo "$out" | pair am gs wb;     then ok "gs eredita am da wb";   else bad "gs eredita am da wb"; fi
if ! echo "$out" | pair preamp wb ""; then ok "wb non ha preamp";    else bad "wb non ha preamp"; fi
if echo "$out" | pair preamp gs gs; then ok "gs ha preamp";          else bad "gs ha preamp"; fi
n="$(echo "$out" | wc -l | tr -d ' ')"
if [ "$n" -gt 60 ]; then ok "oltre 60 coppie risolte ($n)"; else bad "oltre 60 coppie risolte (solo $n)"; fi

if [ "$checks" -ne "$EXPECTED_CHECKS" ]; then echo "  FAIL check eseguiti: $checks, attesi: $EXPECTED_CHECKS"; fail=1; fi
[ $fail -eq 0 ] && echo "TEST RESOLVE OK ($checks check)" || { echo "TEST RESOLVE FAIL"; exit 1; }
