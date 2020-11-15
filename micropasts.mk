nr-completed := $(shell curl -s -X GET -H \
	                'content-type: application/json' \
			https://crowdsourced.micropasts.org/project/neoaxes1/stats \
			| jq -r .n_completed_tasks)

offsets := $(shell seq 0 100 $(nr-completed) | tr '\n' ' ')

offsets-jsons := $(addprefix data/micropasts/,$(addsuffix .json,$(offsets)))

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
	./scripts/get_tasks | jq -s . > $@

data/micropasts-neoaxes1.csv : data/tasks.json $(offsets-jsons) data/info-ids.csv data/correction-sheet.csv
	./scripts/sheets.R
