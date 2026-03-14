---@diagnostic disable: missing-parameter, param-type-mismatch
local assert = require('luassert')
local stub = require('luassert.stub')
local beacon = require('tartar.beacon')

describe('beacon', function()
  describe('.new()', function()
    it('should validate input parameters', function()
      assert.has_error(function()
        beacon.new(123)
      end, 'hlgroup: expected string, got number')
      assert.has_error(function()
        beacon.new('Highlight', 'not a number')
      end, 'interval: expected number, got string')
      assert.has_error(function()
        beacon.new('Highlight', 100, 'not a number')
      end, 'blend: expected number, got string')
      assert.has_error(function()
        beacon.new('Highlight', 100, 0, 'not a number')
      end, 'decay: expected number, got string')
    end)

    it('should create a new beacon instance with default values', function()
      local b = beacon.new()
      assert.is_not_nil(b)
      assert.are.equal('IncSearch', b.hlgroup)
      assert.are.equal(100, b.interval)
      assert.are.equal(0, b.blend)
      assert.are.equal(15, b.decay)
    end)

    it('should create a new beacon instance with custom values', function()
      local b = beacon.new('MyHighlight', 200, 50, 10)
      assert.is_not_nil(b)
      assert.are.equal('MyHighlight', b.hlgroup)
      assert.are.equal(200, b.interval)
      assert.are.equal(50, b.blend)
      assert.are.equal(10, b.decay)
    end)
  end)

  describe(':flash()', function()
    local b
    local snapshot

    before_each(function()
      b = beacon.new('IncSearch', 100, 0, 15)
      snapshot = assert.snapshot()
    end)

    after_each(function()
      if snapshot then
        snapshot:revert()
      end
    end)

    it('when called while running: Updates the settings of existing windows and resets winblend', function()
      b.is_running = true
      b.winid = 88

      local set_config_stub = stub(vim.api, 'nvim_win_set_config')
      local set_opt_stub = stub(vim.api, 'nvim_set_option_value')

      local move_region = {
        height = 1,
        width = 15,
        row = 10,
        col = 20,
        relative = 'cursor',
      }

      b:flash(move_region)
      assert.stub(set_config_stub).was_called_with(b.winid, move_region)
      assert.stub(set_opt_stub).was_called_with('winblend', b.blend, { win = b.winid })
      set_config_stub:revert()
      set_opt_stub:revert()
    end)
  end)

  describe(':around_cursor()', function()
    it('should flash around the cursor', function()
      local b = beacon.new()
      assert.has_no_error(function()
        b:around_cursor(vim.api.nvim_get_current_win())
      end)
    end)
  end)

  describe(':replaced_region()', function()
    it('should flash the replaced region', function()
      local b = beacon.new()
      assert.has_no_error(function()
        b:replaced_region('test', 1, true)
      end)
    end)
  end)
end)
