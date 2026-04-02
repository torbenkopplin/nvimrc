vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.wrap = false
vim.opt.termguicolors = true
vim.opt.splitbelow = true
vim.opt.splitright = true

vim.o.winborder = "rounded"
vim.o.mouse = ""

vim.g.mapleader = ' '

local keymap = vim.keymap.set

keymap('n', '<leader>w', ':w<CR>')
keymap('n', '<leader>q', ':q<CR>')
keymap('n', '<Esc>', '<cmd>nohlsearch<CR><Esc>')
keymap({'n', 'v'}, '<Space>', '<Nop>', { silent = true })
keymap('n', 'r', '<C-r>')

keymap('n', '<leader>e', function() vim.diagnostic.open_float() end)

keymap('n', '<leader>r', vim.lsp.buf.references)
keymap('n', '<leader>d', vim.lsp.buf.definition)
keymap('n', '<leader>s', vim.lsp.buf.rename)

keymap('n', '`', "'")
keymap('n', "'", '`')

keymap('n', 'j', 'gj')
keymap('n', 'gj', 'j')
keymap('n', 'k', 'gk')
keymap('n', 'gk', 'k')

keymap('n', '-', '/')

local gh = function(url) return "https://github.com/" .. url end
local plugs = {
	{ src = gh("n1ghtmare/noirblaze-vim"), },
	{ src = gh("thaerkh/vim-workspace"), },
	{ src = gh("tpope/vim-fugitive"), },
	{ src = gh("junegunn/rainbow_parentheses.vim") },
  { 
		src = gh("ibhagwan/fzf-lua"), 
		req = "fzf-lua",
		opts = {
			winopts = {
				height = 0.40,  -- bottom 40%
				width  = 1.0,
				row    = 1.0,   -- place at bottom
				col    = 0.5,
				border = 1,
			},
			fzf_opts = {
				["--layout"] = "reverse",
				["--info"]   = "inline",
				["--history"] = vim.fn.stdpath("data") .. "/fzf-history",
			},
			preview = { default = "bat" },
		}
	},
	{ src = gh("neovim/nvim-lspconfig") },
	{ src = gh("nvim-tree/nvim-web-devicons") },
	{ 
		src = gh("nvim-treesitter/nvim-treesitter"),
		req = "nvim-treesitter",
		opts = {
			ensure_installed = { "javascript", "typescript", "jsdoc", "cpp", "lua", "html", "css", "json" },
			highlight = { enable = true, },
		}
	},
	{ 
		src = gh("nvim-treesitter/nvim-treesitter-textobjects"),
		req = "nvim-treesitter-textobjects",
	},
	{ src = gh("mason-org/mason.nvim"), req = "mason" },
	{ 
		src = gh("mason-org/mason-lspconfig.nvim"),
		req = "mason-lspconfig",
		opts = {
			ensure_installed = { 'vimls', 'ts_ls', 'lua_ls', 'eslint' }
		},
	},
}

vim.pack.add(plugs)
for _, plug in pairs(plugs) do
	if plug.req then
		if plug.opts then
			require(plug.req).setup(plug.opts)
		else
			require(plug.req).setup()
		end
	end
end

-- (optional) default setup — adjust if you already call fzf.setup() elsewhere
local map_opts = { noremap = true, silent = true }
local fzf = require("fzf-lua")
-- Normal mode mappings (like your old fzf.vim mappings)
keymap("n", "<leader>p", function() fzf.files() end, vim.tbl_extend("force", map_opts, { desc = "FZF: Files" }))
keymap("n", "<leader>f", function() fzf.live_grep() end, vim.tbl_extend("force", map_opts, { desc = "FZF: Live grep (rg)" }))
keymap("n", "<leader>b", function() fzf.buffers() end, vim.tbl_extend("force", map_opts, { desc = "FZF: Buffers" }))
keymap("n", "<leader>g", function()
	fzf.live_grep({ search = vim.fn.expand("<cword>") })
end, vim.tbl_extend("force", map_opts, { desc = "FZF: Live grep (visual selection)" }))

vim.cmd.colorscheme("noirblaze")

-- make background transparent
local groups = {
	"Normal", "NormalNC", "SignColumn", "MsgArea", "LineNr", "CursorLineNr",
	"NonText", "FoldColumn", "StatusLine", "StatusLineNC", "TabLine",
	"TabLineFill", "TabLineSel", "VertSplit", "EndOfBuffer", "PMenu",
	"PMenuSel", "PMenuThumb", "WildMenu"
}

for _, group in ipairs(groups) do
	vim.api.nvim_set_hl(0, group, { bg = "none" })
end

-- vim.api.nvim_set_hl(0, "@lsp.type.parameter", { link = "Hlargs" })
vim.api.nvim_set_hl(0, "@function", { link = "Function" })

-- Workspace options
local data = vim.fn.stdpath("data")
local dirs = {
	data .. "/undo",
	data .. "/swap",
	data .. "/backup",
	data .. "/workspace/sessions",
}

for _, dir in ipairs(dirs) do
	if vim.fn.isdirectory(dir) == 0 then
		vim.fn.mkdir(dir, "p")
	end
end

vim.opt.undofile = true
vim.opt.undodir = data .. "/undo//"
vim.opt.directory = data .. "/swap//"
vim.opt.backupdir = data .. "/backup//"

vim.g.workspace_session_directory = data .. "/workspace/sessions"
vim.g.workspace_undodir = data .. "/undo//"
vim.g.workspace_autocreate = 1
vim.g.workspace_autosave = 0

vim.g.rainbow_pairs = [['(', ')'], ['[', ']']]

local lsps = {
	ts_ls = {},
	eslint = {},
	eslint_d = {},
	lua_ls = {},
}

for lsp, conf in pairs(lsps) do
	vim.lsp.config[lsp] = conf
	vim.lsp.enable(lsp)
end

local au = vim.api.nvim_create_autocmd

au('VimResized', {
	group = vim.api.nvim_create_augroup('autoresize_windows', { clear = true}),
	callback = function()
		vim.schedule(function()
			vim.cmd('wincmd =')
		end)
	end,
})

au('VimEnter', {
	callback = function()
		vim.cmd('RainbowParentheses')
	end
})

local ts_repeat_move = require "nvim-treesitter-textobjects.repeatable_move"
local select_to = require "nvim-treesitter-textobjects.select".select_textobject

-- keymaps
-- You can use the capture groups defined in `textobjects.scm`
vim.keymap.set({ "x", "o" }, "af", function() select_to("@function.outer", "textobjects") end)
vim.keymap.set({ "x", "o" }, "if", function() select_to("@function.inner", "textobjects") end)
vim.keymap.set({ "x", "o" }, "ac", function() select_to("@class.outer", "textobjects") end)
vim.keymap.set({ "x", "o" }, "ic", function() select_to("@class.inner", "textobjects") end)
-- You can also use captures from other query groups like `locals.scm`
vim.keymap.set({ "x", "o" }, "as", function() select_to("@local.scope", "locals") end)
-- Repeat movement with ; and ,
-- ensure ; goes forward and , goes backward regardless of the last direction
vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)

-- vim way: ; goes to the direction you were moving.
-- vim.keymap.set({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
-- vim.keymap.set({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)

-- Optionally, make builtin f, F, t, T also repeatable with ; and ,
vim.keymap.set({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
vim.keymap.set({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })
