# TODO — sean

## Omologazione WB (post cambio spessore connessioni)

- [ ] Omologare il font WB al nuovo peso delle connessioni `seg/*` (default). #sean #avanza #disc
  Le connessioni del motore ora sono a peso default (per combaciare coi glifi GS);
  i glifi WB sono `very thin`, quindi nei diagrammi WB i lacci risultano più spessi
  dei glifi. Decidere l'assetto finale: (a) glifi WB a peso default, (b) modello di
  spessore di connessione **per-font** (ogni font dichiara il proprio peso), (c) altro.
  Aprire issue su GitHub: il repo ora ha un remote → `github.com/s-e-a-m/sean` (`gh` presente).

## Lingua del vocabolario sulla pagina web

- [ ] Decidere come trattare le descrizioni dei segni sulla reference pubblica. #sean #avanza
  Oggi escono come stanno nel registro, in italiano, dentro una pagina la cui cornice è in inglese.
  Sono i nomi dei segni secondo l'Appendice 6 di Branchi: tradurli li staccherebbe dalla fonte,
  lasciarli soli non aiuta chi legge in inglese. Ipotesi: una glossa inglese accanto al termine
  italiano, da scrivere a mano (l'awk può estrarre solo ciò che è già nel sorgente).
  Sessione dedicata.

## Submodule WB → s-e-a-m

- [ ] Trasferire `wb-tdme-simboli` nell'org `s-e-a-m`, poi aggiornare `.gitmodules`
  (oggi punta a `git@gitlab.com:giuseppesilvi/wb-tdme-simboli.git`, branch `font-wb-puro`)
  al nuovo indirizzo `s-e-a-m`. Finché non avviene, il clone pubblico di `sean` non
  scarica il submodule senza chiave SSH GitLab. #sean #blocca
  **La priorità è salita**: ora che la reference è pubblicata su <https://s-e-a-m.github.io/sean/>,
  chi arriva dal sito e clona il repo non può rigenerare la pagina né compilare metà dei test.
  Pubblicare la documentazione di un repo che nessuno può compilare è una promessa a metà.
