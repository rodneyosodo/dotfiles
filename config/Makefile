.PHONY: help install-stow install-dotfiles

help: ## Show this help message
	@which awk > /dev/null || (echo "awk not found. Please install it from https://www.gnu.org/software/gawk/manual/gawk.html" && exit 1)
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-28s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

install-stow: ## Install GNU Stow if not already installed
	@echo "Checking for Stow..."
	@if command -v stow &>/dev/null; then \
		echo "Stow is already installed"; \
	else \
		echo "Installing Stow..."; \
		yay -S stow || { echo "Failed to install Stow"; exit 1; }; \
		echo "Stow installed successfully"; \
	fi

install-dotfiles: ## Install dotfiles using stow
	@echo "Installing dotfiles..."
	@stow --adopt -t ~ . || { echo "Failed to install dotfiles"; exit 1; }
	@echo "Dotfiles installed successfully"

backup-dotfiles: ## Backup existing dotfiles before installing
	@echo "Creating backup of existing dotfiles..."
	@BACKUP_DIR="$${HOME}/.dotfiles-backup-$$(date +%Y%m%d_%H%M%S)"; \
	mkdir -p "$$BACKUP_DIR"; \
	for file in .zshrc .gitconfig .p10k.zsh; do \
		if [[ -f "$$HOME/$$file" ]]; then \
			cp "$$HOME/$$file" "$$BACKUP_DIR/"; \
			echo "Backed up $$file"; \
		fi; \
	done; \
	echo "Backup created at $$BACKUP_DIR"

clean: ## Remove broken symlinks
	@echo "Removing broken symlinks..."
	@find -L "$$HOME" -maxdepth 1 -type l -exec rm {} + 2>/dev/null || true
	@echo "Broken symlinks removed"