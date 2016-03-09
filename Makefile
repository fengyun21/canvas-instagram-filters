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
	@ echo

start:
	@ echo "${PLUS} running at $(SERVER_URL)"
	@ echo "${INFO} press ctrl + c when finished"
	@ python -m SimpleHTTPServer $(PORT) > /dev/null 2>&1
