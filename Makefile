SH_SOURCES := $(shell find -mindepth 1 -maxdepth 1 \( -name '*.sh' -o -name '.sh.lib' \) | sort)

BROWSER = firefox
MARKDOWN = markdown

.DEFAULT_GOAL: check

.PHONY: check
check:
	shellcheck --format=gcc $(SH_SOURCES)

.PHONY: run
run: check run-only

.PHONY: run-only
run-only:
	./do-kb-onetime.sh
	./do-kb.sh

.PHONY: view-docs
view-docs: ./README.html
	$(BROWSER) $<

%.html: %.md
	$(MARKDOWN) $< > $@

.PHONY: clean
clean:
	rm *~ README.html
