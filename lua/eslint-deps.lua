-- Offer to install JS deps when eslint attaches but node_modules is missing
local eslint_prompted = {} -- per-root guard, so it doesn't nag repeatedly

local function pkg_manager(root)
  if vim.uv.fs_stat(root .. "/pnpm-lock.yaml") then return { "pnpm", "install" } end
  if vim.uv.fs_stat(root .. "/yarn.lock") then return { "yarn", "install" } end
  if vim.uv.fs_stat(root .. "/bun.lockb") or vim.uv.fs_stat(root .. "/bun.lock") then
    return { "bun", "install" }
  end
  return { "npm", "install" }
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client or client.name ~= "eslint" then return end
    local root = client.root_dir
    if not root or vim.uv.fs_stat(root .. "/node_modules") or eslint_prompted[root] then return end
    eslint_prompted[root] = true
    local cmd = pkg_manager(root)
    vim.schedule(function()
      if
        vim.fn.confirm(
          ("eslint: node_modules missing in\n%s\nRun `%s`?"):format(root, table.concat(cmd, " ")),
          "&Yes\n&No",
          2
        ) ~= 1
      then
        return
      end
      vim.notify(
        "eslint: installing deps (" .. table.concat(cmd, " ") .. ")…",
        vim.log.levels.INFO
      )
      vim.system(cmd, { cwd = root }, function(out)
        vim.schedule(function()
          if out.code == 0 then
            vim.notify("eslint: deps installed, restarting.", vim.log.levels.INFO)
            pcall(vim.cmd, "LspRestart eslint")
          else
            vim.notify("eslint: install failed\n" .. (out.stderr or ""), vim.log.levels.ERROR)
          end
        end)
      end)
    end)
  end,
})
