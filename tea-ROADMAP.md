# tea PR review: roadmap

Forgejo pull requests inside Neovim, built on `tea` (≥ 0.16), fzf-lua and
diffview. The code is `lua/tea.lua`. It may move to its own repo; see
[Moving it out](#moving-it-out).

## Level 1: done (d6539de)

- `:Pulls [open|closed|all]` picker (`<leader>tp`): Enter overview, `ctrl-x`
  checkout, `ctrl-d` diffview, `ctrl-o` browser, `ctrl-y` copy URL.
- `:Pull [n]` overview buffer (`<leader>to` = PR of the current branch): state,
  head → base, size, mergeable, CI, reviewer verdicts, description, activity
  timeline with inline review comments.
- Keys: `d` diff, `c` checkout, `C` comment, `a` approve, `r` request changes,
  `m` merge, `o`/`y` browser/URL, `R` reload, `q` close.
- `:PullCreate [base]`.

Limits: the timeline shows only the first 100 entries. Comment, approve,
request changes and merge haven't been run against a real PR yet.

## Level 2: inline review in Neovim (~1–2 weeks, ~1500–2500 lines)

Goal: read and write line comments in the diff itself, the way octo.nvim does
for GitHub.

1. **Own diff view.** Diffview has no API for annotating its buffers. Build two
   windows in `diffthis` mode on `git show <merge-base>:<path>` and
   `git show origin/pr/<n>:<path>`, plus a file panel (the list from
   `/pulls/{n}/files`). Name the buffers `tea://…` so they're read-only and
   reloadable.
2. **Show existing comments.** Put them under their lines as `virt_lines`
   extmarks, folded to one line and expanded on `<CR>`. Add `]t`/`[t` to jump
   between threads and a quickfix list of all threads.
3. **Write comments.** Comment on a line or visual range with the `compose()`
   window. Keep comments in a local pending review. Submit them all at once as
   COMMENT, APPROVE or REQUEST_CHANGES.
4. **Threads.** Reply, resolve and unresolve. tea already has `tea pulls reply`,
   `resolve`, `unresolve` and `review-comments`; read their source or `--debug`
   output for the endpoints before calling the API directly.
5. **Outdated comments.** After a force push a comment's `commit_id` is no
   longer in the PR. Show it in its own "outdated" section with its
   `diff_hunk` instead of placing it on a line.

**Hard part: line mapping.** Mapping a buffer line on the old or new side to
the position the API expects is where most of the debugging time will go.
Probe it first (in `aitools/scratch/nvim/`): post a review comment on each side
of a test PR and compare what you sent with what you read back.

### API facts (checked 2026-10-22 against forgejo.xcerion.com)

- `tea api <path>` makes authenticated requests and fills in `{owner}/{repo}`
  from the repo at cwd. `-X`, `-f/-F` and `-d @-` cover writes.
- `GET /repos/{o}/{r}/pulls/{n}` has `head.sha`, `head.ref`, `base.ref`,
  `merge_base`, `mergeable`, `additions`, `deletions`, `changed_files`,
  `requested_reviewers`, `review_comments`, `draft`.
- `GET /pulls/{n}/reviews` returns `id`, `state` (APPROVED, REQUEST_CHANGES,
  COMMENT, PENDING), `body`, `comments_count`, `stale`, `official`,
  `dismissed`.
- `GET /pulls/{n}/reviews/{id}/comments` returns `path`, `position` (the line
  in the new file; 126 matched what tea calls `line`), `original_position`,
  `commit_id`, `original_commit_id`, `diff_hunk`, `resolver`, `html_url`.
- `GET /issues/{n}/timeline` has the types `comment`, `review` (only
  `review_id`, so join it with `/reviews`), `pull_push` (`body` is JSON:
  `is_force_push`, `commit_ids`), `merge_pull`, `close`, `reopen`,
  `assignees`, `commit_ref`, `review_request`, `change_title`.
- `GET /commits/{sha}/status` returns `statuses[]` with `status`, `context`,
  `description` and a relative `target_url`.

### Not yet checked

- The body for `POST /pulls/{n}/reviews`: the field names of the comments
  (`new_position`/`old_position`?) and how a multi-line range is expressed.
- Whether a reply has to be a new review or has its own endpoint.
- Whether `/pulls/{n}/files` gives patch text or only names and stats.
- The server's maximum page size (50 or 100) for the timeline and reviews.

## Level 3: octo-level polish (months; pick à la carte)

- Suggestion blocks (```` ```suggestion ````), with "apply suggestion" writing
  the change into the checked-out branch.
- Edit and delete your own comments (`tea comments edit|delete`, plus review
  comments through the API).
- Live refresh: poll `updated_at` while the overview is open and mark what's
  new since you last looked.
- Edit labels, assignees, reviewers, milestone and title from the overview.
- A CI panel: jobs and logs from Forgejo Actions, and re-running a failed job.
- Notifications and a PR inbox across repos (`tea notifications`, the
  review-requested filter).
- Issues in the same UI (`tea issues`), with linked issues in the overview.
- Draft handling: mark ready, convert to draft.
- Merge options: delete the branch after merge, merge when checks pass.

## Moving it out

- Shape it as a plugin: `lua/<name>/init.lua` with `setup(opts)`, then split
  out `api.lua` (`run`, `api`, `gather`), `overview.lua`, `picker.lua`,
  `compose.lua` and later `review/`. Commands and keymaps get created in
  `setup()`, with keymaps optional.
- Options: remote name (now hardcoded to `origin`), default base for
  `:PullCreate` (now `main`), tab vs. split, highlight groups, picker key
  bindings.
- Dependencies: `tea` ≥ 0.16 (for `tea api`), fzf-lua (could become optional,
  falling back to `vim.ui.select`) and diffview (only for level 1's `d`; level
  2 brings its own view).
- Add `:checkhealth`: tea on PATH and its version, a tea login for the remote,
  fzf-lua and diffview present.
- A test setup: run the headless dump scripts against a test repo on Forgejo,
  as in the level 1 checks.
- Install from Forgejo with `vim.pack`, the way `cloudbackend.nvim` is.
