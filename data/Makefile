nr-completed := $(shell curl -s -X GET -H \
	                'content-type: application/json' \
			https://crowdsourced.micropasts.org/project/neoaxes1/stats \
			| jq -r .n_completed_tasks)

offsets := $(shell seq 0 100 $(nr-completed) | tr '\n' ' ')

offsets-jsons := $(addprefix micropasts/,$(addsuffix .json,$(offsets)))

all : $(offsets-jsons) tasks.json

print-% : ; @echo $($*) | tr " " "\n"

micropasts/%.json :
	@ mkdir -p micropasts
	curl -s -X GET \
	-H "content-type: application/json" \
	"https://crowdsourced.micropasts.org/api/taskrun\
	?project_id=496\
	&limit=100\
	&offset=$*" \
	> $@

tasks.json :
	./get_tasks | jq -s . > $@

clean :
	rm -rf micropasts
	rm -f tasks.json
