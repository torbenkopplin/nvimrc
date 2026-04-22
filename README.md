# nvimrc

Neovim 0.11+ configuration.

## Requirements

- Neovim ≥ 0.11
- git
- `gcc` or `clang` — required for compiling treesitter parsers (`tree-sitter-cli` is **not** needed)
- Node.js — required for `ts_ls` and `eslint`

## First-time setup

**1. Clone into the Neovim config directory**

change `~/repos` where you want to keep your code.

```sh
mkdir -p ~/repos
cd ~/repos
git clone git@github.com:torbenkopplin/nvimrc
ln -s nvimrc ~/.config/nvim
```

**2. Start Neovim — plugins auto-install**

`vim.pack.add` downloads all plugins on first launch. Treesitter parsers are queued for compilation via `ensure_installed`.

**3. Quit and reopen**

Parsers finish compiling on the first launch. A second start gives you full treesitter highlighting, including function parameter colours (`@variable.parameter`).

## LSP servers

Parameter highlighting also uses LSP semantic tokens (`@lsp.type.parameter`) which requires the server binaries to be present in `PATH`. The config enables four servers:

| Server | Binary | Purpose |
|---|---|---|
| `ts_ls` | `typescript-language-server` | TypeScript / JavaScript |
| `eslint` | `vscode-eslint-language-server` | Linting |
| `lua_ls` | `lua-language-server` | Lua |
| `vimls` | `vim-language-server` | Vimscript |

### Arch / CachyOS

```sh
sudo pacman -S typescript-language-server lua-language-server vscode-langservers-extracted
npm install -g vim-language-server
```

### Ubuntu / Debian

```sh
sudo apt install gcc nodejs npm
npm install -g typescript-language-server typescript vim-language-server
```

`lua-language-server` is not in apt — install via snap or download a release binary:

```sh
sudo snap install lua-language-server
# or grab a release from https://github.com/LuaLS/lua-language-server/releases
```

### Other distros / npm

```sh
npm install -g typescript-language-server typescript vim-language-server
```

`lua-language-server` — see <https://luals.github.io/#other-install>

## Verify

Run `:checkhealth lsp` and `:checkhealth nvim-treesitter` inside Neovim to confirm everything is wired up correctly.
