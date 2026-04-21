vim.g.mapleader = " "
local keymap = vim.keymap.set
local ts_repeat_move = require("nvim-treesitter-textobjects.repeatable_move")
local select_to = require("nvim-treesitter-textobjects.select").select_textobject

keymap("n", "<leader>w", ":w<CR>")
keymap("n", "<leader>q", ":q<CR>")
keymap("n", "<Esc>", "<cmd>nohlsearch<CR><Esc>")
keymap({ "n", "v" }, "<Space>", "<Nop>", { silent = true })
keymap("n", "r", "<C-r>")

keymap("n", "<leader>e", function() vim.diagnostic.open_float() end)
-- LSP diagnostics maps
keymap("n", "<C-ä>", function() vim.diagnostic.jump({ count = 1 }) end)
keymap("n", "<C-å>", function() vim.diagnostic.jump({ count = -1 }) end)

keymap("n", "<leader>r", vim.lsp.buf.references)
keymap("n", "<leader>d", vim.lsp.buf.definition)
keymap("n", "<leader>s", vim.lsp.buf.rename)
keymap({ "n", "v" }, "<leader>i", vim.lsp.buf.format)

keymap("n", "`", "'")
keymap("n", "'", "`")

keymap("n", "j", "gj")
keymap("n", "gj", "j")
keymap("n", "k", "gk")
keymap("n", "gk", "k")

keymap("n", "-", "/")

-- keymaps
-- You can use the capture groups defined in `textobjects.scm`
keymap({ "x", "o" }, "af", function() select_to("@function.outer", "textobjects") end)
keymap({ "x", "o" }, "if", function() select_to("@function.inner", "textobjects") end)
keymap({ "x", "o" }, "ac", function() select_to("@class.outer", "textobjects") end)
keymap({ "x", "o" }, "ic", function() select_to("@class.inner", "textobjects") end)
-- You can also use captures from other query groups like `locals.scm`
keymap({ "x", "o" }, "as", function() select_to("@local.scope", "locals") end)
-- Repeat movement with ; and ,
-- ensure ; goes forward and , goes backward regardless of the last direction
keymap({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move_next)
keymap({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_previous)

-- vim way: ; goes to the direction you were moving.
-- keymap({ "n", "x", "o" }, ";", ts_repeat_move.repeat_last_move)
-- keymap({ "n", "x", "o" }, ",", ts_repeat_move.repeat_last_move_opposite)

-- Optionally, make builtin f, F, t, T also repeatable with ; and ,
keymap({ "n", "x", "o" }, "f", ts_repeat_move.builtin_f_expr, { expr = true })
keymap({ "n", "x", "o" }, "F", ts_repeat_move.builtin_F_expr, { expr = true })
keymap({ "n", "x", "o" }, "t", ts_repeat_move.builtin_t_expr, { expr = true })
keymap({ "n", "x", "o" }, "T", ts_repeat_move.builtin_T_expr, { expr = true })

-- (optional) default setup — adjust if you already call fzf.setup() elsewhere
local map_opts = { noremap = true, silent = true }
local fzf = require("fzf-lua")
-- Normal mode mappings (like your old fzf.vim mappings)
keymap("n", "<leader>p", function() fzf.files() end, vim.tbl_extend("force", map_opts, { desc = "FZF: Files" }))
keymap("n", "<leader>f", function() fzf.live_grep() end, vim.tbl_extend("force", map_opts, { desc = "FZF: Live grep (rg)" }))
keymap("n", "<leader>b", function() fzf.buffers() end, vim.tbl_extend("force", map_opts, { desc = "FZF: Buffers" }))
keymap("n", "<leader>g", function() fzf.live_grep({ search = vim.fn.expand("<cword>") }) end, vim.tbl_extend("force", map_opts, { desc = "FZF: Live grep (visual selection)" }))
