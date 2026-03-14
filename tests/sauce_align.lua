local assert = require('luassert')
local spy = require('luassert.spy')
local _align = require('tartar.sauce.align')._align

describe('sause.align', function()
  local ns = vim.api.nvim_create_namespace('test_align')
  local bufnr
  local instance

  before_each(function()
    bufnr = vim.api.nvim_create_buf(false, true)
    local base_lines = { 'x=1', 'long_var=2' }
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, base_lines)

    instance = setmetatable({
      ns = ns,
      bufnr = bufnr,
      hlgroup = 'IncSearch',
      lines = { base = base_lines, expand = base_lines },
      startline = 0,
      endline = 2,
      ctx = { '', '' },
    }, { __index = _align })

    vim.api.nvim_set_current_buf(bufnr)
  end)

  describe('.input()', function()
    it('should update ctx and return the combined string', function()
      assert.are.equal('a', instance:input('a', false))
      assert.are.equal('ab', instance:input('b', false))
    end)

    it('should handle <BS> (backspace) to delete character', function()
      instance.ctx = { 'abc', '' }
      instance:input('\b', false)
      assert.are.equal('ab', instance.ctx[1])
    end)

    it('should return true on <CR> to signal completion', function()
      assert.is_true(instance:input('\r', false))
    end)
  end)

  describe('.align()', function()
    it('should calculate correct padding for matches', function()
      instance.set_extmark = spy.on(instance, 'set_extmark')

      local result = instance:align('=', false)

      assert.are.equal('x       =1', result[1])
      assert.are.equal('long_var=2', result[2])
      assert.spy(instance.set_extmark).was_called_with(instance, 0, 1, '       ')
    end)
  end)
end)
