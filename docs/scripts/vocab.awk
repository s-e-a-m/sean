# vocab.awk — dal registro TeX a un TSV: sezione, id, ancore, descrizione.
#
# Le sezioni sono i commenti "% --- nome ---"; le identita sono le righe
#   \seandeclaresymbol{id}{ancore}   % descrizione
# Le identita dichiarate inline nei font, fuori da ogni banner di sezione,
# finiscono in "estensioni".
BEGIN { section = "estensioni" }

# Nei font lo stesso formato "% --- ... ---" serve a due scopi: banner di
# sezione del vocabolario, e commento che introduce un singolo glifo. I secondi
# contengono sempre due punti ("% --- manometro: quadrante a cerchio ---"), i
# primi mai: e la sola cosa che li distingue senza indovinare.
/^% *--- .* --- *$/ {
  s = $0
  sub(/^% *--- */, "", s)
  sub(/ *--- *$/, "", s)
  if (index(s, ":") > 0) next
  section = s
  next
}

/\\seandeclaresymbol\{/ {
  line = $0
  if (match(line, /\\seandeclaresymbol\{[^}]*\}\{[^}]*\}/) == 0) next
  decl = substr(line, RSTART, RLENGTH)
  split(decl, p, /[{}]/)
  id = p[2]
  anchors = p[4]
  desc = ""
  rest = substr(line, RSTART + RLENGTH)
  if (match(rest, /%.*$/)) {
    desc = substr(rest, RSTART + 1)
    sub(/^ +/, "", desc)
    sub(/ +$/, "", desc)
  }
  printf "%s\t%s\t%s\t%s\n", section, id, anchors, desc
}
