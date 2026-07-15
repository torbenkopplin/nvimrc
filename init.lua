-- Options (vim.o for scalars, vim.opt for list-valued options)
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.expandtab = true
vim.o.wrap = false
vim.o.scrolloff = 3
vim.o.termguicolors = true
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.laststatus = 3 -- single global statusline; windows divided by WinSeparator
vim.opt.completeopt = { "menu", "menuone", "noinsert", "popup", "fuzzy" }
vim.o.cursorline = true
vim.o.winborder = "rounded"
vim.o.mouse = ""
vim.g.mapleader = " "

function _G.git_branch()
  if vim.fn.exists("*FugitiveHead") == 0 then return "" end
  local branch = vim.fn.FugitiveHead()

  if branch ~= "" then return "%#StatusLineGit#  " .. branch .. " %*" end

  return ""
end

vim.o.statusline = table.concat({
  "%f",
  " %{%v:lua.git_branch()%}",
  "%=",
  "%l:%c",
})
-- Editor keymaps
local keymap = vim.keymap.set
keymap("n", "<leader>w", ":w<CR>")
keymap("n", "<leader>q", ":q<CR>")
keymap("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>")
keymap({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
keymap("n", "r", "<C-r>")
keymap("n", "`", "'")
keymap("n", "'", "`")
keymap("n", "j", "gj")
keymap("n", "gj", "j")
keymap("n", "k", "gk")
keymap("n", "gk", "k")
keymap("n", "-", "/")
keymap("n", "å", "[", { remap = true })
keymap("n", "ä", "]", { remap = true })
keymap("n", "<C-h>", "<C-w>h")
keymap("n", "<C-j>", "<C-w>j")
keymap("n", "<C-k>", "<C-w>k")
keymap("n", "<C-l>", "<C-w>l")

-- LSP / diagnostics keymaps
keymap("n", "<leader>e", vim.diagnostic.open_float)
keymap("n", "<leader>r", vim.lsp.buf.references)
keymap("n", "<leader>d", vim.lsp.buf.definition)
keymap("n", "<leader>s", vim.lsp.buf.rename)
keymap("n", "<leader>i", vim.lsp.buf.format)
keymap("n", "<CR>", vim.lsp.buf.definition)

-- Auto-pairs, tag auto-close, smart <CR>
require("autopairs")

-- Plugins
local gh = function(url) return "https://github.com/" .. url end
local plugs = {
  { src = gh("thaerkh/vim-workspace") },
  { src = gh("tpope/vim-fugitive") },
  { src = gh("junegunn/rainbow_parentheses.vim") },
  { src = gh("iamcco/markdown-preview.nvim") },
  { src = gh("neovim/nvim-lspconfig") },
  { src = gh("mason-org/mason.nvim"), req = "mason" },
  {
    src = gh("mason-org/mason-lspconfig.nvim"),
    req = "mason-lspconfig",
    opts = {
      ensure_installed = { "tsgo", "eslint", "vimls", "lua_ls", "lemminx" },
    },
  },
  { src = gh("nvim-tree/nvim-web-devicons") },
  { src = gh("nvim-treesitter/nvim-treesitter") },
  { src = gh("nvim-treesitter/nvim-treesitter-textobjects") },
  {
    src = gh("kevalin/mermaid.nvim"),
    req = "mermaid",
    opts = {
      lint = { enabled = true, command = "mmdc" },
      preview = { renderer = "mermaid.js", theme = "dark" },
    },
  },
  {
    src = gh("hedyhli/outline.nvim"),
    req = "outline",
    opts = {
      keymaps = {
        goto_location = "<S-CR>",
        peek_location = "o",
        goto_and_close = "<CR>",
      },
    },
  },
  {
    src = gh("ibhagwan/fzf-lua"),
    req = "fzf-lua",
    opts = {
      winopts = { height = 0.40, width = 1.0, row = 1.0, col = 0.5, border = 1 },
      fzf_opts = {
        ["--layout"] = "reverse",
        ["--info"] = "inline",
        ["--history"] = vim.fn.stdpath("data") .. "/fzf-history",
      },
      preview = { default = "bat" },
    },
  },
}

vim.pack.add(plugs)
for _, plug in ipairs(plugs) do
  if plug.req then require(plug.req).setup(plug.opts or {}) end
end

-- Mason tools beyond LSP servers (mason-lspconfig's ensure_installed only covers those)
local mason_registry = require("mason-registry")
mason_registry.refresh(function()
  for _, name in ipairs({ "stylua" }) do
    local pkg = mason_registry.get_package(name)
    if not pkg:is_installed() then pkg:install() end
  end
end)

-- Native undotree (bundled optional plugin)
vim.cmd.packadd("nvim.undotree")
keymap("n", "<leader>u", "<cmd>Undotree<CR>", { desc = "Toggle undotree" })

-- Treesitter (main branch needs explicit install + per-buffer start)
require("nvim-treesitter").install({
  "javascript",
  "typescript",
  "tsx",
  "jsdoc",
  "cpp",
  "lua",
  "html",
  "css",
  "json",
  "xml",
  "markdown",
  "mermaid",
})
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args) pcall(vim.treesitter.start, args.buf) end,
})

