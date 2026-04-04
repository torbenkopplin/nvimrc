vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.wrap = false
vim.opt.termguicolors = true
vim.opt.splitbelow = true
vim.opt.splitright = true

vim.o.winborder = "rounded"
vim.o.mouse = ""

vim.g.mapleader = " "


local plugs = require("plugs")
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


vim.cmd.colorscheme("noirblaze")

-- make background transparent
local groups = {
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
	"PMenuSel",
	"PMenuThumb",
	"WildMenu",
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

local lsps = {
	ts_ls = {},
	eslint = {
		filetypes = { "javascript" }
	},
	eslint_d = {},
	lua_ls = {
		settings = {
			Lua = {
				diagnostics = {
					globals = { "vim", "require" },
				},
			},
		},
	},
	vimls = {},
}

for lsp, conf in pairs(lsps) do
	vim.lsp.config[lsp] = conf
	vim.lsp.enable(lsp)
end

local au = vim.api.nvim_create_autocmd

au("VimResized", {
	group = vim.api.nvim_create_augroup("autoresize_windows", { clear = true }),
	callback = function()
		vim.schedule(function()
			vim.cmd("wincmd =")
		end)
	end,
})

au("VimEnter", {
	callback = function()
		vim.cmd("RainbowParentheses")
	end,
})


require("keymaps")
