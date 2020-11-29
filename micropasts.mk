# getting number of completed tasks from micropasts api
nr-completed := $(shell curl -s -X GET -H \
	                'content-type: application/json' \
			https://crowdsourced.micropasts.org/project/neoaxes1/stats \
			| jq -r .n_completed_tasks)

# created sequence from 0 to nr-completed by increments of 100
offsets := $(shell seq 0 100 $(nr-completed) | tr '\n' ' ')

# add prefix and suffix to each member of sequence to create a list of json files to be made
offsets-jsons := $(addprefix data/micropasts/,$(addsuffix .json,$(offsets)))

# implicit rule to make the taskrun jsons by getting them from the API
data/micropasts/%.json :
	@ mkdir -p data/micropasts
	curl -s -X GET \
	-H "content-type: application/json" \
	"https://crowdsourced.micropasts.org/api/taskrun\
	?project_id=496\
	&limit=100\
	&offset=$*" \
	> $@

data/tasks.json :
	@# scripts/get_tasks actually writes json 'lines' to stdout
	@# so need to use jq to 'slurp' (-s) into a properly formatted json
	./scripts/get_tasks | jq -s . > $@

# makes csv of corrected micropasts data for analysis
data/micropasts-neoaxes1.csv : data/tasks.json $(offsets-jsons) data/info-ids.csv data/correction-sheet.csv
	./scripts/sheets.R
