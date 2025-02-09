local formatting = vim.api.nvim_create_augroup("ManualFormatting", {})
local formatters = {
	["json"] = "fixjson",
	["sh"] = "shfmt",
}

for filetype, cmd in pairs(formatters) do
	vim.api.nvim_create_autocmd({ "FileType" }, {
		group = formatting,
		pattern = filetype,
		callback = function()
			vim.bo.formatprg = cmd
		end,
	})
end
