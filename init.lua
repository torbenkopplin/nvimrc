require("opts")
require("plugs")
require("keymaps")
require("nb").setup()

-- vim.cmd.colorscheme("noirblaze")
--
-- -- make background transparent
-- local groups = {
-- 	"Normal",
-- 	"NormalNC",
-- 	"SignColumn",
-- 	"MsgArea",
-- 	"LineNr",
-- 	"CursorLineNr",
-- 	"NonText",
-- 	"FoldColumn",
-- 	"StatusLine",
-- 	"StatusLineNC",
-- 	"TabLine",
-- 	"TabLineFill",
-- 	"TabLineSel",
-- 	"VertSplit",
-- 	"EndOfBuffer",
-- 	"PMenu",
-- 	"PMenuSel",
-- 	"PMenuThumb",
-- 	"WildMenu",
-- }
--
-- for _, group in ipairs(groups) do
-- 	vim.api.nvim_set_hl(0, group, { bg = "none" })
-- end
--
-- -- vim.api.nvim_set_hl(0, "@lsp.type.parameter", { link = "Hlargs" })
-- vim.api.nvim_set_hl(0, "@function", { link = "Function" })
--

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


