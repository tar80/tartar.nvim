---@diagnostic disable: param-type-mismatch, undefined-field
local assert = require('luassert')
local bench = require('tartar.sauce.bench')

describe('sauce.bench', function()
  local bufnr

  before_each(function()
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(0, bufnr)
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { 'line 1', 'line 2', 'line 3' })
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
  end)

  describe('.insert_template()', function()
    it('should combine insert and delete into one undo block', function()
      vim.api.nvim_buf_set_lines(bufnr, 0, 1, false, { 'trigger undo' })
      bench.insert_template(false, 's', 'e')
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      assert.truthy(#lines > 5, 'Template should be inserted')

      vim.cmd('undo')
      local undone_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      assert.is_nil(undone_lines[10], 'Undo should remove the entire template at once')
    end)

    it('insert_template(true) should replace print with notify', function()
      bench.insert_template(true, 's', 'e')

      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local found_notify = false
      for _, line in ipairs(lines) do
        if line:find('bench.notify') then
          found_notify = true
        end
        assert.is_nil(line:match('bench%.print'), 'bench.print should be replaced by notify')
      end
      assert.is_true(found_notify, 'bench.notify was not found in template')
    end)
  end)

  describe('.clear()', function()
    it('should delete lines between marks', function()
      pcall(bench.insert_template, false, 's', 'e')
      bench.clear()
      assert.is_nil(vim.b.tartar_benchmark_mark)
    end)

    it('should not error if no marks are set', function()
      vim.b.tartar_benchmark_mark = nil
      assert.has_no.errors(function()
        bench.clear()
      end)
    end)
  end)

  describe('.run()', function()
    it('captures return values and time strings', function()
      local res = bench.run(1, function()
        return 'ok'
      end)
      assert.are.equal('ok', res[1].ret)
      assert.is_string(res[1].time)
    end)

    it('run() should handle 0 loop count gracefully', function()
      local results = bench.run(0, function()
        return 'nop'
      end)
      assert.is_table(results[1])
    end)

    it('run() should skip non-function arguments', function()
      local results = bench.run(1, function()
        return 'ok'
      end, 'dummy string')
      assert.are.equal(1, #results)
    end)
  end)
end)