-- Treesitter textobjects
local ts_select = require("nvim-treesitter-textobjects.select").select_textobject
local ts_move = require("nvim-treesitter-textobjects.repeatable_move")
for lhs, q in pairs({
  af = "@function.outer",
  ["if"] = "@function.inner",
  ac = "@class.outer",
  ic = "@class.inner",
}) do
  keymap({ "x", "o" }, lhs, function() ts_select(q, "textobjects") end)
end
keymap({ "x", "o" }, "as", function() ts_select("@local.scope", "locals") end)
keymap({ "n", "x", "o" }, ";", ts_move.repeat_last_move_next)
keymap({ "n", "x", "o" }, ",", ts_move.repeat_last_move_previous)
keymap({ "n", "x", "o" }, "f", ts_move.builtin_f_expr, { expr = true })
keymap({ "n", "x", "o" }, "F", ts_move.builtin_F_expr, { expr = true })
keymap({ "n", "x", "o" }, "t", ts_move.builtin_t_expr, { expr = true })
keymap({ "n", "x", "o" }, "T", ts_move.builtin_T_expr, { expr = true })

-- FZF
local fzf = require("fzf-lua")
keymap("n", "<leader>p", fzf.files, { desc = "FZF: Files" })
keymap("n", "<leader>f", fzf.live_grep, { desc = "FZF: Live grep" })
keymap("n", "<leader>b", fzf.buffers, { desc = "FZF: Buffers" })
keymap(
  "n",
  "<leader>g",
  function() fzf.live_grep({ search = vim.fn.expand("<cword>") }) end,
  { desc = "FZF: Grep <cword>" }
)

-- Colorscheme + transparent backgrounds
vim.cmd.colorscheme("noirblaze")
for _, g in ipairs({
  "Normal",
  "NormalNC",
  "SignColumn",
  "MsgArea",
  "LineNr",
  "CursorLineNr",
  "NonText",
  "FoldColumn",
  "StatusLine",
  "StatusLineNC",
  "TabLine",
  "TabLineFill",
  "TabLineSel",
  "VertSplit",
  "EndOfBuffer",
  "PMenu",
  "PMenuThumb",
  "WildMenu",
}) do
  vim.api.nvim_set_hl(0, g, { bg = "none" })
end
vim.api.nvim_set_hl(0, "@function", { link = "Function" })

local function set_statusline_git_hl()
  local fg = vim.api.nvim_get_hl(0, { name = "Function", link = false }).fg
  vim.api.nvim_set_hl(0, "StatusLineGit", { fg = fg, bg = "none", bold = true })
end
set_statusline_git_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_statusline_git_hl })

-- Persistence
local data = vim.fn.stdpath("data")
for _, dir in ipairs({ "/undo", "/swap", "/backup", "/workspace/sessions" }) do
  vim.fn.mkdir(data .. dir, "p")
end
vim.o.undofile = true
vim.o.undodir = data .. "/undo//"
vim.o.directory = data .. "/swap//"
vim.o.backupdir = data .. "/backup//"

-- vim-workspace
vim.g.workspace_session_directory = data .. "/workspace/sessions"
vim.g.workspace_undodir = data .. "/undo//"
vim.g.workspace_autocreate = 1
vim.g.workspace_autosave = 0

-- Rainbow parentheses
vim.g["rainbow#pairs"] = { { "(", ")" }, { "[", "]" }, { "{", "}" } }

-- LSP servers
local lsps = {
  tsgo = {},
  eslint = {},
  vimls = {},
  lemminx = {},
  lua_ls = {
    settings = {
      Lua = {
        workspace = { library = vim.api.nvim_get_runtime_file("", true) },
        diagnostics = { globals = { "vim" } },
      },
    },
  },
}
for lsp, conf in pairs(lsps) do
  vim.lsp.config[lsp] = conf
  vim.lsp.enable(lsp)
