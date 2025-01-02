local modes = {
	["n"] = { "NORMAL", "St_NormalMode" },
	["niI"] = { "NORMAL i", "St_NormalMode" },
	["niR"] = { "NORMAL r", "St_NormalMode" },
	["niV"] = { "NORMAL v", "St_NormalMode" },
	["no"] = { "N-PENDING", "St_NormalMode" },
	["i"] = { "INSERT", "St_InsertMode" },
	["ic"] = { "INSERT (completion)", "St_InsertMode" },
	["ix"] = { "INSERT completion", "St_InsertMode" },
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

local function mode()
	local m = vim.api.nvim_get_mode().mode
	local current_mode = "%#" .. modes[m][2] .. "#" .. "  " .. modes[m][1]

	return table.concat({ current_mode })
end

local function spacer()
	return table.concat({ "%#Spacer# " })
end

local function separator()
	return [[]]
end

local function file_info()
	local filename = (vim.fn.expand("%") == "" and "Empty ") or vim.fn.expand("%:t")
	local icon = ""

	if filename ~= "Empty " then
		local utils = require("utils")
		local ext = utils.get_filetype(filename)
		local icons = require("icons")
		icon = icons[ext]
		if icon == nil then
			icon = ""
		end
	end

	return table.concat({ "%#St_CurrentFile#", icon, " ", filename, " " })
end

local function get_gitstatus()
	local git_status = vim.system({ "git", "status", "-bs" }):wait()
	if git_status.code ~= 0 then
		return nil
	end

	local lines = vim.split(git_status.stdout, "\n")
	if #lines == 0 then
		return nil
	end

	local added = 0
	local changed = 0
	local removed = 0

	for _, line in ipairs(lines) do
		local start = string.sub(line, 1, 1)
		if start == "A" then
			added = added + 1
		-- Modified, renamed or copied
		elseif start == "M" or start == "R" or start == "C" then
			changed = changed + 1
		elseif start == "D" then
			removed = removed + 1
		end
	end

	local branch = vim.split(lines[1], "%.%.%.")[1]
	local branch_name = string.gsub(branch, "## ", "")

	return { head = branch_name, added = added, changed = changed, removed = removed }
end

local function git()
	local git_status = get_gitstatus()
	if git_status == nil then
		return ""
	end

	local branch_name = "%#Normal#" .. "   " .. git_status.head .. " "
	local added = (git_status.added and git_status.added ~= 0) and ("%#St_git_add#" .. "  " .. git_status.added)
		or ""
	local changed = (git_status.changed and git_status.changed ~= 0)
			and ("%#St_git_change#" .. "  " .. git_status.changed)
		or ""
	local removed = (git_status.removed and git_status.removed ~= 0)
			and ("%#St_git_delete#" .. "  " .. git_status.removed)
		or ""

	return table.concat({ branch_name, added, changed, removed })
end
local function lsp_diagnostics()
	if not rawget(vim, "lsp") then
		return ""
	end

	local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
	local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
	local hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
	local info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })

	local errors_str = (errors and errors > 0) and ("%#DiagnosticError#" .. " " .. errors .. " ") or ""
	local warnings_str = (warnings and warnings > 0) and ("%#DiagnosticWarn#" .. " " .. warnings .. " ") or ""
	local hints_str = (hints and hints > 0) and ("%#DiagnosticHint#" .. " " .. hints .. " ") or ""
	local info_str = (info and info > 0) and ("%#DiagnosticInfo#" .. " " .. info .. " ") or ""

	return errors_str .. warnings_str .. hints_str .. info_str
end

function StatusLine()
	return mode()
		.. spacer()
		.. spacer()
		.. separator()
		.. spacer()
		.. spacer()
		.. file_info()
		.. "%="
		.. lsp_diagnostics()
		.. spacer()
		.. git()
end

vim.o.statusline = "%!v:lua.StatusLine()"
