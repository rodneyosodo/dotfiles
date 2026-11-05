# Personal Notes to manage my dotfiles/machines

## Empty trash

```bash
rm -rf ~/.local/share/Trash/*
```

## Clear cache

```bash
rm -rf ~/.cache/*
```
qw
## Clean Downloads

```bash
du -h --max-depth=1 ~/Downloads 2>/dev/null | sort -hr | head -20
```

## Remove package cache

```bash
sudo pacman -Sc
```
