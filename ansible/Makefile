.PHONY: ping
ping:
	ansible-playbook playbooks/ping.yaml --connection=local

.PHONY: prep
prep:
	ansible-galaxy collection install community.general
	ansible-galaxy collection install kewlfft.aur

.PHONY: install-desktop
install-desktop: prep
	ansible-playbook playbooks/environment.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/yay.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/pacman.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/packages/desktop.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/amd.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/audio.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/docker.yaml --connection=local --ask-become-pass
	ansible-playbook playbooks/go.yaml --connection=local
	ansible-playbook playbooks/rust.yaml --connection=local
