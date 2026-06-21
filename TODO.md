# TODO — sean

## Omologazione WB (post cambio spessore connessioni)

- [ ] Omologare il font WB al nuovo peso delle connessioni `seg/*` (default). #sean #avanza #disc
  Le connessioni del motore ora sono a peso default (per combaciare coi glifi GS);
  i glifi WB sono `very thin`, quindi nei diagrammi WB i lacci risultano più spessi
  dei glifi. Decidere l'assetto finale: (a) glifi WB a peso default, (b) modello di
  spessore di connessione **per-font** (ogni font dichiara il proprio peso), (c) altro.
  Aprire issue su GitHub: il repo ora ha un remote → `github.com/s-e-a-m/sean` (`gh` presente).

## Submodule WB → s-e-a-m

- [ ] Trasferire `wb-tdme-simboli` nell'org `s-e-a-m`, poi aggiornare `.gitmodules`
  (oggi punta a `git@gitlab.com:giuseppesilvi/wb-tdme-simboli.git`, branch `font-wb-puro`)
  al nuovo indirizzo `s-e-a-m`. Finché non avviene, il clone pubblico di `sean` non
  scarica il submodule senza chiave SSH GitLab. #sean #blocca
