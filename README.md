# Linux Journal

## Disto of choice

I have previously used Ubuntu, but I have recently switched to Arch Linux. I have found that Arch Linux is much more customizable and lightweight than Ubuntu. I also like the AUR, which is a repository of user-created packages. I have found that the AUR has almost every package I need, and it is very easy to install packages from the AUR.

I have shifted to Arch Linux as my primary distro for my PC, this is because:

- I like the AUR
- I like the Arch Wiki
- Sometimes staying on the bleeding edge is fun

I will continue and forever use Debian for my servers and workstations, this is because:

- I like the stability
- I like the community

This is somehow a goodbye to Ubuntu, I feel like I have outgrown it. I started using Ubuntu 2017 and I have been using it since then. I have learned a lot from Ubuntu, and I will forever be grateful for that. After 7 years the journey has come to an end. After all, Ubuntu is the reason why I am here today.

## Desktop Environment

GNOME is my desktop environment of choice. I like the simplicity of GNOME, and I like the way it looks. GNOME extensions are also very useful, and I use a lot of them. Though it is a bit heavy, I don't mind that.

## Installation

### Arch Linux

Follow the instructions in the [Arch](archinstall.md) section.

### Debian

Follow the instructions in the [Debian](debianinstall.md) section.

## Platform agnostic

### Install docker images

This is to help pull docker images ahead of time to avoid having to wait for them to download when you need them. It is done after installing docker.

```bash
bash docker/images.sh
```

### Install Python packages

This is done after installing python and pip.

```bash
pip install -r python/requirements.txt --break-system-packages
```

### Install Rust Packages

This is done after installing rust.

```bash
cargo install ouch du-dust exa bat fd-find ripgrep tealdeer cargo-generate jwt-cli wasm-pack
```

### Install Go Packages

This is done after installing go.

```bash
go install github.com/segmentio/kafka-go@latest
go install github.com/confluentinc/confluent-kafka-go/v2/kafka@latest
go install golang.org/x/website/tour@latest
go install golang.org/x/tools/cmd/godoc@latest
go install github.com/fullstorydev/grpcui/cmd/grpcui@latest
go install github.com/go-delve/delve/cmd/dlv@latest
go install github.com/google/pprof@latest
go install golang.org/x/tools/gopls@latest
go install golang.org/x/tools/gopls@latest
go install github.com/jesseduffield/lazygit@latest
go install github.com/goreleaser/goreleaser@latest
go install github.com/birdayz/kaf/cmd/kaf@latest
go install github.com/nats-io/gnatsd@latest
go install github.com/tetafro/godot/cmd/godot@latest
go install github.com/denis-tingaikin/go-header/cmd/go-header@latest
go install github.com/nats-io/natscli/nats@latest
go install golang.org/x/tools/cmd/goimports@latest
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
go install -v github.com/go-critic/go-critic/cmd/gocritic@latest
go install golang.org/dl/go1.10.7@latest
go install github.com/alexkohler/unimport@latest
go install github.com/takanorig/mqtt-bench@latest
go install github.com/k3d-io/k3d/v5@latest
go install github.com/derailed/k9s@latest
go install go.k6.io/xk6/cmd/xk6@latest
go install github.com/nats-io/nats-top@latest
```
