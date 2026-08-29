# TODO — sean

## Omologazione WB (post cambio spessore connessioni)

- [ ] Omologare il font WB al nuovo peso delle connessioni `seg/*` (default). #sean #avanza #disc
  → issue [s-e-a-m/sean#3](https://github.com/s-e-a-m/sean/issues/3)
  Le connessioni del motore ora sono a peso default (per combaciare coi glifi GS);
  i glifi WB sono `very thin`, quindi nei diagrammi WB i lacci risultano più spessi
  dei glifi. Decidere l'assetto finale: (a) glifi WB a peso default, (b) modello di
  spessore di connessione **per-font** (ogni font dichiara il proprio peso), (c) altro.
  Aprire issue su GitHub: il repo ora ha un remote → `github.com/s-e-a-m/sean` (`gh` presente).

## Lingua del vocabolario sulla pagina web

- [ ] Decidere come trattare le descrizioni dei segni sulla reference pubblica. #sean #avanza
  → issue [s-e-a-m/sean#2](https://github.com/s-e-a-m/sean/issues/2)
  Oggi escono come stanno nel registro, in italiano, dentro una pagina la cui cornice è in inglese.
  Sono i nomi dei segni secondo l'Appendice 6 di Branchi: tradurli li staccherebbe dalla fonte,
  lasciarli soli non aiuta chi legge in inglese. Ipotesi: una glossa inglese accanto al termine
  italiano, da scrivere a mano (l'awk può estrarre solo ciò che è già nel sorgente).
  Sessione dedicata.

## Submodule WB → s-e-a-m

- [x] Trasferire `wb-tdme-simboli` nell'org `s-e-a-m` e aggiornare `.gitmodules`. #sean #blocca
  → issue [s-e-a-m/sean#1](https://github.com/s-e-a-m/sean/issues/1) — fatto il 2026-08-29.
  Il repo è ora <https://github.com/s-e-a-m/wb-tdme-simboli> (pubblico, default `font-wb-puro`)
  e `.gitmodules` lo raggiunge via HTTPS. Verificato da un clone anonimo, senza credenziali:
  `make test` arriva a `ALL TEX OK` e `make svg` rende gli 89 glifi.
  Il repo GitLab resta come archivio e non è stato toccato.

