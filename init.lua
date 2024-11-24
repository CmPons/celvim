require("keymaps")
require("startup").Init()

vim.api.nvim_create_user_command("Reload", function()
	require("startup").Cleanup()

	package.loaded["startup"] = nil
	package.loaded["keymaps"] = nil

	require("keymaps")
	require("startup").Init()
end, {})
