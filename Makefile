SHELL := /usr/bin/env bash

pdfs := $(sort $(shell find drawings-and-forms/ -type f -name '*.pdf'))
jpgs := $(subst drawings-and-forms, extracted-jpgs, $(patsubst %.pdf, %-000.jpg, $(pdfs)))

drawings := $(sort $(wildcard drawings/*.jpg))
coords := $(patsubst %.jpg, %.csv, $(drawings))

find-jp2 = $(shell find $@/ -type f -name '*.jp2')

all : $(coords)

print-% : ; @echo $* = $($*) | tr " " "\n"

drawings/%.csv : drawings/%.jpg .venv
	source .venv/bin/activate; ./scripts/view-finder.py $< $@

extracted-jpgs : drawings-and-forms $(jpgs)
	-[ ! -z "$(find-jp2)" ] && convert $(find-jp2) $(patsubst %.jp2, %.jpg, $(find-jp2))
	-[ ! -z "$(find-jp2)" ] && rm $(find-jp2)

extracted-jpgs/%-000.jpg : drawings-and-forms/%.pdf
	@ mkdir -p extracted-jpgs/{flint,stone}
	pdfimages -all $< $(subst drawings-and-forms, extracted-jpgs, $(basename $<))

# venv inspired by https://stackoverflow.com/a/46188210

.venv : .venv/bin/activate

.venv/bin/activate : requirements.txt
	test -d .venv || python3 -m venv .venv
	source .venv/bin/activate; pip install -Ur requirements.txt
	touch .venv/bin/activate

clean :
	rm -rf extracted-jpgs
	rm -rf .venv
	find -iname "*.pyc" -delete
	rm drawings/*.csv
