local assert = require('luassert')
local stub = require('luassert.stub')
local abbrev = require('tartar.sauce.abbrev')

describe('sauce.abbrev', function()
  local keymap_stub

  before_each(function()
    keymap_stub = stub(vim.keymap, 'set')
  end)

  after_each(function()
    if keymap_stub then
      keymap_stub:revert()
    end
  end)

  describe('.ia table', function()
    it('should set multiple abbreviations for a single word', function()
      local word = 'git'
      local replaces = { 'g', 'gi' }

      abbrev.ia(word, replaces)

      assert.stub(keymap_stub).was_called(2)
      assert.stub(keymap_stub).was_called_with('ia', 'g', 'git')
      assert.stub(keymap_stub).was_called_with('ia', 'gi', 'git')
    end)
  end)

  describe('.ca table', function()
    it('should set simple ca with expression', function()
      local word = 'G'
      local replace = { { 'git' }, false }

      abbrev.ca(word, replace)

      local expected_exp = 'getcmdtype()..getcmdline() ==# ":G" ? "git" : "G"'
      assert.stub(keymap_stub).was_called_with('ca', 'G', expected_exp, { expr = true })
    end)

    it('should set complex ca with range support and getchar', function()
      local word = 's'
      local replace = { { 'substitute', 'SUB' }, true }

      abbrev.ca(word, replace)

      local getchar = '[getchar(), ""][1].'
      local expected_exp = ('getcmdtype()..getcmdline() ==# ":s" ? %s"substitute" : getcmdtype()..getcmdline() ==# ":\'<,\'>s" ? %s"SUB" : "s"'):format(
        getchar,
        getchar
      )

      assert.stub(keymap_stub).was_called_with('ca', 's', expected_exp, { expr = true })
    end)

    it('should fail if replace[1] is not a table (validation)', function()
      assert.has_error(function()
        abbrev.ca('test', { 'not_a_table', false })
      end)
    end)
  end)

  describe('.set()', function()
    it('should iterate over the table and call the mode function with a single table argument', function()
      local test_data = { 'W', { 'w', 'ww' } }
      abbrev.tbl = { ia = { test_data } }
      local ia_stub = stub(abbrev, 'ia')
      abbrev:set('ia')
      assert.stub(ia_stub).was_called_with(test_data)
      ia_stub:revert()
    end)
  end)
end)
