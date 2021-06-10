.DEFAULT_GOAL := help

##
## Available Goals:
##

##   api     : Rebuilds and deploys the API component
##
.PHONY : api
api: tmp/last-build-api tmp/last-deployment-api

tmp/last-build-api: api/Dockerfile api/quipper/* api/test/* api/pytest.ini api/requirements-dev.txt api/setup.py
	@scripts/build api
	@touch tmp/last-build-api

tmp/last-deployment-api: api/api.yaml tmp/last-build-api
	@scripts/deploy-api
	@touch tmp/last-deployment-api

##   ui      : Rebuilds and deploys the UI component
##
.PHONY : ui
ui: tmp/last-build-ui tmp/last-deployment-ui

tmp/last-build-ui: ui/Dockerfile ui/*.jpg ui/index.html
	@scripts/build ui
	@touch tmp/last-build-ui

tmp/last-deployment-ui: ui/ui.yaml tmp/last-build-ui
	@scripts/deploy-ui
	@touch tmp/last-deployment-ui

# From: https://swcarpentry.github.io/make-novice/08-self-doc/index.html
##   help    : Print this help message
##
.PHONY : help
help : Makefile
	@sed -n 's/^##//p' $<
