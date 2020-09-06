SHELL := /usr/bin/env bash

pdfs := $(sort $(shell find drawings-and-forms/ -type f -name '*.pdf'))
jpgs := $(subst drawings-and-forms, extracted-jpgs, $(patsubst %.pdf, %-000.jpg, $(pdfs)))

find-jp2 = $(shell find $@/ -type f -name '*.jp2')

all : extracted-jpgs

extracted-jpgs: drawings-and-forms $(jpgs)
	-[ ! -z "$(find-jp2)" ] && convert $(find-jp2) $(patsubst %.jp2, %.jpg, $(find-jp2))
	-[ ! -z "$(find-jp2)" ] && rm $(find-jp2)

print-% : ; @echo $* = $($*) | tr " " "\n"

extracted-jpgs/%-000.jpg : drawings-and-forms/%.pdf
	@ mkdir -p extracted-jpgs/{flint,stone}
	pdfimages -all $< $(subst drawings-and-forms, extracted-jpgs, $(basename $<))

clean :
	rm -rf extracted-jpgs
