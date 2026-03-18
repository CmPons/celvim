--- @param file_to_edit string
function EditFile(file_to_edit)
  local exists = vim.fn.filereadable(file_to_edit)
  if not exists then
    error("Failed to open file for edit in P4! File " .. file_to_edit .. " does not exist!")
    return
  end

  local cmd = { "p4", "edit", file_to_edit }

  local system_obj = vim.system(cmd, { text = true, cwd = vim.fn.getcwd() })
  local one_second = 1000
  local sys_completed = system_obj:wait(one_second)

  if sys_completed.code ~= 0 then
    error(
      "Failed to open file " .. file_to_edit .. " for edit:\n" .. sys_completed.stdout .. "\n" .. sys_completed.stderr
    )
  else
    vim.notify("Opened " .. vim.fn.fnamemodify(file_to_edit, ":t") .. " for edit in p4!")
  end
end

--- @param file_to_add string
local function AddFile(file_to_add)
  local exists = vim.fn.filereadable(file_to_add)
  if not exists then
    error("Failed to open file for add in P4! File " .. file_to_add .. " does not exist!")
    return
  end

  local cmd = { "p4", "add", file_to_add }

  local system_obj = vim.system(cmd, { text = true, cwd = vim.fn.getcwd() })
  local one_second = 1000
  local sys_completed = system_obj:wait(one_second)

  if sys_completed.code ~= 0 then
    error(
      "Failed to add file " .. file_to_add .. " for edit:\n" .. sys_completed.stdout .. "\n" .. sys_completed.stderr
    )
  else
    vim.notify("Added " .. vim.fn.fnamemodify(file_to_add, ":t") .. " to p4!")
  end
end

local M = {}

M.Init = function()
  vim.keymap.set("n", "<leader>pe", function()
    local curr_buff = vim.api.nvim_buf_get_name(0)
    EditFile(curr_buff)
  end)

  vim.keymap.set("n", "<leader>pa", function()
    local curr_buff = vim.api.nvim_buf_get_name(0)
    AddFile(curr_buff)
  end)
end

M.Cleanup = function()
end

return M
