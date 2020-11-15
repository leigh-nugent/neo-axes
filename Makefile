SHELL := /usr/bin/env bash

drawings := $(sort $(wildcard drawings/*d.jpg))
coords := $(patsubst %d.jpg, %-c.csv, $(drawings))
cropped := $(patsubst %-c.csv, %-cropped, $(coords))
filled := $(patsubst %cropped, %filled, $(cropped))

all : $(filled) data/micropasts-neoaxes1.csv

print-% : ; @echo $($*) | tr " " "\n"

include micropasts.mk

drawings/%-filled : drawings/%-c.csv drawings/%-cropped .venv
	source .venv/bin/activate; \
	awk 'FNR > 1' $< \
	| ifne awk -F , '{print $$NF, $$NF}' \
	| ifne awk '{sub(".jpg", "-fill.jpg", $$2)}1' \
	| ifne xargs -n 2 ./scripts/fill-view.py
	touch $@

drawings/%-cropped : drawings/%-c.csv .venv
	awk 'FNR > 1' $< \
	| ifne awk -F , '{print $$6 " -crop " $$3 "x" $$4 "+" $$1 "+" $$2 " " $$NF}' \
	| ifne xargs -n 4 convert
	touch $@

drawings/%-c.csv : drawings/%d.jpg .venv scripts/view-finder.py
	source .venv/bin/activate; ./scripts/view-finder.py $< $@

.PRECIOUS : $(coords)

# venv inspired by https://stackoverflow.com/a/46188210
.venv : .venv/bin/activate

.venv/bin/activate : requirements.txt
	test -d .venv || python3 -m venv .venv
	source .venv/bin/activate; pip install -Ur requirements.txt
	touch .venv/bin/activate

clean :
	rm -rf .venv
	rm -rf drawings/*-*
	rm -rf data/micropasts
	rm -f data/tasks.json
	rm -f data/micropasts-neoaxes1.csv
