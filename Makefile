DOTFILES_DIR := $(CURDIR)
BOOTSTRAP    := $(DOTFILES_DIR)/bootstrap.sh

.DEFAULT_GOAL := help
.PHONY: help all packages shell symlinks git ssh claude vscode defaults

help:     ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

all:      ## Full fresh Mac setup (interactive — Xcode, Homebrew, clone + all modules)
	@bash $(BOOTSTRAP)

packages: ## Install Homebrew bundle (formulae, casks, fonts)
	@bash $(BOOTSTRAP) packages

shell:    ## Set up shell (Oh My Zsh, plugins, default shell)
	@bash $(BOOTSTRAP) shell

symlinks: ## Create dotfile symlinks
	@bash $(BOOTSTRAP) symlinks

git:      ## Configure git identity files per account
	@bash $(BOOTSTRAP) git

ssh:      ## Generate SSH keys for GitHub accounts
	@bash $(BOOTSTRAP) ssh

claude:   ## Set up Claude / MCP integrations
	@bash $(BOOTSTRAP) claude

vscode:   ## Install VS Code extensions
	@bash $(BOOTSTRAP) vscode

defaults: ## Apply macOS system preferences
	@bash $(BOOTSTRAP) defaults
