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

-- GET from the Forgejo API; tea fills in {owner}/{repo} from the repo at cwd
local function api(path, cwd, on_done)
  run({ "tea", "api", path }, cwd, function(stdout)
    on_done(vim.json.decode(stdout, { luanil = { object = true, array = true } }))
  end)
end

-- several api() calls side by side; on_done(results) once all of them answered
local function gather(paths, cwd, on_done)
  local results, left = {}, vim.tbl_count(paths)
  if left == 0 then return on_done(results) end
  for key, path in pairs(paths) do
    api(path, cwd, function(data)
      results[key], left = data, left - 1
      if left == 0 then on_done(results) end
    end)
  end
end

local function index(selected) return selected[1] and selected[1]:match("^(%d+)\t") end

local function checkout(n, cwd)
  run({ "tea", "pulls", "checkout", "--branch", n }, cwd, function()
    vim.cmd.checktime()
    vim.notify("checked out PR #" .. n, vim.log.levels.INFO, { title = "tea" })
  end)
end

-- the PR's changes since it branched from base, in diffview; no checkout needed
local function review(n, base, cwd)
  run({ "git", "fetch", "origin", "+refs/pull/" .. n .. "/head:refs/remotes/origin/pr/" .. n,
    "+refs/heads/" .. base .. ":refs/remotes/origin/" .. base }, cwd, function()
    vim.cmd(("DiffviewOpen -C%s origin/%s...origin/pr/%s"):format(vim.fn.fnameescape(cwd), base, n))
  end)
end

-- a markdown scratch window: :w hands its text to submit(text, close), :q drops it
local function compose(name, submit)
  local old = vim.fn.bufnr(name)
  if old ~= -1 then vim.api.nvim_buf_delete(old, { force = true }) end
  vim.cmd("botright 12new")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(buf, name)
  vim.bo[buf].buftype, vim.bo[buf].bufhidden, vim.bo[buf].filetype = "acwrite", "wipe", "markdown"
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      local text = vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
      submit(text, function()
        vim.bo[buf].modified = false
        vim.api.nvim_buf_delete(buf, { force = true })
      end)
    end,
  })
  vim.cmd.startinsert()
end

local ns = vim.api.nvim_create_namespace("tea")
local verdicts = {
  APPROVED = { "approved", "DiagnosticOk" },
  REQUEST_CHANGES = { "requested changes", "DiagnosticError" },
  COMMENT = { "reviewed", "DiagnosticInfo" },
  PENDING = { "started a review", "Comment" },
}
local checks = {
  success = { "✓", "DiagnosticOk" },
  failure = { "✗", "DiagnosticError" },
  error = { "✗", "DiagnosticError" },
  warning = { "!", "DiagnosticWarn" },
  pending = { "●", "DiagnosticWarn" },
}
local function date(s) return s and (s:gsub("T(%d+:%d+).*", " %1")) or "" end
local function who(u) return u and u.login or "someone" end

