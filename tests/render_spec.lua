local assert = require('luassert')
local render = require('tartar.render')
local stub = require('luassert.stub')

describe('render', function()
  local ns = vim.api.nvim_create_namespace('tartar_test')

  describe('.indicator()', function()
    it('should display an indicator', function()
      local text = 'test'
      local timeout = 200
      local row = 0
      local col = 0

      local winid = render.indicator(ns, text, timeout, row, col)
      local ns_id = vim.api.nvim_get_hl_ns({ winid = winid })
      assert.is.equal(ns, ns_id)

      local bufnr = vim.api.nvim_win_get_buf(winid)
      local content = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)
      assert.equal(text, content[1])

      assert.is_true(vim.api.nvim_win_is_valid(winid))
      vim.api.nvim_win_close(winid, true)
    end)
  end)

  describe('.infotip', function()
    it('should display an infotip', function()
      local contents = { 'line1', 'line2' }
      local opts = { winblend = 50, border = { ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ' } }

      local result = render.infotip(ns, contents, opts)
      assert.is.table(result)
      ---@diagnostic disable-next-line: param-type-mismatch
      local bufnr, winid = unpack(result)

      local ns_id = vim.api.nvim_get_hl_ns({ winid = winid })
      assert.is.equal(ns, ns_id)

      local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      assert.are.same(contents, content)

      assert.is_true(vim.api.nvim_win_is_valid(winid))
      vim.api.nvim_win_close(winid, true)
    end)
  end)

  describe('.infotip_overwrite()', function()
    it('should overwrite the contents of an existing infotip', function()
      local initial_contents = { 'line1', 'line2' }
      local new_contents = { 'new_line1', 'new_line2' }

      local result = render.infotip(ns, initial_contents, {})
      assert.is.table(result)
      ---@diagnostic disable-next-line: param-type-mismatch
      local bufnr, winid = unpack(result)

      render.infotip_overwrite(bufnr, winid, new_contents)
      local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      assert.are.same(new_contents, content)

      assert.is_true(vim.api.nvim_win_is_valid(winid))
      vim.api.nvim_win_close(winid, true)
    end)
  end)
end)
