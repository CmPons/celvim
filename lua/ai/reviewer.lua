local M = {}
local review_namespace = vim.api.nvim_create_namespace("ai_reviewer")
local review_in_progress_timer = vim.loop.new_timer()

--- @class ReviewItem
--- @field line_num integer
--- @field col integer
--- @field severity "ERROR" | "WARN" | "INFO" | "HINT"
--- @field message string
--- @field file string

--- @class ReviewResult
--- @field reviews ReviewItem[]

--- @type fun(out: vim.SystemCompleted)
local reviewer_exit = function(out)
	review_in_progress_timer:stop()

	if out == nil then
		return
	end

	vim.notify("Reviewer done!")
	info("Reviewer feedback: ", out.stdout)

	local start = out.stdout:find("{")
	local last = out.stdout:match(".*()}")

	if start ~= nil and last ~= nil then
		local json = out.stdout:sub(start, last)

		--- @type ReviewResult
		local review_results = vim.json.decode(json)
		if review_results == nil then
			error("Review failed!")
			return
		end

		local diagnostics = {}
		for _, review in ipairs(review_results.reviews) do
			local bufnr = vim.fn.bufadd(review.file)
			if bufnr == 0 then
				error("AI Reviewer: Failed to add buf: " .. review.file)
			else
				vim.fn.bufload(bufnr)

				if not diagnostics[bufnr] then
					diagnostics[bufnr] = {}
				end

				--- @type vim.Diagnostic
				local diagnostic =
					{ lnum = review.line_num, col = review.col, message = review.message, severity = review.severity }

				table.insert(diagnostics[bufnr], diagnostic)
			end
		end

		for bufnr, diagnostics_list in pairs(diagnostics) do
			vim.diagnostic.set(review_namespace, bufnr, diagnostics_list)
		end
	end
end

local prompt = [[Launch a sub-agent to run the /review skill on the changed files in git.

  Once the sub-agent completes, synthesize ALL of its findings into a single JSON object.

  Your ENTIRE response must be ONLY this JSON object. No markdown fences, no preamble, no explanation, no commentary before or after.

  Schema:
  {
    "reviews": [
      {
        "line_num": <int>,
        "col": <int>,
        "severity": "ERROR" | "WARN" | "INFO" | "HINT",
        "message": "<string>",
        "file": "<relative file path>"
      }
    ]
  }

  severity meanings:
  - ERROR: bugs, dead code, security issues
  - WARN: potential problems, silent failures, edge cases
  - INFO: positive observations, good patterns worth noting
  - HINT: minor suggestions, style, API ergonomics

  Output ONLY valid JSON.]]

local review_code = function()
	vim.diagnostic.reset(review_namespace)

	review_in_progress_timer:start(
		500,
		500,
		vim.schedule_wrap(function()
			vim.notify("Review in progress...")
		end)
	)

	vim.notify("Review started!")
	vim.system({ "claude", "-p", prompt }, vim.schedule_wrap(reviewer_exit))
end

M.Init = function()
	vim.keymap.set("n", "<leader>ar", function()
		review_code()
	end, { desc = "AI Reviewer" })
end

M.Shutdown = function() end

return M
