local modes = {
	["n"] = { "NORMAL", "St_NormalMode" },
	["niI"] = { "NORMAL", "St_NormalMode" },
	["niR"] = { "NORMAL", "St_NormalMode" },
	["niV"] = { "NORMAL", "St_NormalMode" },
	["no"] = { "N-PENDING", "St_NormalMode" },
	["i"] = { "INSERT", "St_InsertMode" },
	["ic"] = { "INSERT", "St_InsertMode" },
	["ix"] = { "INSERT", "St_InsertMode" },
	["t"] = { "TERMINAL", "St_TerminalMode" },
	["nt"] = { "NTERMINAL", "St_NTerminalMode" },
	["v"] = { "VISUAL", "St_VisualMode" },
	["V"] = { "V-LINE", "St_VisualMode" },
	["Vs"] = { "V-LINE (Ctrl O)", "St_VisualMode" },
	[""] = { "V-BLOCK", "St_VisualMode" },
	["R"] = { "REPLACE", "St_ReplaceMode" },
	["Rv"] = { "V-REPLACE", "St_ReplaceMode" },
	["s"] = { "SELECT", "St_SelectMode" },
	["S"] = { "S-LINE", "St_SelectMode" },
	[""] = { "S-BLOCK", "St_SelectMode" },
	["c"] = { "COMMAND", "St_CommandMode" },
	["cv"] = { "COMMAND", "St_CommandMode" },
	["ce"] = { "COMMAND", "St_CommandMode" },
	["r"] = { "PROMPT", "St_ConfirmMode" },
	["rm"] = { "MORE", "St_ConfirmMode" },
	["r?"] = { "CONFIRM", "St_ConfirmMode" },
	["!"] = { "SHELL", "St_TerminalMode" },
}

local nord_colors = require("nord.named_colors")

local mode_color = {
	["St_NormalMode"] = nord_colors.green,
	["St_InsertMode"] = nord_colors.orange,
	["St_TerminalMode"] = nord_colors.orange,
	["St_NTerminalMode"] = nord_colors.orange,
	["St_VisualMode"] = nord_colors.purple,
	["St_ReplaceMode"] = nord_colors.glacier,
	["St_SelectMode"] = nord_colors.yellow,
	["St_CommandMode"] = nord_colors.teal,
	["St_ConfirmMode"] = nord_colors.light_gray_bright,
	["St_File"] = nord_colors.blue,
	["St_Error"] = nord_colors.red,
}

local function set_colors()
	for group, color in pairs(mode_color) do
		vim.api.nvim_command("hi " .. group .. " guibg=" .. color .. " guifg=#434c5e gui=bold")
	end

	vim.api.nvim_command("hi St_CurrentFile guibg=#5e81ac")
end

local function mode()
	local m = vim.api.nvim_get_mode().mode
	local current_mode = "%#" .. modes[m][2] .. "#" .. modes[m][1] .. " "
	return table.concat({ current_mode })
end

local function spacer()
	return table.concat({ "%#Spacer# " })
end

local function file_info()
	local filename = (vim.fn.expand("%") == "" and "Empty ") or vim.fn.expand("%:t")
	local icon = ""

	local utils = require("utils")
	if string.find(filename, ".") == nil or string.find(filename, ":") then
		return table.concat({
			"%#St_File#",
			" ",
			" ",
			utils.sanitize_terminal_name(filename),
			" ",
		})
	end

	if filename ~= "Empty " then
		local ext = utils.get_filetype(filename)
		if ext ~= "" then
			local icons = require("icons")
			icon = icons[ext]
			if icon == nil then
				icon = ""
			end
			return table.concat({
				"%#St_File#",
				" ",
				icon,
				" ",
				filename,
				" ",
			})
		end
	end

	return ""
end

local git_cache = {
	status = nil,
	timer = nil,
}

-- Setup timer for git status updates
local function setup_git_timer()
	local timer = vim.loop.new_timer()
	timer:start(
		0,
		1000,
		vim.schedule_wrap(function()
			local git_status = vim.system({ "git", "status", "-bs" }):wait()
			if git_status.code == 0 then
				local lines = vim.split(git_status.stdout, "\n")
				if #lines > 0 then
					local added = 0
					local changed = 0
					local removed = 0
					local untracked = 0

					for _, line in ipairs(lines) do
						local start = string.sub(line, 2, 2)
						if start == "A" then
							added = added + 1
						elseif start == "M" or start == "R" or start == "C" then
							changed = changed + 1
						elseif start == "D" then
							removed = removed + 1
						elseif start == "?" then
							untracked = untracked + 1
						end
					end

					local branch = vim.split(lines[1], "%.%.%.")[1]
					local branch_name = string.gsub(branch, "## ", "")

					git_cache.status = {
						head = branch_name,
						added = added,
						changed = changed,
						removed = removed,
						untracked = untracked,
					}
				end
			else
				git_cache.status = nil
			end
		end)
	)
	return timer
end

-- Start the timer when Neovim starts
git_cache.timer = setup_git_timer()
local function get_gitstatus()
	local status = git_cache.status
	if status == nil then
		return
	end

	return {
		head = status.head,
		added = status.added,
		changed = status.changed,
		removed = status.removed,
		untracked = status.untracked,
	}
end

local function git()
	local git_status = get_gitstatus()
	if git_status == nil then
		return ""
	end

	local branch_name = "%#Normal#" .. "   " .. git_status.head .. " "
	-- To my confused future self: The highlight groups below are picked at random
	-- from what exists in :hi already
	local added = (git_status.added and git_status.added ~= 0) and ("%#@string#" .. "  " .. git_status.added) or ""
	local changed = (git_status.changed and git_status.changed ~= 0)
			and ("%#@string.regexp#" .. "  " .. git_status.changed)
		or ""
	local removed = (git_status.removed and git_status.removed ~= 0)
			and ("%#@comment.error#" .. "  " .. git_status.removed)
		or ""

	local untracked = (git_status.untracked and git_status.untracked ~= 0)
			and ("%#@attribute#" .. "  " .. git_status.untracked)
		or ""

	return table.concat({ branch_name, added, changed, removed, untracked, " " })
end
local function lsp_diagnostics()
	if not rawget(vim, "lsp") then
		return ""
	end

	local errors = #vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.ERROR })
	local warnings = #vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.WARN })
	local hints = #vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.HINT })
	local info = #vim.diagnostic.get(nil, { severity = vim.diagnostic.severity.INFO })

	local errors_str = (errors and errors > 0) and ("%#DiagnosticError#" .. "  " .. errors .. " ") or ""
	local warnings_str = (warnings and warnings > 0) and ("%#DiagnosticWarn#" .. "  " .. warnings .. " ") or ""
	local hints_str = (hints and hints > 0) and ("%#DiagnosticHint#" .. "  " .. hints .. " ") or ""
	local info_str = (info and info > 0) and ("%#DiagnosticInfo#" .. "  " .. info .. " ") or ""

	return errors_str .. warnings_str .. hints_str .. info_str
end

local function lsp_status()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients == 0 or not clients[1].initialized then
		return ""
	end

	return "%#St_NormalMode#" .. " 󱘖  "
end

function StatusLine()
	return mode() .. file_info() .. spacer() .. "%=" .. lsp_status() .. lsp_diagnostics() .. git()
end

set_colors()
vim.o.statusline = "%!v:lua.StatusLine()"
