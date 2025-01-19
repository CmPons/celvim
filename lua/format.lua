local json_types = { "anim", "renderdata", "template", "map", "uiview", "config" }
for _, pat in pairs(json_types) do
	vim.api.nvim_create_autocmd("BufRead", {
		group = vim.api.nvim_create_augroup("detect_" .. pat, { clear = true }),
		desc = "Detecting " .. pat .. "file as .json",
		pattern = { "*." .. pat },
		callback = function()
			vim.cmd("set filetype=json")
		end,
	})
end

local formatters = {
	["json"] = "fixjson",
	["sh"] = "shfmt",
}

local formatting = vim.api.nvim_create_augroup("ManualFormatting", {})
for filetype, cmd in pairs(formatters) do
	vim.api.nvim_create_autocmd({ "FileType" }, {
		group = formatting,
		pattern = filetype,
		callback = function()
			vim.bo.formatprg = cmd
		end,
	})
end
