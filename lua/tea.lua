-- Forgejo/Gitea pull requests through tea, picked with fzf-lua
local fzf = require("fzf-lua")

local function root()
  local out = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait()
  if out.code ~= 0 then return nil end
  return vim.trim(out.stdout)
end

-- run a command in the repo; on_done(stdout) only when it succeeds
local function run(cmd, cwd, on_done)
  vim.system(cmd, { cwd = cwd, text = true }, function(out)
    vim.schedule(function()
      if out.code ~= 0 then
        return vim.notify(vim.trim(out.stderr ~= "" and out.stderr or out.stdout), vim.log.levels.ERROR, { title = "tea" })
      end
      if on_done then on_done(out.stdout) end
    end)
  end)
end

local function index(selected) return selected[1] and selected[1]:match("^(%d+)\t") end

-- :Pulls [open|closed|all]
local function pulls(state)
  local cwd = root()
  if not cwd then return vim.notify("not in a git repository", vim.log.levels.WARN, { title = "tea" }) end
  state = (state and state ~= "") and state or "open"
  run({ "tea", "pulls", "list", "--state", state, "--limit", "100", "--output", "tsv",
    "--fields", "index,state,head,base,author,title,url" }, cwd, function(stdout)
    local lines = vim.split(vim.trim(stdout), "\n", { trimempty = true })
    table.remove(lines, 1) -- header
    -- tsv quotes fields that need it; drop the quotes so fzf shows plain text
    lines = vim.tbl_map(function(l) return (l:gsub('"', "")) end, lines)
    if #lines == 0 then return vim.notify("no " .. state .. " pull requests", vim.log.levels.INFO, { title = "tea" }) end
    fzf.fzf_exec(lines, {
      prompt = "PRs (" .. state .. ")> ",
      cwd = cwd,
      preview = "tea pulls {1}",
      fzf_opts = { ["--delimiter"] = "\t", ["--with-nth"] = "1..6", ["--no-multi"] = true },
      winopts = { preview = { layout = "horizontal", horizontal = "right:60%" } },
      actions = {
        ["default"] = function(sel)
          local n = index(sel)
          if n then run({ "tea", "pulls", "checkout", "--branch", n }, cwd, function()
            vim.cmd.checktime()
            vim.notify("checked out PR #" .. n, vim.log.levels.INFO, { title = "tea" })
          end) end
        end,
        ["ctrl-o"] = function(sel)
          local url = sel[1] and sel[1]:match("\t(%S+)$")
          if url then vim.ui.open(url) end
        end,
        ["ctrl-y"] = function(sel)
          local url = sel[1] and sel[1]:match("\t(%S+)$")
          if url then
            vim.fn.setreg("+", url)
            vim.notify("copied " .. url, vim.log.levels.INFO, { title = "tea" })
          end
        end,
        ["ctrl-d"] = function(sel)
          local n = index(sel)
          if not n then return end
          local base = sel[1]:match("^%d+\t[^\t]*\t[^\t]*\t([^\t]*)")
          -- diff of the PR head against where it branched from the base
          run({ "git", "fetch", "origin", "refs/pull/" .. n .. "/head" }, cwd, function()
            vim.cmd("tabnew")
            vim.cmd("Git diff --merge-base origin/" .. base .. " FETCH_HEAD")
          end)
        end,
      },
    })
  end)
end

-- :PullCreate [base]: PR from the current branch, title and body from its commits
local function create(base)
  local cwd = root()
  if not cwd then return vim.notify("not in a git repository", vim.log.levels.WARN, { title = "tea" }) end
  base = (base and base ~= "") and base or "main"
  local head = vim.trim(vim.system({ "git", "branch", "--show-current" }, { cwd = cwd, text = true }):wait().stdout)
  if head == "" or head == base then
    return vim.notify("switch to a feature branch first (on " .. (head ~= "" and head or "detached HEAD") .. ")", vim.log.levels.WARN, { title = "tea" })
  end
  local log = vim.system({ "git", "log", "--reverse", "--format=%s%n%n%b", base .. ".." .. head }, { cwd = cwd, text = true }):wait()
  local subject = vim.trim(vim.system({ "git", "log", "-1", "--format=%s", head }, { cwd = cwd, text = true }):wait().stdout)
  vim.ui.input({ prompt = ("PR %s -> %s title: "):format(head, base), default = subject }, function(title)
    if not title or title == "" then return end
    local body = vim.trim(log.stdout or "")
    -- tea creates the PR from what's on the remote, so push the branch first
    run({ "git", "push", "-u", "origin", head }, cwd, function()
      run({ "tea", "pulls", "create", "--head", head, "--base", base, "--title", title, "--description", body }, cwd, function(out)
        local url = out:match("https?://%S+/pulls/%d+")
        vim.notify("created " .. (url or "pull request"), vim.log.levels.INFO, { title = "tea" })
      end)
    end)
  end)
end

local states = { "open", "closed", "all" }
vim.api.nvim_create_user_command("Pulls", function(o) pulls(o.args) end, {
  nargs = "?",
  complete = function(lead) return vim.tbl_filter(function(s) return s:find("^" .. lead) end, states) end,
  desc = "tea: pick a pull request",
})
vim.api.nvim_create_user_command("PullCreate", function(o) create(o.args) end, { nargs = "?", desc = "tea: create a pull request" })

vim.keymap.set("n", "<leader>tp", function() pulls() end, { desc = "tea: Pull requests" })
vim.keymap.set("n", "<leader>tP", function() create() end, { desc = "tea: Create pull request" })
