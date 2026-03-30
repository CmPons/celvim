local M = {}

M.check = function()
	vim.health.start("Reviewer")

	if vim.fn.executable("claude") == 0 then
		vim.health.error("'claude' not found on path")
		return
	else
		vim.health.ok("'claude' found on path")
	end
end

return M
