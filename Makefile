NODE=$(shell which node 2> /dev/null)
NPM=$(shell which npm 2> /dev/null)
YARN=$(shell which yarn 2> /dev/null)
JQ=$(shell which jq 2> /dev/null)

PKM?=$(if $(YARN),$(YARN),$(shell which npm))

REMOTE="https://github.com/jereleao/react-dialog-controller"
CURRENT_VERSION:=$(shell jq ".version" package.json)

BRANCH=$(shell git rev-parse --abbrev-ref HEAD)

RELEASE?=true;

VERSION:=$(if $(RELEASE),$(shell read -p "Release $(CURRENT_VERSION) -> " V && echo $$V),"HEAD")

help:
	@echo
	@echo "Current version: $(CURRENT_VERSION)"
	@echo
	@echo "List of commands:"
	@echo
	@echo "  make info             - display node, npm and yarn versions..."
	@echo "  make deps             - install all dependencies."
	@echo "  make lint             - run lint."
	@echo "  make build            - build project artifacts."
	@echo "  make publish          - build and publish version on npm."

info:
	@[[ ! -z "$(NODE)" ]] && echo node version: `$(NODE) --version` "$(NODE)"
	@[[ ! -z "$(PKM)" ]] && echo $(shell basename $(PKM)) version: `$(PKM) --version` "$(PKM)"
	@[[ ! -z "$(JQ)" ]] && echo jq version: `$(JQ) --version` "$(JQ)"

deps: deps-project

deps-project:
	@$(shell basename $(PKM)) install

# Rules for development

lint:
	@npm run lint

# Rules for build and publish

check-working-tree:
	@[ -z "`git status -s`" ] && \
	echo "Stopping publish. There are change to commit or discard." || echo "Worktree is clean."

build: 
	@echo "[Building]"
	@npm run build

pre-release-commit:
	git commit --allow-empty -m "Release v$(VERSION)."

changelog:
	@echo "[Updating CHANGELOG.md $(CURRENT_VERSION) > $(VERSION)]"
	python ./scripts/changelog.py -a $(VERSION) > CHANGELOG.md

update-package-version:
	cat package.json | jq '.version="$(VERSION)"' > tmp; mv -f tmp package.json

release-commit: pre-release-commit update-package-version changelog
	@git add .
	@git commit --amend -m "`git log -1 --format=%s`"

release-tag:
	git tag "v$(VERSION)" -m "`python ./scripts/changelog.py -c $(VERSION)`"

publish-version: release-commit release-tag
	@echo "[Publishing]"
	git push $(REMOTE) "$(BRANCH)" "v$(VERSION)"
	npm publish

pre-publish: clean
pre-build: deps-project build

publish: check-working-tree pre-publish pre-build publish-version publish-finished

publish-finished: clean

# Rules for clean up

clean-build:
	@rm -rf lib/*

clean: clean-build
