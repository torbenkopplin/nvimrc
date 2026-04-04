local gh = function(url)
	return "https://github.com/" .. url
end

return {
	{ src = gh("n1ghtmare/noirblaze-vim") },
	{ src = gh("thaerkh/vim-workspace") },
	{ src = gh("tpope/vim-fugitive") },
	{ src = gh("junegunn/rainbow_parentheses.vim") },
	{
		src = gh("ibhagwan/fzf-lua"),
		req = "fzf-lua",
		opts = {
			winopts = {
				height = 0.40, -- bottom 40%
				width = 1.0,
				row = 1.0, -- place at bottom
				col = 0.5,
				border = 1,
			},
			fzf_opts = {
				["--layout"] = "reverse",
				["--info"] = "inline",
				["--history"] = vim.fn.stdpath("data") .. "/fzf-history",
			},
			preview = { default = "bat" },
		},
	},
	{ src = gh("neovim/nvim-lspconfig") },
	{ src = gh("nvim-tree/nvim-web-devicons") },
	{
		src = gh("nvim-treesitter/nvim-treesitter"),
		req = "nvim-treesitter",
		opts = {
			ensure_installed = { "javascript", "typescript", "jsdoc", "cpp", "lua", "html", "css", "json" },
			highlight = { enable = true },
		},
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
			ensure_installed = { "vimls", "ts_ls", "lua_ls", "eslint" },
		},
	},
}
