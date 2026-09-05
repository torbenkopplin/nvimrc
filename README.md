# nvimrc

Neovim 0.12+ configuration.

## Layout

| Path | Content |
|---|---|
| `init.lua` | options, keymaps, plugin list, LSP/treesitter setup, autocmds |
| `lua/autopairs.lua` | hand-rolled auto-pairs, XML/HTML tag auto-close, smart `<CR>` |
| `lua/diagnostics-filter.lua` | drops noisy diagnostics (unused vars, TS "cannot find name") |
| `lua/eslint-deps.lua` | offers to run the package manager when eslint attaches without `node_modules` |
| `after/queries/` | treesitter highlight query overrides (xml, html) |

The colourscheme is **not** in here any more. It lives in
[torbenkopplin/noirblaze](https://github.com/torbenkopplin/noirblaze) and comes
in through `vim.pack.add` like any other plugin, because the same theme also
drives the desktop and two hand-edited copies do not stay in step.

> **`colors/noirblaze.lua` was deleted from this repo on purpose.** The config
> directory precedes packages on `runtimepath`, so a local copy silently shadows
> the plugin — you edit the theme in one place and neovim keeps drawing the
> other. If a `colors/noirblaze.lua` ever reappears here, that is a bug.

## Requirements

- Neovim ≥ 0.12 — required by nvim-treesitter's `main` branch
- git, `curl`, `tar`
- `gcc` or `clang` — compiles the treesitter parsers
- `tree-sitter-cli` ≥ 0.26.1 — nvim-treesitter `main` drives the build through it; without
  it *every* parser install fails. Install it from your package manager, **not** npm
  (Arch/CachyOS: `sudo pacman -S tree-sitter-cli`)
- Node.js + npm — required by mason to install several of the language servers

## First-time setup

**1. Clone into the Neovim config directory**

change `~/repos` where you want to keep your code.

```sh
mkdir -p ~/repos
cd ~/repos
git clone git@github.com:torbenkopplin/nvimrc
ln -s nvimrc ~/.config/nvim
```

**2. Start Neovim — everything auto-installs**

`vim.pack.add` downloads all plugins on first launch, the colourscheme among
them. Treesitter parsers are queued for compilation via `require("nvim-treesitter").install(...)`, and mason installs the LSP servers (`ensure_installed` in mason-lspconfig) plus extra tools like `stylua`.

Parser progress is reported through `vim.notify`; when all of them are done you get an
`Installed n/n languages` message. If `tree-sitter` is missing from `PATH`, the config warns
at startup and skips the install instead of failing per parser.

**3. Quit and reopen**

Parsers finish compiling on the first launch. A second start gives you full treesitter highlighting, including function parameter colours (`@variable.parameter`).

## LSP servers

All servers are installed automatically by mason on first launch — no manual installs needed.

| Server | Purpose |
|---|---|
| `tsgo` | TypeScript / JavaScript (TypeScript 7 native LSP) |
| `eslint` | Linting |
| `lua_ls` | Lua |
| `vimls` | Vimscript |
| `lemminx` | XML |

Parameter highlighting uses LSP semantic tokens (`@lsp.type.parameter`) in addition to treesitter, so it only appears once the servers are running.

## Verify

Run `:checkhealth lsp` and `:checkhealth nvim-treesitter` inside Neovim to confirm everything is wired up correctly.

For the colourscheme, `:echo g:colors_name` should say `noirblaze` and

```vim
:lua =vim.api.nvim_get_hl(0, { name = "Comment" })
```

should report `fg` as `9145255` (`#8b8b8b`). If it reports `5461843` (`#535353`)
you are running a stale local copy — check that no `colors/noirblaze.lua` exists
under this directory.

## Deploying is not committing

`~/.config/nvim` is a **real directory** — a second clone of this repository, not
a symlink to it — so a commit here changes nothing on screen until:

```sh
git -C ~/.config/nvim pull
```

The two can drift, and the symptom is a theme that will not change however many
times you edit it.
