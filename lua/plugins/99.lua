return {
  {
    dir = "/Users/ezzatabdelnaby/Personal/99",
    config = function()
      local _99 = require("99")
      local cwd = vim.uv.cwd()
      local basename = vim.fs.basename(cwd)

      _99.setup({
        provider = _99.Providers.ClaudeCodeProvider,
        model = "claude-sonnet-4-6",
        logger = {
          level = _99.DEBUG,
          path = "/tmp/" .. basename .. ".99.debug",
          print_on_error = true,
        },
        tmp_dir = "./tmp",
        completion = {
          source = "cmp",
          custom_rules = {
            "/Users/ezzatabdelnaby/work/skills/",
          },
        },
        md_files = {
          "AGENT.md",
        },
        code_rules = {
          "~/work/skills/code-rules.md",
        },
      })

      -- Preview quickfix entry: K opens file on left + finding on right
      -- In the finding buffer, visually select text and press <leader>9v to fix with AI
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "qf",
        callback = function(ev)
          vim.keymap.set("n", "K", function()
            local line = vim.fn.line(".")
            local qflist = vim.fn.getqflist()
            if #qflist == 0 or line > #qflist then return end

            local item = qflist[line]
            if not item or not item.text then return end

            local text = item.text
            local formatted = {}
            local filename = item.bufnr and vim.fn.bufname(item.bufnr) or ""
            local lnum = item.lnum or 0
            local short_name = filename ~= "" and vim.fn.fnamemodify(filename, ":t") or "Finding"

            -- Header
            table.insert(formatted, "# " .. short_name)
            table.insert(formatted, "**Line " .. lnum .. "**")
            table.insert(formatted, "")
            table.insert(formatted, "---")
            table.insert(formatted, "")

            -- Extract category tag
            local category, rest = text:match("^(%[%u+%])%s*(.*)")
            if category then
              table.insert(formatted, "**" .. category .. "**")
              table.insert(formatted, "")
              text = rest
            end

            -- Split on " — " for title/description separation
            local parts = vim.split(text, " — ")
            if #parts > 1 then
              table.insert(formatted, "### " .. vim.trim(parts[1]))
              table.insert(formatted, "")
              for i = 2, #parts do
                for sentence in parts[i]:gmatch("[^.]+%.?") do
                  sentence = vim.trim(sentence)
                  if sentence ~= "" then
                    table.insert(formatted, sentence .. ".")
                    table.insert(formatted, "")
                  end
                end
              end
            else
              for sentence in text:gmatch("[^.]+%.?") do
                sentence = vim.trim(sentence)
                if sentence ~= "" then
                  table.insert(formatted, sentence)
                  table.insert(formatted, "")
                end
              end
            end

            -- Add instructions at the bottom
            table.insert(formatted, "---")
            table.insert(formatted, "")
            table.insert(formatted, "> **Select text in the code (left) → `<leader>9v` to fix with AI**")
            table.insert(formatted, "> **`q` to close this view**")

            -- Close quickfix window
            vim.cmd("cclose")

            -- Open the source file on the left
            if item.bufnr and item.bufnr > 0 then
              vim.cmd("edit " .. vim.fn.fnameescape(filename))
              -- Jump to the line
              pcall(vim.api.nvim_win_set_cursor, 0, { lnum, 0 })
              vim.cmd("normal! zz")
            end

            -- Create finding buffer on the right
            local finding_buf = vim.api.nvim_create_buf(false, true)
            vim.bo[finding_buf].buftype = "nofile"
            vim.bo[finding_buf].filetype = "markdown"
            vim.bo[finding_buf].swapfile = false
            vim.api.nvim_buf_set_lines(finding_buf, 0, -1, false, formatted)
            vim.bo[finding_buf].modifiable = false

            -- Open vertical split on the right
            vim.cmd("vsplit")
            local finding_win = vim.api.nvim_get_current_win()
            vim.api.nvim_win_set_buf(finding_win, finding_buf)
            vim.wo[finding_win].wrap = true
            vim.wo[finding_win].linebreak = true
            vim.wo[finding_win].number = false
            vim.wo[finding_win].relativenumber = false
            vim.wo[finding_win].signcolumn = "no"

            -- Resize finding panel to 40% width
            local total_width = vim.o.columns
            vim.api.nvim_win_set_width(finding_win, math.floor(total_width * 0.35))

            -- q closes the finding buffer and goes back to quickfix
            vim.keymap.set("n", "q", function()
              if vim.api.nvim_win_is_valid(finding_win) then
                vim.api.nvim_win_close(finding_win, true)
              end
              pcall(vim.api.nvim_buf_delete, finding_buf, { force = true })
              vim.cmd("copen")
            end, { buffer = finding_buf, desc = "Close finding" })

            -- Store the full finding text so visual can use it
            local finding_text = table.concat(formatted, "\n")

            -- Focus back to the code file (left)
            vim.cmd("wincmd h")
            local code_buf = vim.api.nvim_get_current_buf()

            -- Override <leader>9v in the code buffer while finding is open
            -- This version includes the finding as context for the AI
            vim.keymap.set("v", "<leader>9v", function()
              _99.visual({
                additional_prompt = string.format(
                  [[
## Review Finding to Fix
The following issue was found during code review. Fix ONLY this issue in the selected code:

<Finding>
%s
</Finding>

Apply the fix precisely. Do not change anything else. Do not refactor unrelated code.
]],
                  finding_text
                ),
              })

              -- Close finding panel after submitting
              if vim.api.nvim_win_is_valid(finding_win) then
                vim.api.nvim_win_close(finding_win, true)
              end
              pcall(vim.api.nvim_buf_delete, finding_buf, { force = true })
            end, { buffer = code_buf, desc = "99: Fix this finding" })

          end, { buffer = ev.buf, desc = "99: Preview finding" })
        end,
      })

      -- AI search -> quickfix list
      vim.keymap.set("n", "<leader>9s", function()
        _99.search()
      end, { desc = "99: Search" })

      -- Replace visual selection with AI output
      vim.keymap.set("v", "<leader>9v", function()
        _99.visual()
      end, { desc = "99: Visual replace" })

      -- Cancel all in-flight requests
      vim.keymap.set("n", "<leader>9x", function()
        _99.stop_all_requests()
      end, { desc = "99: Stop requests" })

      -- Open previous results
      vim.keymap.set("n", "<leader>9o", function()
        _99.open()
      end, { desc = "99: Open results" })

      -- View logs
      vim.keymap.set("n", "<leader>9l", function()
        _99.view_logs()
      end, { desc = "99: View logs" })

      -- Chat with AI
      vim.keymap.set("n", "<leader>9c", function()
        _99.chat()
      end, { desc = "99: Chat" })

      -- Chat about visual selection
      vim.keymap.set("v", "<leader>9c", function()
        _99.visual_chat()
      end, { desc = "99: Chat about selection" })

      -- Grill the design before building (gv in the chat to implement)
      vim.keymap.set("n", "<leader>9g", function()
        _99.grill()
      end, { desc = "99: Grill design" })

      -- Grill the design about a visual selection
      vim.keymap.set("v", "<leader>9g", function()
        _99.visual_grill()
      end, { desc = "99: Grill about selection" })

      -- Explain a visual selection — mark a confusing sentence in the :Docs
      -- reader (or any code) and 99 explains it immediately, no typing needed.
      local EXPLAIN_SYSTEM = [[
You are my patient senior engineer. Explain the highlighted selection clearly and concretely so I truly understand it — what it means, why it works this way, and how the pieces connect. If it is code, walk the key lines and the data/control flow; if it is documentation or prose, translate the jargon into plain language and give a tiny concrete example. Use the surrounding project for context when useful. Build intuition, stay concise, do NOT just restate it, and do NOT change any code. End with one line on the key takeaway or a gotcha to remember.
]]
      vim.keymap.set("v", "<leader>9e", function()
        vim.api.nvim_feedkeys(
          vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
          "x",
          false
        )
        local Range = require("99.geo").Range
        local range = Range.from_visual_selection()
        _99.chat({
          code = range:to_text(),
          file = vim.api.nvim_buf_get_name(range.buffer),
          system = EXPLAIN_SYSTEM,
          title = "99 Explain",
          hint = "Explaining your selection… `i` to ask a follow-up, `q` to close.",
          initial_message = "Explain the highlighted selection above.",
        })
      end, { desc = "99: Explain selection" })

      -- Tutorial / explain code
      vim.keymap.set("n", "<leader>9t", function()
        _99.tutorial()
      end, { desc = "99: Tutorial" })

      -- Worker: set work description
      local Worker = _99.Extensions.Worker
      vim.keymap.set("n", "<leader>wd", function()
        Worker.set_work()
      end, { desc = "99: Set work description" })

      -- Worker: review changes against work description
      vim.keymap.set("n", "<leader>ww", function()
        Worker.review()
      end, { desc = "99: Review changes" })

      -- Worker: search for remaining work
      vim.keymap.set("n", "<leader>ws", function()
        Worker.search()
      end, { desc = "99: Search remaining work" })

      -- Quick bug & quality scan — no task/RFC needed, just checks the code
      -- Uses sonnet for speed
      vim.keymap.set("n", "<leader>wb", function()
        local base = "main"
        local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", "")

        local original_model = _99.get_model()
        _99.set_model("claude-sonnet-4-6")

        _99.search({
          additional_prompt = string.format(
            [[
## Quick Bug & Quality Scan: %s vs %s

Run `git diff %s...HEAD` to see all changes on this branch.

You are a senior code reviewer. Ignore the task intent — focus ONLY on the code itself.
Find every issue in the changed code:

### Bugs
- Logic errors, off-by-one, wrong conditions, null/undefined access
- Race conditions, async/await mistakes, unhandled promise rejections
- Wrong variable used, typos in property names, incorrect comparisons

### Security
- SQL/NoSQL injection, XSS, command injection
- Hardcoded secrets, exposed API keys, missing auth checks
- Unsafe user input handling, missing sanitization

### Performance
- N+1 queries, unnecessary re-renders, missing memoization
- Blocking I/O, large loops, missing pagination
- Inefficient data structures, redundant API calls

### Quality
- Unused variables/imports, dead code, console.logs left in
- Missing TypeScript types, `any` types, wrong types
- Missing error handling, empty catch blocks
- Duplicated code that should be extracted

For EACH finding, the NOTES field MUST include:
1. Category: [BUG], [SECURITY], [PERFORMANCE], or [QUALITY]
2. Clear title
3. WHY it's a problem
4. How to FIX it

Report with proper Search Format described in <Rule> and <Output>.
Only report real issues. Do not report style preferences or nitpicks.
]],
            branch, base, base
          ),
        })

        _99.set_model(original_model)
      end, { desc = "99: Quick bug & quality scan" })

      -- Full review with task + RFC context
      -- Opens a buffer to paste task + RFC, then :w to submit
      vim.keymap.set("n", "<leader>wr", function()
        local base = "main"
        local branch = vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("\n", "")

        local buf = vim.api.nvim_create_buf(false, true)
        vim.bo[buf].buftype = "acwrite"
        vim.bo[buf].filetype = "markdown"
        vim.bo[buf].swapfile = false
        vim.api.nvim_buf_set_name(buf, "99-branch-review")

        local template = {
          "# Branch Review: " .. branch .. " vs " .. base,
          "",
          "## Task Description (required)",
          "Paste your Jira task description below this line:",
          "",
          "",
          "",
          "## RFC / Design Doc (optional)",
          "Paste your RFC or design doc below this line (delete this section if none):",
          "",
          "",
          "",
          "---",
          "Save `:w` to start review, `q` to cancel",
        }

        vim.api.nvim_buf_set_lines(buf, 0, -1, false, template)
        vim.cmd("tabnew")
        local win = vim.api.nvim_get_current_win()
        vim.api.nvim_win_set_buf(win, buf)
        vim.wo[win].wrap = true
        vim.wo[win].number = true

        -- Place cursor on the empty line after "Paste your Jira task"
        vim.api.nvim_win_set_cursor(win, { 6, 0 })

        -- q to cancel
        vim.keymap.set("n", "q", function()
          vim.cmd("tabclose")
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
          vim.notify("Review cancelled", vim.log.levels.INFO)
        end, { buffer = buf })

        -- :w to submit
        vim.api.nvim_create_autocmd("BufWriteCmd", {
          buffer = buf,
          once = true,
          callback = function()
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            local content = table.concat(lines, "\n")

            -- Parse task (between "below this line:" and "## RFC")
            local task = content:match("Paste your Jira task description below this line:%s*(.-)%s*## RFC")
            task = vim.trim(task or "")

            -- Parse RFC (between "below this line (delete" and "---")
            local rfc = content:match("Paste your RFC or design doc below this line.-:%s*(.-)%s*%-%-%-")
            rfc = vim.trim(rfc or "")

            -- Close the tab
            vim.cmd("tabclose")
            pcall(vim.api.nvim_buf_delete, buf, { force = true })

            if task == "" then
              vim.notify("Review cancelled — task description is empty", vim.log.levels.WARN)
              return
            end

            local rfc_section = ""
            if rfc ~= "" then
              rfc_section = string.format(
                [[

## RFC / Design Document
<RFC>
%s
</RFC>
Use this RFC to understand the intended design, architecture decisions, and expected behavior.
Compare the implementation against what was specified in the RFC.
]],
                rfc
              )
            end

            local prompt = string.format(
              [[
## Branch Review: %s vs %s

## Task Description
<Task>
%s
</Task>
%s
## Phase 1: Understand the Code Changes
[ ] - Run `git log %s...HEAD --oneline` to see all commits and understand the story
[ ] - Run `git diff %s...HEAD` to inspect every changed file
[ ] - Build a mental model of what was actually implemented

## Phase 2: Code Quality Review
For every changed file, check:
[ ] - Bugs and logic errors (off-by-one, null checks, race conditions, wrong conditions)
[ ] - Missing edge cases (empty arrays, undefined, null, 0, negative numbers, concurrent access)
[ ] - Error handling (are errors caught? are they meaningful? do they propagate correctly?)
[ ] - Security issues (injection, auth bypass, exposed secrets, unsafe input handling)
[ ] - Performance (N+1 queries, unnecessary re-renders, blocking calls, large loops, missing indexes)
[ ] - Code quality (unclear naming, duplication, SOLID violations, dead code, magic numbers)
[ ] - Types and contracts (correct types? any `any` types? proper interfaces?)

## Phase 3: Task Completeness
[ ] - Compare the implementation against every requirement in <Task>
[ ] - Are all acceptance criteria met?
[ ] - Are there missing requirements that were not implemented?
[ ] - Are there changes outside the task scope that shouldn't be there?
[ ] - If there are tests, run the tests
[ ] - Are there missing tests for new functionality?

## Phase 4: Structural Review
[ ] - Is the code organized well? (right files, right folders, right abstraction level)
[ ] - Could the approach be simpler or more maintainable?
[ ] - Are there better patterns that should have been used?
[ ] - Will this be easy to modify or extend in the future?
%s
## Output
Report all findings with proper Search Format described in <Rule> and an example in <Output>.
For EACH finding, the NOTES field MUST include:
1. Category prefix: [BUG], [SECURITY], [PERFORMANCE], [QUALITY], [MISSING], or [SUGGESTION]
2. A clear title of the issue
3. A detailed explanation of WHY it is a problem
4. What SHOULD be done to fix it
5. Use multiple lines in the NOTES field separated by newlines, set span to cover all relevant lines

Example NOTES format:
[BUG] Missing null check on user.email — The function accesses user.email on line 42 without checking if user exists. If the API returns null for the user object, this will throw a TypeError at runtime. Fix: Add a guard clause `if (!user?.email) return` before accessing the property.
]],
              branch, base, task,
              rfc_section,
              base, base,
              rfc ~= "" and [[
## Phase 5: RFC Compliance
[ ] - Now that you have fully reviewed the code, compare it against the <RFC>
[ ] - Does the implementation follow the architecture decisions in the RFC?
[ ] - Are there deviations from the RFC? If so, are they justified?
[ ] - Does the RFC itself have gaps or issues now that you've seen the actual code?
[ ] - Suggest improvements to the RFC if the implementation revealed better approaches
]] or ""
            )
            -- Switch to sonnet for faster reviews
            local original_model = _99.get_model()
            _99.set_model("claude-sonnet-4-6")
            _99.search({ additional_prompt = prompt })
            _99.set_model(original_model)
          end,
        })
      end, { desc = "99: Review branch vs main" })

      -- Telescope model/provider pickers (if telescope is available)
      vim.keymap.set("n", "<leader>9m", function()
        require("99.extensions.telescope").select_model()
      end, { desc = "99: Select model" })

      vim.keymap.set("n", "<leader>9p", function()
        require("99.extensions.telescope").select_provider()
      end, { desc = "99: Select provider" })
    end,
  },
}
