SH_SOURCES := $(shell find -mindepth 1 -maxdepth 1 \( -name '*.sh' -o -name '.sh.lib' \) | sort)

BROWSER = firefox
MARKDOWN = markdown

.DEFAULT_GOAL: check

.PHONY: check
check:
	shellcheck --format=gcc $(SH_SOURCES)

.PHONY: run
run: check
	./do-kb-onetime.sh
	./do-kb.sh

.PHONY: view-docs
view-docs: ./README.html
	$(BROWSER) $<

%.html: %.md
	$(MARKDOWN) $< > $@
