-- Auto-pairs + smart <CR> (drop a pair's closer onto its own indented line),
-- plus auto-closing of XML-like tags so <CR> can expand them too.
local keymap = vim.keymap.set

local function cursor_chars()
  local col = vim.fn.col(".")
  local line = vim.fn.getline(".")
  return line:sub(col - 1, col - 1), line:sub(col, col) -- char before / after cursor
end

local close_of = { ["("] = ")", ["["] = "]", ["{"] = "}" }
for open, close in pairs(close_of) do
  keymap("i", open, function()
    local _, after = cursor_chars()
    if after == "" or after:match("[%s%)%]},;'\"]") then return open .. close .. "<Left>" end
    return open
  end, { expr = true })
end
for close in pairs({ [")"] = true, ["]"] = true, ["}"] = true }) do
  keymap("i", close, function()
    local _, after = cursor_chars()
    return after == close and "<Right>" or close -- skip over the existing closer
  end, { expr = true })
end

for _, q in ipairs({ '"', "'", "`" }) do
  keymap("i", q, function()
    local before, after = cursor_chars()
    if after == q then return "<Right>" end -- skip over
    if before:match("[%w\\]") or after:match("[%w]") then return q end -- apostrophe / wrap
    return q .. q .. "<Left>"
  end, { expr = true })
end

keymap("i", "<BS>", function()
  local before, after = cursor_chars()
  local pair = { ["("] = ")", ["["] = "]", ["{"] = "}", ['"'] = '"', ["'"] = "'", ["`"] = "`" }
  if after ~= "" and pair[before] == after then return "<BS><Del>" end -- delete empty pair
  return "<BS>"
end, { expr = true })

-- Auto-close XML-like tags (only in tag-y filetypes)
local tag_fts = { html = true, xhtml = true, xml = true, xsd = true, svg = true, xslt = true }
local void_el = {
  area = true,
  base = true,
  br = true,
  col = true,
  embed = true,
  hr = true,
  img = true,
  input = true,
  link = true,
  meta = true,
  param = true,
  source = true,
  track = true,
  wbr = true,
}
keymap("i", ">", function()
  if not tag_fts[vim.bo.filetype] then return ">" end
  local col = vim.fn.col(".")
  local before = vim.fn.getline("."):sub(1, col - 1) .. ">"
  local tag = before:match("<([%a_][%w%-:%.]*)[^<>]*>$")
  if not tag or before:match("/>$") then return ">" end
  if (vim.bo.filetype == "html" or vim.bo.filetype == "xhtml") and void_el[tag:lower()] then
    return ">"
  end
  local closer = "</" .. tag .. ">"
  return ">" .. closer .. string.rep("<Left>", #closer)
end, { expr = true })

local cr_expand = { ["("] = ")", ["["] = "]", ["{"] = "}", [">"] = "<" }
keymap("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 and vim.fn.complete_info({ "selected" }).selected ~= -1 then
    return "<C-y>" -- confirm a selected completion item
  end
  local before, after = cursor_chars()
  if after ~= "" and cr_expand[before] == after then return "<CR><Esc>O" end
  return "<CR>"
end, { expr = true })
