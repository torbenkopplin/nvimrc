# nvimrc

Neovim 0.11+ configuration.

## Layout

| Path | Content |
|---|---|
| `init.lua` | options, keymaps, plugin list, LSP/treesitter setup, autocmds |
| `lua/autopairs.lua` | hand-rolled auto-pairs, XML/HTML tag auto-close, smart `<CR>` |
| `lua/diagnostics-filter.lua` | drops noisy diagnostics (unused vars, TS "cannot find name") |
| `lua/eslint-deps.lua` | offers to run the package manager when eslint attaches without `node_modules` |
| `colors/noirblaze.lua` | colorscheme |
| `after/queries/` | treesitter highlight query overrides (xml, html) |

## Requirements

- Neovim ≥ 0.11
- git
- `gcc` or `clang` — required for compiling treesitter parsers (`tree-sitter-cli` is **not** needed)
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

`vim.pack.add` downloads all plugins on first launch. Treesitter parsers are queued for compilation via `require("nvim-treesitter").install(...)`, and mason installs the LSP servers (`ensure_installed` in mason-lspconfig) plus extra tools like `stylua`.

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
