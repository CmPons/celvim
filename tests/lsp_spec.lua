local spy = require("luassert.spy")
local mock = require("luassert.mock")
local stub = require("luassert.stub")
local match = require("luassert.match")

describe("LSP module", function()
	local lsp_mod = require("lsp")

	describe("initialization", function()
		local create_augroup_spy
		local create_autocmd_spy
		local clear_autocmds_spy

		before_each(function()
			create_augroup_spy = spy.on(vim.api, "nvim_create_augroup")
			create_autocmd_spy = spy.on(vim.api, "nvim_create_autocmd")
			clear_autocmds_spy = spy.on(vim.api, "nvim_clear_autocmds")
		end)

		after_each(function()
			create_augroup_spy:revert()
			create_autocmd_spy:revert()
			clear_autocmds_spy:revert()
		end)

		it("should create augroups", function()
			lsp_mod.Init()

			assert.spy(create_augroup_spy).was_called()
			assert.spy(create_augroup_spy).was_called_with("LspFormatting", {})
			assert.spy(create_augroup_spy).was_called_with("LspFuncs", {})
		end)

		it("should create LspProgress autocmd", function()
			lsp_mod.Init()

			assert.spy(create_autocmd_spy).was_called_with("LspProgress", match._)
		end)

		it("should create InsertCharPre autocmd", function()
			lsp_mod.Init()

			assert.spy(create_autocmd_spy).was_called_with("InsertCharPre", match._)
		end)
	end)

	describe("cleanup", function()
		local clear_autocmds_spy

		before_each(function()
			clear_autocmds_spy = spy.on(vim.api, "nvim_clear_autocmds")
		end)

		after_each(function()
			clear_autocmds_spy:revert()
		end)

		it("should clear both augroups", function()
			lsp_mod.Init()
			lsp_mod.Cleanup()

			assert.spy(clear_autocmds_spy).was_called_with({ group = lsp_mod.formatting })
			assert.spy(clear_autocmds_spy).was_called_with({ group = lsp_mod.lsp_funcs })
		end)
	end)

	describe("InsertCharPre autocmd", function()
		local omnifunc_spy
		local schedule_stub

		before_each(function()
			lsp_mod.Init()
			omnifunc_spy = spy.on(vim.lsp, "omnifunc")
			schedule_stub = stub(vim, "schedule", function(func)
				func()
			end)
		end)

		after_each(function()
			schedule_stub:revert()
			omnifunc_spy:revert()
			lsp_mod.Cleanup()
		end)

		it("should call omnifunc when char alphanumeric", function()
			vim.v.char = "a"
			vim.api.nvim_exec_autocmds("InsertCharPre", {})
			assert.spy(omnifunc_spy).was_called()
			omnifunc_spy:clear()
		end)
	end)
end)
