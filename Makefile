# Welcome curious developer!
#
# Make is a build tool available on most (all?) UNIX based systems. For us,
# it's a great way to organize project tasks without worrying about existing
# system dependencies.
#
# make <task>

# Environment defaults
include ./.env

help:
	@ echo
	@ echo "  ${GREEN}start${RESET} – host a local web server."
	@ echo "  ${GREEN}docs${RESET}  – create pretty docs for lessons."
	@ echo

start:
	@ echo "${PLUS} running at $(SERVER_URL)"
	@ echo "${INFO} press ctrl + c when finished"
	@ python -m SimpleHTTPServer $(PORT) > /dev/null 2>&1

docs: $(patsubst %.md,%.html,$(wildcard lessons/**/README.md) README.md)

%.html: %.md
	@ echo "<meta charset='utf-8'>" > $(@D)/index.html
	@ cat $^ | node ./node_modules/nhunzaker-markdown/index >> $(@D)/index.html
	@ echo "${PLUS} $(@D)/index.html"
