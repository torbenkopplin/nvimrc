-- Options
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.wrap = false
vim.opt.termguicolors = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.o.winborder = "rounded"
vim.o.mouse = ""
vim.g.mapleader = " "

local keymap = vim.keymap.set

-- Editor keymaps
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

-- LSP / diagnostics keymaps
keymap("n", "<leader>e", vim.diagnostic.open_float)
keymap("n", "<leader>r", vim.lsp.buf.references)
keymap("n", "<leader>d", vim.lsp.buf.definition)
keymap("n", "<leader>s", vim.lsp.buf.rename)
keymap("n", "<leader>i", vim.lsp.buf.format)
keymap("n", "<CR>", vim.lsp.buf.definition)

-- Plugins
local gh = function(url) return "https://github.com/" .. url end
local plugs = {
  { src = gh("thaerkh/vim-workspace") },
  { src = gh("tpope/vim-fugitive") },
  { src = gh("junegunn/rainbow_parentheses.vim") },
  { src = gh("iamcco/markdown-preview.nvim") },
  { src = gh("neovim/nvim-lspconfig") },
  { src = gh("nvim-tree/nvim-web-devicons") },
  { src = gh("nvim-treesitter/nvim-treesitter") },
  { src = gh("nvim-treesitter/nvim-treesitter-textobjects") },
  {
    src = gh("ibhagwan/fzf-lua"),
    req = "fzf-lua",
    opts = {
      winopts = { height = 0.40, width = 1.0, row = 1.0, col = 0.5, border = 1 },
      fzf_opts = {
        ["--layout"]  = "reverse",
        ["--info"]    = "inline",
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

-- Treesitter (main branch needs explicit install + per-buffer start)
require("nvim-treesitter").install({
  "javascript", "typescript", "tsx", "jsdoc", "cpp", "lua",
  "html", "css", "json", "xml", "markdown",
})
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args) pcall(vim.treesitter.start, args.buf) end,
})

-- Treesitter textobjects
local ts_select = require("nvim-treesitter-textobjects.select").select_textobject
local ts_move = require("nvim-treesitter-textobjects.repeatable_move")
for lhs, q in pairs({
  af = "@function.outer", ["if"] = "@function.inner",
  ac = "@class.outer",    ic = "@class.inner",
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
keymap("n", "<leader>p", fzf.files,     { desc = "FZF: Files" })
keymap("n", "<leader>f", fzf.live_grep, { desc = "FZF: Live grep" })
keymap("n", "<leader>b", fzf.buffers,   { desc = "FZF: Buffers" })
keymap("n", "<leader>g", function() fzf.live_grep({ search = vim.fn.expand("<cword>") }) end,
  { desc = "FZF: Grep <cword>" })

-- Colorscheme + transparent backgrounds
vim.cmd.colorscheme("noirblaze")
for _, g in ipairs({
  "Normal", "NormalNC", "SignColumn", "MsgArea", "LineNr", "CursorLineNr",
  "NonText", "FoldColumn", "StatusLine", "StatusLineNC", "TabLine",
  "TabLineFill", "TabLineSel", "VertSplit", "EndOfBuffer", "PMenu",
  "PMenuSel", "PMenuThumb", "WildMenu",
}) do
  vim.api.nvim_set_hl(0, g, { bg = "none" })
end
vim.api.nvim_set_hl(0, "@function", { link = "Function" })

-- Persistence
local data = vim.fn.stdpath("data")
for _, dir in ipairs({ "/undo", "/swap", "/backup", "/workspace/sessions" }) do
  vim.fn.mkdir(data .. dir, "p")
end
vim.opt.undofile = true
vim.opt.undodir = data .. "/undo//"
vim.opt.directory = data .. "/swap//"
vim.opt.backupdir = data .. "/backup//"

-- vim-workspace
vim.g.workspace_session_directory = data .. "/workspace/sessions"
vim.g.workspace_undodir = data .. "/undo//"
vim.g.workspace_autocreate = 1
vim.g.workspace_autosave = 0

-- Rainbow parentheses
vim.api.nvim_set_var("rainbow#pairs", { { "(", ")" }, { "[", "]" }, { "{", "}" } })

-- LSP servers
local lsps = {
  ts_ls = {},
  eslint = {},
  vimls = {},
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

-- Drop noisy diagnostics: unused (tag 1) and TS "cannot find name" (2304/2552)
local orig_publish = vim.lsp.handlers["textDocument/publishDiagnostics"]
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
  if result and result.diagnostics then
    local is_ts = (vim.lsp.get_client_by_id(ctx.client_id) or {}).name == "ts_ls"
    result.diagnostics = vim.tbl_filter(function(d)
      if d.tags and vim.tbl_contains(d.tags, 1) then return false end
      if is_ts and (d.code == 2304 or d.code == 2552) then return false end
      return true
    end, result.diagnostics)
  end
  orig_publish(err, result, ctx, config)
end

-- Autocmds
local au = vim.api.nvim_create_autocmd
au("VimResized", { callback = function() vim.schedule(function() vim.cmd("wincmd =") end) end })
au("VimEnter",   { callback = function() vim.cmd("RainbowParentheses") end })

-- Markdown preview
vim.g.mkdp_theme      = "light"
vim.g.mkdp_auto_start = 1
vim.g.mkdp_port       = "8890"
vim.g.mkdp_browser    = "google-chrome"
vim.g.mkdp_open_ip    = "127.0.0.1"

-- :PackClean / :PackUpdate
vim.api.nvim_create_user_command("PackClean", function()
  local inactive = vim.tbl_map(function(p) return p.spec.name end,
    vim.tbl_filter(function(p) return not p.active end, vim.pack.get()))
  if #inactive == 0 then return vim.notify("No unused plugins.") end
  if vim.fn.confirm("Remove " .. #inactive .. " unused plugins?", "&Yes\n&No", 2) == 1 then
    vim.pack.del(inactive)
  end
end, { desc = "Remove unused plugins" })

vim.api.nvim_create_user_command("PackUpdate", function(opts)
  vim.pack.update(opts.fargs, { force = opts.bang })
end, { nargs = "*", bang = true, desc = "Update plugins" })
