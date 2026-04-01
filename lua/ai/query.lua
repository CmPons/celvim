--- @class ClaudeContentBlock
--- @field type "text"|"tool_use"|"tool_result"|"thinking"
--- @field text? string
--- @field id? string
--- @field name? string
--- @field input? table
--- @field thinking? string

--- @class ClaudeCacheCreation
--- @field ephemeral_5m_input_tokens integer
--- @field ephemeral_1h_input_tokens integer

--- @class ClaudeUsage
--- @field input_tokens integer
--- @field cache_creation_input_tokens integer
--- @field cache_read_input_tokens integer
--- @field cache_creation ClaudeCacheCreation
--- @field output_tokens integer
--- @field service_tier string
--- @field inference_geo string

--- @class ClaudeMessage
--- @field model string
--- @field id string
--- @field type "message"
--- @field role "assistant"
--- @field content ClaudeContentBlock[]
--- @field stop_reason? "end_turn"|"max_tokens"|"stop_sequence"|"tool_use"
--- @field stop_sequence? string
--- @field stop_details? table
--- @field usage ClaudeUsage
--- @field context_management? table

--- @class ClaudeAssistantEvent
--- @field type "assistant"
--- @field message ClaudeMessage
--- @field parent_tool_use_id? string
--- @field session_id string
--- @field uuid string

--- @class ClaudeSystemEvent
--- @field type "system"
--- @field subtype "init"|"api_retry"
--- @field session_id string
--- @field attempt? integer
--- @field max_retries? integer
--- @field retry_delay_ms? integer
--- @field error_status? integer
--- @field error? string

--- @class ClaudeResultEvent
--- @field type "result"
--- @field subtype string
--- @field session_id string
--- @field uuid string

--- @class ClaudeStreamDelta
--- @field type "text_delta"|"input_json_delta"
--- @field text? string
--- @field partial_json? string

--- @class ClaudeStreamApiEvent
--- @field type "message_start"|"content_block_start"|"content_block_delta"|"content_block_stop"|"message_delta"|"message_stop"
--- @field index? integer
--- @field delta? ClaudeStreamDelta
--- @field message? ClaudeMessage
--- @field content_block? ClaudeContentBlock

--- @class ClaudeStreamEvent
--- @field type "stream_event"
--- @field event ClaudeStreamApiEvent
--- @field session_id string
--- @field uuid string
--- @field parent_tool_use_id? string

--- @alias ClaudeEvent ClaudeAssistantEvent|ClaudeSystemEvent|ClaudeResultEvent|ClaudeStreamEvent

local M = {}

M.query_buf = nil
M.query_win = nil
M.prompt = " : "
M.bot = "󰚩 : "
M.model = "opus"
M.snippet_length = 25
M.system_prompt = [[
<SystemPrompt>
  You are a programming assistant embedded in Neovim. The user is asking a question while editing code.                                                                                                              
  Context:                                                                                                                                                                                                           
  - File: Current file the user has open      
  - Cursor: Line their cursor is at
  - Snippet: A few lines before and after the cursor pos

  Use this context as a clue to infer what the user is working on, but only reference it if relevant to their question. Be concise and direct. If the question is about code, prefer short explanations with code
  snippets. Do not repeat the question back.
  </SystemPrompt>
]]

M.on_std_out = function(_, data)
	if data == nil then
		return
	end

	-- 🤖
	info(data)

	--- @type ClaudeEvent
	local claude_code_msg = vim.json.decode(data)

	if claude_code_msg.type == "assistant" then
		for _, content in ipairs(claude_code_msg.message.content) do
			local line_data = vim.inspect(content)

			if content.type == "text" then
				line_data = content.text
			elseif content.type == "thinking" then
				line_data = " " .. content.thinking
			elseif content.type == "tool_use" then
				line_data = "󱁤 " .. content.name .. " \n" .. vim.inspect(content.input)
			end

			local lines = vim.split(line_data, "\n")
			lines[1] = M.bot .. lines[1]

			vim.api.nvim_buf_set_lines(M.query_buf, -1, -1, false, lines)
		end
	end
end

M.on_bot_done = function(_)
	vim.api.nvim_buf_set_lines(M.query_buf, -1, -1, false, { M.prompt })

	local lines = vim.api.nvim_buf_get_lines(M.query_buf, 0, -1, false)
	vim.api.nvim_win_set_cursor(M.query_win, { #lines, #M.prompt + 1 })
end

M.open_query_window = function()
	local last_buff = vim.api.nvim_buf_get_name(0)
	local last_win = vim.api.nvim_get_current_win()
	local cursor_pos = vim.api.nvim_win_get_cursor(last_win)
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local from = math.max(1, cursor_pos[1] - M.snippet_length)
	local to = math.min(#lines, cursor_pos[1] + M.snippet_length)
	local last_snippet_lines = vim.api.nvim_buf_get_lines(0, from, to, false)
	local last_snippet = table.concat(last_snippet_lines, "\n") .. "\n"

	vim.cmd("tabnew")
	M.query_buf = vim.api.nvim_get_current_buf()
	M.query_win = vim.api.nvim_get_current_win()

	vim.bo[M.query_buf].filetype = "aiquery"
	vim.bo[M.query_buf].buftype = "nofile"
	vim.api.nvim_set_option_value("number", false, { win = 0 })
	vim.api.nvim_set_option_value("relativenumber", false, { win = 0 })

	vim.api.nvim_buf_set_lines(M.query_buf, 0, 0, false, { M.prompt })
	vim.api.nvim_win_set_cursor(M.query_win, { 1, #M.prompt + 1 })
	vim.cmd("startinsert")

	local auto_mode = "--dangerously-skip-permissions"
	if vim.fn.has("win32") == 1 then
		auto_mode = "--enable-auto-mode"
	end

	vim.keymap.set("i", "<enter>", function()
		local lines = vim.api.nvim_buf_get_lines(M.query_buf, 0, -1, false)
		local prompt = table.concat(lines, "\n") .. "\n"

		prompt = string.format(
			[[
    %s
    <Context>
    File=%s
    Line=%d
    Snippet=\n%s
    </Context>

    <Conversation>
    %s
    </Conversation>
    ]],
			M.system_prompt,
			last_buff,
			cursor_pos[1],
			last_snippet,
			prompt
		)

		info("Query prompt", prompt)

		vim.system(
			{ "claude", "--model", M.model, auto_mode, "-p", prompt, "--output-format", "stream-json", "--verbose" },
			{ text = true, stdout = vim.schedule_wrap(M.on_std_out) },
			vim.schedule_wrap(M.on_bot_done)
		)
	end, { desc = "AI Query", buffer = M.query_buf })
end

M.Init = function()
	vim.keymap.set("n", "<leader>ai", function()
		M.open_query_window()
	end, { desc = "AI Reviewer" })
end

M.Shutdown = function() end

return M
