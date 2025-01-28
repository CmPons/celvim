local M = {}

local session_cmds = vim.api.nvim_create_augroup("session_cmds", { clear = true })

M.Init = function()
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = session_cmds,
		callback = function()
			local cwd = vim.fn.getcwd()
			local filename, _ = cwd:gsub("/", "_")
			local home_path = os.getenv("HOME")
			if home_path == nil then
				return
			end

			local full_path = home_path .. "/" .. ".local/state/celvim/sessions/"
			vim.system({ "mkdir", full_path }):wait()

			vim.cmd("mksession! " .. full_path .. filename .. ".vim")
		end,
	})

	vim.api.nvim_create_user_command("LoadSession", function()
		local cwd = vim.fn.getcwd()
		local filename, _ = cwd:gsub("/", "_")

		local home_path = os.getenv("HOME")
		if home_path == nil then
			return
		end

		-- Delete all buffers first
		vim.cmd("%bd!")

		local full_path = home_path .. "/" .. ".local/state/celvim/sessions/"
		vim.cmd.source(full_path .. filename .. ".vim")
	end, {})
end

M.Cleanup = function()
	vim.api.nvim_clear_autocmds({ group = session_cmds })
end

return M