-- lines and highlights of the overview; each line() arg is a string or { text, hl }
local function render(r)
  local pr, lines, marks = r.pr, {}, {}
  local function line(...)
    local text = ""
    for _, seg in ipairs({ ... }) do
      local s, hl = type(seg) == "table" and seg[1] or seg, type(seg) == "table" and seg[2]
      if hl then table.insert(marks, { #lines, #text, #text + #s, hl }) end
      text = text .. s
    end
    table.insert(lines, text)
  end
  local function block(s)
    for _, l in ipairs(vim.split((s or ""):gsub("\r", ""), "\n")) do table.insert(lines, l) end
  end

  local state = pr.merged and { "merged", "DiagnosticHint" }
    or pr.state == "closed" and { "closed", "DiagnosticError" }
    or { pr.draft and "draft" or "open", "DiagnosticOk" }
  line("# " .. pr.title)
  line({ "c checkout  d diff  o browser  y url  a approve  r request changes  C comment  m merge  R reload  q close", "Comment" })
  line("")
  local wants = pr.merged and "merged" or pr.state == "closed" and "wanted to merge" or "wants to merge"
  line(("#%d · "):format(pr.number), state, (" · %s %s "):format(who(pr.user), wants),
    { pr.head.ref, "Identifier" }, " into ", { pr.base.ref, "Identifier" })
  local size = { ("+%d"):format(pr.additions or 0), "DiagnosticOk" }
  local merge = pr.state ~= "open" and "" or pr.mergeable and " · mergeable" or " · conflicts"
  line(size, { (" −%d"):format(pr.deletions or 0), "DiagnosticError" },
    (" in %d files"):format(pr.changed_files or 0), { merge, pr.mergeable and "DiagnosticOk" or "DiagnosticError" })

  local ci = { "CI       " }
  for _, s in ipairs(r.status and r.status.statuses or {}) do
    table.insert(ci, checks[s.status] or { "?", "Comment" })
    table.insert(ci, " " .. s.context .. "   ")
  end
  ci[#ci] = vim.trim(ci[#ci])
  if #ci > 1 then line(unpack(ci)) end

  -- latest verdict per reviewer, then whoever is still asked to review
  local latest, order = {}, {}
  for _, rv in ipairs(r.reviews or {}) do
    local name = who(rv.user)
    if not rv.dismissed and verdicts[rv.state] and rv.state ~= "PENDING" then
      if not latest[name] then table.insert(order, name) end
      latest[name] = rv.state
    end
  end
  local reviewers = { "Reviews  " }
  for _, name in ipairs(order) do
    local v = verdicts[latest[name]]
    table.insert(reviewers, { name .. " " .. v[1], v[2] })
    table.insert(reviewers, "   ")
  end
  for _, u in ipairs(pr.requested_reviewers or {}) do
    if not latest[who(u)] then
      table.insert(reviewers, { who(u) .. " pending", "DiagnosticWarn" })
      table.insert(reviewers, "   ")
    end
  end
  if #reviewers > 1 then
    table.remove(reviewers)
    line(unpack(reviewers))
  end
  local labels = vim.tbl_map(function(l) return l.name end, pr.labels or {})
  if #labels > 0 then line("Labels   ", { table.concat(labels, ", "), "Special" }) end

  line("")
  block(pr.body ~= "" and pr.body or "_No description._")
  line("")
  line("## Activity")

  local reviews = {}
  for _, rv in ipairs(r.reviews or {}) do reviews[rv.id] = rv end
  for _, ev in ipairs(r.timeline or {}) do
    local by, at = who(ev.user), { " · " .. date(ev.created_at), "Comment" }
    if ev.type == "comment" then
      line("")
      line("### " .. by .. " commented", at)
      block(ev.body)
    elseif ev.type == "review" and reviews[ev.review_id] then
      local rv = reviews[ev.review_id]
      local v = verdicts[rv.state] or { rv.state:lower(), "Comment" }
      line("")
      line("### " .. by .. " ", { v[1], v[2] }, rv.dismissed and { " (dismissed)", "Comment" } or "", at)
      if rv.body ~= "" then block(rv.body) end
      for _, c in ipairs(r["review" .. rv.id] or {}) do
        local pos = c.position ~= 0 and c.position or c.original_position
        line("")
        line({ ("> %s:%d"):format(c.path, pos), "Directory" }, c.resolver and { "  resolved", "Comment" } or "")
        for _, l in ipairs(vim.split(c.body:gsub("\r", ""), "\n")) do line("> " .. l) end
      end
    elseif ev.type == "pull_push" then
      local ok, push = pcall(vim.json.decode, ev.body or "")
      local count = ok and type(push) == "table" and #(push.commit_ids or {}) or 0
      local verb = ok and type(push) == "table" and push.is_force_push and "force-pushed" or "pushed"
      line("")
      line(("- %s %s %d commit%s"):format(by, verb, count, count == 1 and "" or "s"), at)
    elseif ev.type == "merge_pull" or ev.type == "close" or ev.type == "reopen" then
      local verb = ({ merge_pull = "merged", close = "closed", reopen = "reopened" })[ev.type]
      line("")
      line("- " .. by .. " ", { verb, verb == "merged" and "DiagnosticHint" or "Special" }, " this", at)
    elseif ev.type == "review_request" then
      line("")
      line(("- %s asked %s to review"):format(by, ev.assignee and who(ev.assignee) or "a team"), at)
    elseif ev.type == "change_title" then
      line("")
      line(("- %s renamed this from %q"):format(by, ev.old_title or ""), at)
    end
  end
  return lines, marks
end

-- :Pull [n]: the PR as a buffer, with the actions on its keys
local function overview(n, cwd)
  local name = ("tea://%s/pulls/%s"):format(vim.fs.basename(cwd), n)
  gather({
    pr = "/repos/{owner}/{repo}/pulls/" .. n,
    timeline = "/repos/{owner}/{repo}/issues/" .. n .. "/timeline?limit=100",
    reviews = "/repos/{owner}/{repo}/pulls/" .. n .. "/reviews?limit=100",
  }, cwd, function(r)
    local more = { status = "/repos/{owner}/{repo}/commits/" .. r.pr.head.sha .. "/status" }
    for _, rv in ipairs(r.reviews or {}) do
      if (rv.comments_count or 0) > 0 then
        more["review" .. rv.id] = ("/repos/{owner}/{repo}/pulls/%s/reviews/%d/comments"):format(n, rv.id)
      end
    end
    gather(more, cwd, function(extra)
      r = vim.tbl_extend("force", r, extra)
      local lines, marks = render(r)

      local buf = vim.fn.bufnr(name)
      if buf == -1 then
        buf = vim.api.nvim_create_buf(true, true)
        vim.api.nvim_buf_set_name(buf, name)
        vim.bo[buf].filetype = "markdown"
      end
      local win = vim.fn.bufwinid(buf)
      if win ~= -1 then
        vim.api.nvim_set_current_win(win)
      else
        vim.cmd("tab sbuffer " .. buf)
      end
      vim.wo.wrap, vim.wo.linebreak, vim.wo.conceallevel = true, true, 2
      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      vim.bo[buf].modifiable, vim.bo[buf].modified = false, false
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      for _, m in ipairs(marks) do
        vim.api.nvim_buf_set_extmark(buf, ns, m[1], m[2], { end_col = m[3], hl_group = m[4], priority = 200 })
      end

      local pr = r.pr
      local function reload() overview(n, cwd) end
      local function map(lhs, fn, desc) vim.keymap.set("n", lhs, fn, { buffer = buf, desc = "tea: " .. desc }) end
      map("q", function() vim.api.nvim_buf_delete(buf, { force = true }) end, "close")
      map("R", reload, "reload")
      map("c", function() checkout(n, cwd) end, "checkout")
      map("d", function() review(n, pr.base.ref, cwd) end, "review diff")
      map("o", function() vim.ui.open(pr.html_url) end, "open in browser")
      map("y", function()
        vim.fn.setreg("+", pr.html_url)
        vim.notify("copied " .. pr.html_url, vim.log.levels.INFO, { title = "tea" })
      end, "copy url")
      local function send(what, cmd)
        return function(text, close)
          run(cmd(text), cwd, function()
            close()
            vim.notify(what .. " #" .. n, vim.log.levels.INFO, { title = "tea" })
            reload()
          end)
        end
      end
      map("C", function()
        compose(name .. "/comment", function(text, close)
          if text == "" then return vim.notify("empty comment", vim.log.levels.WARN, { title = "tea" }) end
          send("commented on", function() return { "tea", "comment", "--", n, text } end)(text, close)
        end)
      end, "comment")
      map("a", function()
        compose(name .. "/approve", send("approved", function(text)
          return text == "" and { "tea", "pulls", "approve", n } or { "tea", "pulls", "approve", "--", n, text }
        end))
      end, "approve")
      map("r", function()
        compose(name .. "/request-changes", function(text, close)
          if text == "" then return vim.notify("say what needs to change", vim.log.levels.WARN, { title = "tea" }) end
          send("requested changes on", function() return { "tea", "pulls", "reject", "--", n, text } end)(text, close)
        end)
      end, "request changes")
      map("m", function()
        local prompt = ("Merge #%s (%s into %s) with:"):format(n, pr.head.ref, pr.base.ref)
        vim.ui.select({ "merge", "rebase", "squash", "rebase-merge" }, { prompt = prompt }, function(style)
          if not style then return end
          run({ "tea", "pulls", "merge", "--style", style, n }, cwd, function()
            vim.notify("merged #" .. n, vim.log.levels.INFO, { title = "tea" })
            reload()
          end)
        end)
      end, "merge")
    end)
  end)
end

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
          if n then overview(n, cwd) end
        end,
        ["ctrl-x"] = function(sel)
          local n = index(sel)
          if n then checkout(n, cwd) end
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
          if n then review(n, sel[1]:match("^%d+\t[^\t]*\t[^\t]*\t([^\t]*)"), cwd) end
        end,
      },
    })
  end)
