.PHONY: install-stow
install-stow:
	@echo "Installing stow"
	@if ! command -v stow &>/dev/null; then \
		yay -S stow; \
	else \
		echo "Stow is already installed"; \
	fi

.PHONY: install-dotfiles
install-dotfiles:
	@echo "Installing dotfiles"
	@stow --adopt -t ~ .

.PHONY: help
help:
	@echo "This Makefile is used to install dotfiles"
	@echo ""
	@echo "Usage:"
	@echo "  make install-dotfiles - install dotfiles"
	@echo "  make install-stow     - install stow"
	@echo "  make help             - show this help message"
