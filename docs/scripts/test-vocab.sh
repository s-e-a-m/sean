#!/usr/bin/env bash
# I check usano awk -F'\t' e non grep -P: dentro uno script si usa /usr/bin/grep
# (BSD), che non ha -P, anche quando la shell interattiva instrada altrove.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$HERE/../.."
out="$(gawk -f "$HERE/vocab.awk" "$ROOT/lib/vocabulary-core.tex")"
gs="$(gawk -f "$HERE/vocab.awk" "$ROOT/fonts/gs/font-gs.tex")"

EXPECTED_CHECKS=10
fail=0; checks=0
ok()  { checks=$((checks+1)); echo "  ok   $1"; }
bad() { checks=$((checks+1)); echo "  FAIL $1"; fail=1; }
has() { awk -F'\t' -v a="$1" -v b="$2" -v c="$3" -v d="$4" \
        '(a==""||$1~a) && (b==""||$2==b) && (c==""||$3==c) && (d==""||$4==d){f=1} END{exit !f}'; }

n="$(echo "$out" | wc -l | tr -d ' ')"
if [ "$n" -eq 37 ]; then ok "37 identita nel canone"; else bad "37 identita nel canone (trovate $n)"; fi
if echo "$out" | has '^generatori$' gensin out "onde sinusoidali"; then ok "riga gensin completa"; else bad "riga gensin completa"; fi
if echo "$out" | has '^modulatori' am "in,out,mod" ""; then ok "ancore multiple"; else bad "ancore multiple"; fi
if echo "$out" | has '^sorgenti' ac "" ""; then ok "ancore vuote ammesse"; else bad "ancore vuote ammesse"; fi
if [ "$(echo "$out" | cut -f1 | sort -u | wc -l | tr -d ' ')" -eq 7 ]; then ok "7 sezioni"; else bad "7 sezioni"; fi

m="$(echo "$gs" | wc -l | tr -d ' ')"
if [ "$m" -eq 15 ]; then ok "15 estensioni GS"; else bad "15 estensioni GS (trovate $m)"; fi
if echo "$gs" | has '' preamp "in,out" ""; then ok "preamp estratto"; else bad "preamp estratto"; fi
if echo "$gs" | has '^estensioni$' preamp "" ""; then ok "sezione di default per le inline"; else bad "sezione di default per le inline"; fi

if echo "$gs" | has '^catena aria compressa' scuba out ""; then ok "catena aria compressa e una sezione"; else bad "catena aria compressa e una sezione"; fi
if [ "$(echo "$gs" | cut -f1 | grep -c ':')" -eq 0 ]; then ok "nessun commento-glifo preso per sezione"; else bad "nessun commento-glifo preso per sezione"; fi

if [ "$checks" -ne "$EXPECTED_CHECKS" ]; then echo "  FAIL check eseguiti: $checks, attesi: $EXPECTED_CHECKS"; fail=1; fi
[ $fail -eq 0 ] && echo "TEST VOCAB OK ($checks check)" || { echo "TEST VOCAB FAIL"; exit 1; }