end

-- Native LSP completion + signature help on attach
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, args.data.client_id, args.buf, { autotrigger = true })
    end
    if client:supports_method("textDocument/signatureHelp") then
      local chars = (client.server_capabilities.signatureHelpProvider or {}).triggerCharacters
        or { "(", "," }
      vim.api.nvim_create_autocmd("InsertCharPre", {
        buffer = args.buf,
        callback = function()
          local char = vim.v.char
          -- Whitespace keeps an already-open popup alive (CursorMovedI would
          -- otherwise close it on the next keystroke); it won't open a new one.
          local win = vim.b[args.buf].lsp_floating_preview
          local refresh_on_ws = char:match("%s") and win and vim.api.nvim_win_is_valid(win)
          if vim.tbl_contains(chars, char) or refresh_on_ws then
            vim.schedule(
              function() vim.lsp.buf.signature_help({ focus = false, silent = true }) end
            )
          end
        end,
      })
    end
  end,
})

-- Drop noisy diagnostics (unused vars, TS "cannot find name")
require("diagnostics-filter")

-- Autocmds
local au = vim.api.nvim_create_autocmd

-- Offer to install JS deps when eslint attaches but node_modules is missing
require("eslint-deps")

au("VimResized", {
  callback = function()
    vim.schedule(function() vim.cmd("wincmd =") end)
  end,
})

-- The runtime XML indenter (XmlIndentGet(v:lnum,1)) gates on legacy :syntax via
-- synID() to skip tags inside comments/strings. We highlight with Treesitter and
-- never enable :syntax, so that check always fails and nested tags stay flush.
-- Re-run it with the syntax check off (trailing arg 1 -> 0). Deferred so it lands
-- after the runtime indent file has set indentexpr.
au("FileType", {
  callback = function(args)
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(args.buf) then return end
      local ie = vim.bo[args.buf].indentexpr
      local fixed = ie:gsub("XmlIndentGet%(v:lnum,%s*1%)", "XmlIndentGet(v:lnum,0)")
      if fixed ~= ie then vim.bo[args.buf].indentexpr = fixed end
    end)
  end,
})
au("VimEnter", { callback = function() vim.cmd("RainbowParentheses") end })
au("FileType", {
  pattern = "mermaid",
  callback = function(args)
    keymap(
      "n",
      "<leader>mp",
      "<cmd>MermaidPreview<CR>",
      { buffer = args.buf, desc = "Mermaid preview" }
    )
    keymap(
      "n",
      "<leader>mf",
      "<cmd>MermaidFormat<CR>",
      { buffer = args.buf, desc = "Mermaid format" }
    )
  end,
})
au("FileType", {
  pattern = "qf",
  callback = function()
    keymap("n", "o", function()
      local qf_win = vim.api.nvim_get_current_win()
      local ln = vim.api.nvim_win_get_cursor(0)[1]
      vim.cmd(ln .. "cc")
      vim.api.nvim_set_current_win(qf_win)
    end, { buffer = true, silent = true })

    keymap("n", "<CR>", "<CR>:cclose<CR>", { buffer = true, silent = true })
  end,
})

-- Suppress OSC 9;4 progress sequences (kitty <0.36 forwards them to the desktop notification daemon)
vim.api.nvim_create_augroup("nvim.progress", { clear = true })

-- Markdown preview
vim.g.mkdp_theme = "dark"
vim.g.mkdp_auto_start = 0
vim.g.mkdp_port = "8890"
vim.g.mkdp_browser = vim.fn.executable("google-chrome") == 1 and "google-chrome" or "chromium"
vim.g.mkdp_open_ip = "127.0.0.1"

-- :PackClean / :PackUpdate
vim.api.nvim_create_user_command("PackClean", function()
  local inactive = vim.tbl_map(
    function(p) return p.spec.name end,
    vim.tbl_filter(function(p) return not p.active end, vim.pack.get())
  )
  if #inactive == 0 then return vim.notify("No unused plugins.") end
  if vim.fn.confirm("Remove " .. #inactive .. " unused plugins?", "&Yes\n&No", 2) == 1 then
    vim.pack.del(inactive)
  end
end, { desc = "Remove unused plugins" })

vim.api.nvim_create_user_command(
  "PackUpdate",
  function(opts) vim.pack.update(opts.fargs, { force = opts.bang }) end,
  { nargs = "*", bang = true, desc = "Update plugins" }
)

-- Outline
keymap("n", "<leader>o", "<cmd>Outline<CR>", { desc = "Toggle outline" })
