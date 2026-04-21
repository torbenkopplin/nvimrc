vim.opt.background = "dark"
vim.g.colors_name = "noirblaze"

local hi = function(group, opts) vim.api.nvim_set_hl(0, group, opts) end

local c = {
  bg        = "#121212",
  bg2       = "#212121",
  bg3       = "#323232",
  dim1      = "#535353",
  dim2      = "#737373",
  dim3      = "#787878",
  dim4      = "#7a7a7a",
  mid       = "#949494",
  fg4       = "#a7a7a7",
  fg3       = "#b0b0b0",
  fg2       = "#b4b4b4",
  fg1       = "#d5d5d5",
  fg0       = "#f5f5f5",
  white     = "#ffffff",
  pink      = "#ff0088",
}

-- Base
hi("Normal",        { fg = c.fg2,   bg = c.bg })
hi("NormalNC",      { fg = c.fg2,   bg = c.bg })
hi("Comment",       { fg = c.dim1,  italic = true })
hi("Constant",      { fg = c.pink })
hi("String",        { fg = c.dim3 })
hi("Character",     { fg = c.dim3 })
hi("Number",        { fg = c.pink })
hi("Boolean",       { fg = c.pink })
hi("Float",         { fg = c.pink })
hi("Identifier",    { fg = c.white })
hi("Function",      { fg = c.pink })
hi("Statement",     { fg = c.fg3 })
hi("Keyword",       { fg = c.mid })
hi("Conditional",   { fg = c.mid })
hi("Repeat",        { fg = c.mid })
hi("Label",         { fg = c.mid })
hi("Operator",      { fg = c.fg3 })
hi("Exception",     { fg = c.pink })
hi("PreProc",       { fg = c.pink })
hi("Include",       { fg = c.dim2 })
hi("Define",        { fg = c.pink })
hi("Macro",         { fg = c.pink })
hi("Type",          { fg = c.dim4 })
hi("StorageClass",  { fg = c.dim2 })
hi("Structure",     { fg = c.dim2 })
hi("Typedef",       { fg = c.dim2 })
hi("Special",       { fg = c.dim3 })
hi("Underlined",    { fg = c.fg3,   underline = true })
hi("Error",         { fg = c.pink,  bg = c.bg3 })
hi("Todo",          { fg = c.pink,  bg = c.bg3,  bold = true })
hi("Title",         { fg = c.fg3,   bold = true })

-- UI chrome
hi("ColorColumn",   { bg = c.bg3 })
hi("CursorLine",    { bg = c.bg2 })
hi("CursorColumn",  { bg = c.bg2 })
hi("CursorLineNr",  { fg = c.dim2, bg = c.bg3 })
hi("LineNr",        { fg = c.bg3,  bg = c.bg })
hi("SignColumn",    { bg = c.bg })
hi("FoldColumn",    { fg = c.mid,  bg = c.bg3 })
hi("Folded",        { fg = c.mid,  bg = c.bg3 })
hi("VertSplit",     { fg = c.bg2,  bg = c.bg2 })
hi("WinSeparator",  { fg = c.bg2,  bg = c.bg2 })
hi("StatusLine",    { fg = c.mid,  bg = c.bg3 })
hi("StatusLineNC",  { fg = c.dim1, bg = c.bg3 })
hi("TabLine",       { fg = c.fg2,  bg = c.bg3 })
hi("TabLineFill",   { bg = c.bg3 })
hi("TabLineSel",    { fg = c.fg1,  bg = c.bg })
hi("Visual",        { bg = c.bg3 })
hi("VisualNOS",     { fg = c.pink, bg = c.bg3 })
hi("Search",        { fg = c.bg,   bg = c.white })
hi("IncSearch",     { fg = c.bg,   bg = c.white })
hi("CurSearch",     { fg = c.bg,   bg = c.pink })
hi("MatchParen",    { bg = c.dim1, bold = true })
hi("Conceal",       { fg = c.dim1 })
hi("NonText",       { fg = c.bg3 })
hi("SpecialKey",    { fg = c.dim4, bg = c.bg })
hi("Directory",     { fg = c.fg3 })
hi("Question",      { fg = c.fg0,  bg = c.bg3 })
hi("MoreMsg",       { fg = c.bg,   bg = c.dim3 })
hi("WarningMsg",    { fg = c.pink })
hi("ErrorMsg",      { fg = c.fg0,  bg = c.pink })
hi("WildMenu",      { fg = c.dim3, bg = c.bg3 })

-- Popup menu
hi("Pmenu",         { fg = c.fg1,  bg = c.bg3 })
hi("PmenuSel",      { fg = c.white, bg = c.dim1, bold = true })
hi("PmenuSbar",     { bg = c.bg3 })
hi("PmenuThumb",    { bg = c.dim2 })

-- Diff
hi("DiffAdd",       { fg = c.pink,  bg = c.bg3 })
hi("DiffChange",    { fg = c.white, bg = c.bg3 })
hi("DiffDelete",    { fg = c.pink,  bg = c.bg3 })
hi("DiffText",      { fg = c.white, bg = c.dim1 })

