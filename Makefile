TEX = xelatex -interaction=nonstopmode -halt-on-error
TEXINPUTS_ := $(CURDIR):

.PHONY: test clean render ref regress

test: ; @cd test && for f in *.tex; do [ "$$f" = seantest.tex ] && continue; echo "== $$f =="; \
	TEXINPUTS=$(TEXINPUTS_) $(TEX) $$f >/dev/null 2>&1 || { echo "FAIL $$f"; exit 1; }; \
	grep -q 'SEAN-OK' $${f%.tex}.log 2>/dev/null && echo "  markers ok" || true; done; echo "ALL TEX OK"
clean: ; find . -name '*.aux' -o -name '*.log' -o -name '*.xdv' | xargs rm -f
