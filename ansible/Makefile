ping: ## Run a ping test to the server
	ansible-playbook playbooks/ping.yaml --connection=local

prep: ## Install ansible collections
	ansible-galaxy collection install community.general
	ansible-galaxy collection install kewlfft.aur

setup-desktop: prep ## Setup desktop environment (runs prep)
	ansible-playbook playbooks/yay.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/pacman.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/packages/desktop.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/amd.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/audio.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/docker.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/go.yaml --connection=local
	ansible-playbook playbooks/rust.yaml --connection=local

install-desktop: prep ## Install desktop packages (runs prep)
	ansible-playbook playbooks/packages/desktop.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/go.yaml --connection=local
	ansible-playbook playbooks/rust.yaml --connection=local

export-packages: ## Export installed packages to playbooks/packages/desktop.txt
	pacman -Qqe > playbooks/packages/desktop.txt

export-go-packages: ## Export installed go packages to playbooks/go.yaml
	python3 scripts/export_packages.py go playbooks/go.yaml

export-cargo-packages: ## Export installed cargo packages to playbooks/rust.yaml
	python3 scripts/export_packages.py cargo playbooks/rust.yaml

help: ## Show this help message
	@which awk > /dev/null || (echo "awk not found. Please install it from https://www.gnu.org/software/gawk/manual/gawk.html" && exit 1)
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[$$()% a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-28s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
