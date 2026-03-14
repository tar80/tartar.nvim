---@diagnostic disable: undefined-field, param-type-mismatch
local assert = require('luassert')
local mock = require('luassert.mock')
local sauce = require('tartar.sauce')

describe('sauce', function()
  it('should strictly match the defined method list', function()
    local expected_methods = {
      'abbrev',
      'align',
      'foldtext',
      'live_replace',
      'plugkey',
      'smart_zc',
      'testmode',
    }
    table.sort(expected_methods)

    local actual_methods = {}
    for name, v in pairs(sauce) do
      if type(v) == 'function' then
        table.insert(actual_methods, name)
      end
    end
    table.sort(actual_methods)

    assert.are.same(expected_methods, actual_methods)
  end)

  it('method validity and return types', function()
    local m = mock(sauce, true)

    sauce.abbrev()
    assert.stub(sauce.abbrev).was_called(1)
    sauce.align('TestGroup')
    assert.stub(sauce.align).was_called_with('TestGroup')
    sauce.foldtext('...')
    assert.stub(sauce.foldtext).was_called_with('...')
    sauce.live_replace()
    assert.stub(sauce.live_replace).was_called(1)
    sauce.plugkey('n', 'TestKey', '<leader>t', true)
    assert.stub(sauce.plugkey).was_called_with('n', 'TestKey', '<leader>t', true)
    sauce.smart_zc('TestMod', 100)
    assert.stub(sauce.smart_zc).was_called_with('TestMod', 100)
    sauce.testmode({ option = 'value' })
    assert.stub(sauce.testmode).was_called_with({ option = 'value' })
    mock.revert(m)
  end)
end)
