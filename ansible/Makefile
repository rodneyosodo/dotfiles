.PHONY: ping
ping:
	ansible-playbook playbooks/ping.yaml --connection=local

.PHONY: prep
prep:
	ansible-galaxy collection install community.general
	ansible-galaxy collection install kewlfft.aur

.PHONY: setup-desktop
setup-desktop: prep
	ansible-playbook playbooks/yay.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/pacman.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/packages/desktop.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/amd.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/audio.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/docker.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/go.yaml --connection=local
	ansible-playbook playbooks/rust.yaml --connection=local

.PHONY: install-desktop
install-desktop: prep
	ansible-playbook playbooks/packages/desktop.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/go.yaml --connection=local
	ansible-playbook playbooks/rust.yaml --connection=local

.PHONY: help
help:
	@echo "This Makefile is used to install dotfiles"
	@echo ""
	@echo "Usage:"
	@echo "  make ping            - ping the server"
	@echo "  make prep            - install ansible collections"
	@echo "  make setup-desktop   - install desktop packages(runs prep)"
	@echo "  make install-desktop - install desktop packages(runs prep)"
	@echo "  make help            - show this help message"
