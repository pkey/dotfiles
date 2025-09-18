
.PHONY: pre-commit-install
pre-commit-install: ## Install pre-commit hooks
	pre-commit install

.PHONY: pre-commit-run
pre-commit-run: ## Run pre-commit hooks on all files
	pre-commit run --all-files

.PHONY: pre-commit-update
pre-commit-update: ## Update pre-commit hook versions
	pre-commit autoupdate

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
