-- Drop noisy diagnostics: unused (tag 1) and TS "cannot find name" (2304/2552)
local function drop_noisy_diags(diags, client_id)
  local name = (vim.lsp.get_client_by_id(client_id) or {}).name
  local is_ts = name == "tsgo" or name == "ts_ls"
  return vim.tbl_filter(function(d)
    if d.tags and vim.tbl_contains(d.tags, 1) then return false end
    if is_ts and (d.code == 2304 or d.code == 2552) then return false end
    return true
  end, diags)
end

local orig_publish = vim.lsp.handlers["textDocument/publishDiagnostics"]
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
  if result and result.diagnostics then
    result.diagnostics = drop_noisy_diags(result.diagnostics, ctx.client_id)
  end
  orig_publish(err, result, ctx, config)
end

-- tsgo delivers diagnostics via pull (textDocument/diagnostic), not publish
local orig_pull = vim.lsp.handlers["textDocument/diagnostic"]
---@diagnostic disable-next-line: duplicate-set-field
vim.lsp.handlers["textDocument/diagnostic"] = function(err, result, ctx, config)
  if result and result.items then result.items = drop_noisy_diags(result.items, ctx.client_id) end
  return orig_pull(err, result, ctx, config)
end