-- Diagnostics
hi("DiagnosticError",            { fg = c.pink })
hi("DiagnosticWarn",             { fg = c.mid })
hi("DiagnosticInfo",             { fg = c.dim4 })
hi("DiagnosticHint",             { fg = c.dim2 })
hi("DiagnosticUnderlineError",   { undercurl = true, sp = c.pink })
hi("DiagnosticUnderlineWarn",    { undercurl = true, sp = c.mid })
hi("DiagnosticUnderlineInfo",    { undercurl = true, sp = c.dim4 })
hi("DiagnosticUnderlineHint",    { undercurl = true, sp = c.dim2 })
hi("DiagnosticVirtualTextError", { fg = c.pink,  bg = c.bg2 })
hi("DiagnosticVirtualTextWarn",  { fg = c.mid,   bg = c.bg2 })
hi("DiagnosticVirtualTextInfo",  { fg = c.dim4,  bg = c.bg2 })
hi("DiagnosticVirtualTextHint",  { fg = c.dim2,  bg = c.bg2 })
hi("DiagnosticUnnecessary",      {})

-- Spell
hi("SpellBad",   { fg = c.pink,  undercurl = true, sp = c.pink })
hi("SpellCap",   { fg = c.white, undercurl = true, sp = c.white })
hi("SpellLocal", { fg = c.dim3 })
hi("SpellRare",  { fg = c.pink })

-- Treesitter
hi("@variable",              { fg = c.fg1 })
hi("@variable.builtin",      { fg = c.white })
hi("@variable.parameter",    { fg = "#e0af68" })
hi("@variable.member",       { fg = c.fg1 })
hi("@constant",              { fg = c.pink })
hi("@constant.builtin",      { fg = c.pink })
hi("@string",                { fg = c.dim3 })
hi("@string.escape",         { fg = c.pink })
hi("@character",             { fg = c.dim3 })
hi("@number",                { fg = c.pink })
hi("@boolean",               { fg = c.pink })
hi("@float",                 { fg = c.pink })
hi("@function",              { fg = c.white })
hi("@function.builtin",      { fg = c.pink })
hi("@function.method",       { fg = c.fg0 })
hi("@function.call",         { fg = c.white })
hi("@constructor",           { fg = c.fg0 })
hi("@keyword",               { fg = c.mid })
hi("@keyword.function",      { fg = c.mid })
hi("@keyword.return",        { fg = c.white })
hi("@keyword.operator",      { fg = c.fg3 })
hi("@operator",              { fg = c.fg3 })
hi("@punctuation.delimiter", { fg = c.dim2 })
hi("@punctuation.bracket",   { fg = c.dim2 })
hi("@punctuation.special",   { fg = c.pink })
hi("@type",                  { fg = c.dim4 })
hi("@type.builtin",          { fg = c.dim2 })
hi("@property",              { fg = c.fg1 })
hi("@attribute",             { fg = c.fg4 })
hi("@namespace",             { fg = c.dim2 })
hi("@include",               { fg = c.dim2 })
hi("@tag",                   { fg = c.dim2 })
hi("@tag.attribute",         { fg = c.fg4 })
hi("@tag.delimiter",         { fg = c.dim2 })
hi("@comment",               { fg = c.dim1, italic = true })

-- LSP semantic tokens
hi("@lsp.type.parameter",    { fg = "#e0af68" })
hi("@lsp.type.variable",     { fg = c.fg1 })
hi("@lsp.type.property",     { fg = c.fg1 })
hi("@lsp.type.function",     { fg = c.white })
hi("@lsp.type.method",       { fg = c.fg0 })
hi("@lsp.type.keyword",      { fg = c.mid })
hi("@lsp.type.type",         { fg = c.dim4 })
hi("@lsp.type.class",        { fg = c.fg0 })
hi("@lsp.type.interface",    { fg = c.dim4 })
hi("@lsp.type.namespace",    { fg = c.dim2 })
hi("@lsp.type.enum",         { fg = c.dim4 })
hi("@lsp.type.enumMember",   { fg = c.fg1 })
hi("@lsp.type.macro",        { fg = c.pink })
hi("@lsp.type.decorator",    { fg = c.fg4 })
hi("@lsp.typemod.variable.unused",   {})
hi("@lsp.typemod.parameter.unused",  {})

-- Git (fugitive / gitsigns)
hi("GitGutterAdd",              { fg = c.pink })
hi("GitGutterChange",           { fg = c.white })
hi("GitGutterChangeDelete",     { fg = c.white })
hi("GitGutterDelete",           { fg = c.pink })
hi("gitcommitComment",          { fg = c.dim2 })
hi("gitcommitOnBranch",         { fg = c.dim2 })
hi("gitcommitHeader",           { fg = c.fg2 })
hi("gitcommitHead",             { fg = c.dim2 })
hi("gitcommitSelectedType",     { fg = c.pink })
hi("gitcommitSelectedFile",     { fg = c.pink })
hi("gitcommitDiscardedType",    { fg = c.white })
hi("gitcommitDiscardedFile",    { fg = c.white })
hi("gitcommitUntrackedFile",    { fg = c.pink })

-- nvim-web-devicons (uniform)
hi("DevIconDefault",  { fg = c.mid })
