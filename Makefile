# because I've developed this using bash, have set shell to bash for simplicity, likely to  work without (/bin/sh)
SHELL := /usr/bin/env bash
# variable assignments
drawings := $(sort $(wildcard drawings/*d.jpg))
coords := $(patsubst %d.jpg, %-c.csv, $(drawings))
# dummy files as rules that generate these produce multiple files
cropped := $(patsubst %-c.csv, %-cropped, $(coords))
filled := $(patsubst %cropped, %filled, $(cropped))

chapters := $(wildcard *.Rmd)
datasets := data/micropasts-neoaxes1.csv data/outlines.Rds

_book/dissertation.pdf : $(chapters) $(datasets)
	Rscript -e 'bookdown::render_book("index.Rmd")'

# helper target to print contents of variable
print-% : ; @echo $($*) | tr " " "\n"

data/outlines.Rds : $(filled)
	./scripts/momocs-outlines.R

# separate makefile for getting micropasts data
include micropasts.mk

# implicit rule to create silhouettes 
drawings/%-filled : drawings/%-c.csv drawings/%-cropped venv
	@# activate venv
	@# construct arguments to be passed to scripts/fill-view.py via `xargs`
	@# arguments are made from csv using `awk`
	source venv/bin/activate; \
	awk 'FNR > 1' $< \
	| ifne awk -F , '{print $$NF, $$NF}' \
	| ifne awk '{sub(".jpg", "-fill.jpg", $$2)}1' \
	| ifne xargs -n 2 ./scripts/fill-view.py
	touch $@

# implicit rule to crop drawings with imagemagick's `convert` program using coordinates from each csv 
drawings/%-cropped : drawings/%-c.csv
	@# remove header row of csv using `awk`
	@# pipe through `ifne` ('if not empty' tool from GNU moreutils) for safety
	@# construct arguments to be passed to `convert` via `xargs`
	@# `awk` fields - $6: input drawing, $3: width, $4: height, $1: x, $2: y, $NF: output filename
	awk 'FNR > 1' $< \
	| ifne awk -F , '{print $$6 " -crop " $$3 "x" $$4 "+" $$1 "+" $$2 " " $$NF}' \
	| ifne xargs -n 4 convert
	touch $@

# making one csv per drawing which contains coordinates for cropping
drawings/%-c.csv : drawings/%d.jpg venv scripts/view-finder.py
	source venv/bin/activate; ./scripts/view-finder.py $< $@

.PRECIOUS : $(coords)

# venv with Makefile inspired by https://stackoverflow.com/a/46188210
venv : venv/bin/activate

# making venv that depends on requirements.txt
venv/bin/activate : requirements.txt
	test -d venv || python3 -m venv venv
	source venv/bin/activate; pip install -r requirements.txt
	touch venv/bin/activate

# Docker
build : Dockerfile
	docker build -t neo-axes .

run :
	docker run -it --rm \
	-e PASSWORD=ucl \
	-e USERID=$$(id -u ${USER}) \
	-e GROUPID=$$(id -g ${USER}) \
	-e UMASK=022 \
	-v ${PWD}/renv/docker-cache:/home/rstudio/.local/share/renv/cache \
	-v ${PWD}/data:/home/rstudio/neo-axes/data \
	-v ${PWD}/drawings:/home/rstudio/neo-axes/drawings \
	-v ${PWD}/_book:/home/rstudio/neo-axes/_book \
	neo-axes \
	/bin/bash -c \
	". /etc/cont-init.d/userconf; \
	 su -s /usr/local/bin/R -c '-e renv::restore()' rstudio; \
	 su -s /bin/bash -c 'make -j$$((`nproc`+1))' rstudio"

clean :
	rm -rf venv
	rm -rf drawings/*-*
	rm -rf data/micropasts
	rm -f data/tasks.json
	rm -f data/micropasts-neoaxes1.csv
	rm -rf _book _bookdown_files
