-- The LazyVim Rust extra (lazyvim.json) configures rustaceanvim and picks the
-- version for this Neovim; lazy-lock.json pins the commit. Only load it eagerly.
return {
  "mrcjkb/rustaceanvim",
  lazy = false,
}
