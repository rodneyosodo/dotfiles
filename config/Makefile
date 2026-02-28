install-stow: ## Install GNU Stow if not already installed
	@echo "Installing stow"
	@if ! command -v stow &>/dev/null; then \
		yay -S stow; \
	else \
		echo "Stow is already installed"; \
	fi

install-dotfiles: ## Install dotfiles using stow
	@echo "Installing dotfiles"
	@stow --adopt -t ~ .

help: ## Show this help message
	@which awk > /dev/null || (echo "awk not found. Please install it from https://www.gnu.org/software/gawk/manual/gawk.html" && exit 1)
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-28s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