end

-- :Pull with no number: the open PR of the current branch
local function pull(n)
  local cwd = root()
  if not cwd then return vim.notify("not in a git repository", vim.log.levels.WARN, { title = "tea" }) end
  if n and n ~= "" then return overview(n, cwd) end
  local head = vim.trim(vim.system({ "git", "branch", "--show-current" }, { cwd = cwd, text = true }):wait().stdout)
  run({ "tea", "pulls", "list", "--state", "open", "--limit", "100", "--output", "tsv", "--fields", "index,head" }, cwd, function(stdout)
    for _, l in ipairs(vim.split(stdout, "\n", { trimempty = true })) do
      local i, h = l:gsub('"', ""):match("^(%d+)\t(.*)$")
      if h == head then return overview(i, cwd) end
    end
    vim.notify("no open pull request for " .. (head ~= "" and head or "detached HEAD"), vim.log.levels.INFO, { title = "tea" })
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
vim.api.nvim_create_user_command("Pull", function(o) pull(o.args) end, { nargs = "?", desc = "tea: pull request overview" })
vim.api.nvim_create_user_command("PullCreate", function(o) create(o.args) end, { nargs = "?", desc = "tea: create a pull request" })

vim.keymap.set("n", "<leader>tp", function() pulls() end, { desc = "tea: Pull requests" })
vim.keymap.set("n", "<leader>to", function() pull() end, { desc = "tea: Pull request of this branch" })
vim.keymap.set("n", "<leader>tP", function() create() end, { desc = "tea: Create pull request" })
