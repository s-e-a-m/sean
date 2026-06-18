TEX = xelatex -interaction=nonstopmode -halt-on-error
TEXINPUTS_ := $(CURDIR):
RENDER = pdftoppm -png -r 120

# Sorgenti che producono output visivo significativo (gli altri test sono solo asserzioni).
RENDER_SRCS = test/place.tex test/override.tex test/domains.tex test/font-wb.tex test/rotate.tex test/bridge.tex docs/catalog.tex fonts/gs/test/font-gs.tex

.PHONY: test clean render ref regress

TESTS = $(filter-out test/seantest.tex,$(wildcard test/*.tex) $(wildcard fonts/*/test/*.tex))

test: ; @ok=1; for f in $(TESTS); do d=$$(dirname $$f); b=$$(basename $$f); \
	echo "== $$f =="; \
	(cd $$d && TEXINPUTS=$(TEXINPUTS_) $(TEX) $$b >/dev/null 2>&1) || { echo "FAIL $$f"; ok=0; }; \
	grep -q 'SEAN-OK' $${f%.tex}.log 2>/dev/null && echo "  markers ok" || true; \
	done; [ $$ok = 1 ] && echo "ALL TEX OK" || exit 1

render: ; @for f in $(RENDER_SRCS); do d=$$(dirname $$f); b=$$(basename $$f .tex); \
	(cd $$d && TEXINPUTS=$(TEXINPUTS_) $(TEX) $$b.tex >/dev/null 2>&1 && $(RENDER) $$b.pdf $$b >/dev/null 2>&1) \
	&& echo "  rendered $$b" || echo "  SKIP $$b (compile fail)"; done; echo "render done"

ref: render ; @for f in $(RENDER_SRCS); do d=$$(dirname $$f); b=$$(basename $$f .tex); \
	case "$$d" in fonts/*/test) r="$${d%/test}/ref" ;; *) r="test/ref" ;; esac; \
	mkdir -p $$r; cp $$d/$$b-1.png $$r/$$b.png 2>/dev/null && echo "  ref $$b" || true; done; echo "ref updated"

regress: render ; @ok=1; for f in $(RENDER_SRCS); do d=$$(dirname $$f); b=$$(basename $$f .tex); \
	case "$$d" in fonts/*/test) r="$${d%/test}/ref" ;; *) r="test/ref" ;; esac; \
	if [ -f $$r/$$b.png ]; then \
	  if cmp -s $$d/$$b-1.png $$r/$$b.png; then echo "  ok $$b"; \
	  else echo "  DIFF $$b"; ok=0; fi; \
	else echo "  (no ref) $$b"; fi; done; \
	[ $$ok = 1 ] && echo "REGRESS OK" || { echo "REGRESS FAIL"; exit 1; }

clean: ; find . -name '*.aux' -o -name '*.log' -o -name '*.xdv' | xargs rm -f
