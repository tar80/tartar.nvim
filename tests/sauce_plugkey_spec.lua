local assert = require('luassert')
local plugkey = require('tartar.sauce.plugkey')

describe('sauce.plugkey', function()
  describe('non-repeatable mode', function()
    it('should register basic prefix and plug mappings', function()
      local name = 'TestSubMode'
      local prefix = 'gz'
      local register = plugkey('n', name, prefix, false)

      local maps = vim.api.nvim_get_keymap('n')
      local found_prefix = false
      for _, map in ipairs(maps) do
        if map.lhs == prefix and map.rhs == '<Plug>(' .. name .. ')' then
          found_prefix = true
        end
      end
      assert.is_true(found_prefix, 'Prefix mapping not found')

      register('j')

      local found_plug = false
      maps = vim.api.nvim_get_keymap('n')
      for _, map in ipairs(maps) do
        if map.lhs == '<Plug>(' .. name .. ')j' and map.rhs == prefix .. 'j' then
          found_plug = true
        end
      end
      assert.is_true(found_plug, 'Plug sub-key mapping not found')
    end)
  end)

  describe('repeatable mode', function()
    it('should register repeatable sequence', function()
      local name = 'RepeatMode'
      local prefix = 'r'
      local register = plugkey('n', name, prefix, true)

      register('a')

      local maps = vim.api.nvim_get_keymap('n')
      local found_init = false
      local found_repeat = false

      local plug = '<Plug>(' .. name .. ')'
      for _, map in ipairs(maps) do
        if map.lhs == prefix .. 'a' and map.rhs == prefix .. 'a' .. plug then
          found_init = true
        end
        if map.lhs == plug .. 'a' and map.rhs == prefix .. 'a' .. plug then
          found_repeat = true
        end
      end

      assert.is_true(found_init, 'Initial repeatable mapping failed')
      assert.is_true(found_repeat, 'Continuous repeatable mapping failed')
    end)

    it('should handle table input with custom replacement', function()
      local name = 'TableMode'
      local prefix = 's'
      local register = plugkey('n', name, prefix, true)

      register({ { 'x', 'y' } })

      local maps = vim.api.nvim_get_keymap('n')
      local found = false
      for _, map in ipairs(maps) do
        if map.lhs == 'sx' and map.rhs == 'y<Plug>(TableMode)' then
          found = true
        end
      end
      assert.is_true(found, 'Custom table mapping failed')
    end)
  end)
end)
