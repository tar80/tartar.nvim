local assert = require('luassert')
local stub = require('luassert.stub')
local helper = require('tartar.helper')

describe('tartar.helper', function()
  describe('.echo()', function()
    local s
    before_each(function()
      s = stub(vim.api, 'nvim_echo')
    end)

    local name = 'Name'
    local subject = 'subject'
    it('returns echo. "msg" can be a string', function()
      local msg = 'string messages'
      local expects = { { '[Name] subject: ' }, { msg } }
      helper.echo(name, subject, msg)
      assert.stub(s).was.called_with(expects, false, {})
    end)

    it('returns echo. "msg" can be a table of string array', function()
      local msg = { { 'table' }, { 'of', 'Error' }, { 'messages', 'Warn' } }
      local expects = { { '[Name] subject: ' }, unpack(msg) }
      helper.echo(name, subject, msg)
      assert.stub(s).was.called_with(expects, false, {})
    end)
  end)

  describe('.utf_encoding()', function()
    it('returns encoding. should return "utf-8"', function()
      assert.equal(helper.utf_encoding('utf-8'), 'utf-8')
      assert.equal(helper.utf_encoding('UTF-8'), 'utf-8')
    end)
    it('returns encoding. should return "utf-16"', function()
      assert.equal(helper.utf_encoding('utf-16'), 'utf-16')
      assert.equal(helper.utf_encoding('UTF-16'), 'utf-16')
    end)
    it('returns encoding. should return "utf-32"', function()
      assert.equal(helper.utf_encoding('utf-0'), 'utf-32')
      assert.equal(helper.utf_encoding('UTF-32'), 'utf-32')
      assert.equal(helper.utf_encoding(''), 'utf-32')
      assert.equal(helper.utf_encoding(nil), 'utf-32')
    end)
  end)

  describe('.split_option_value()', function()
    it('returns option values as a table', function()
      local original_value = vim.o.whichwrap
      vim.o.whichwrap = '<,>'
      assert.are.same(helper.split_option_value('whichwrap'), { '<', '>' })
      vim.o.whichwrap = original_value
    end)
  end)

  describe('.get_wrap_marker_flags()', function()
    it('returns wrap marker flags as integers', function()
      local original_listchars = vim.o.listchars
      vim.o.listchars = 'extends:>,precedes:<'
      local extends, precedes = helper.get_wrap_marker_flags()
      assert.are.equal(1, extends)
      assert.are.equal(1, precedes)

      vim.o.listchars = 'extends:>'
      extends, precedes = helper.get_wrap_marker_flags()
      assert.are.equal(1, extends)
      assert.are.equal(0, precedes)

      vim.o.listchars = 'precedes:<'
      extends, precedes = helper.get_wrap_marker_flags()
      assert.are.equal(0, extends)
      assert.are.equal(1, precedes)

      vim.o.listchars = ''
      extends, precedes = helper.get_wrap_marker_flags()
      assert.are.equal(0, extends)
      assert.are.equal(0, precedes)

      vim.o.listchars = original_listchars
    end)
  end)

  describe('.get_selected_range()', function()
    it('returns visual selected range as zero-based index', function()
      vim.cmd('normal! ggVG')
      local start_pos, end_pos, is_reverse = helper.get_selected_range(0, 0, false)
      assert.are.same({ 0, 0 }, start_pos)
      local last_line = vim.api.nvim_buf_line_count(0) - 1
      local last_col = #vim.api.nvim_buf_get_lines(0, last_line, last_line + 1, false)[1]
      assert.are.same({ last_line, last_col }, end_pos)
      assert.is_false(is_reverse)
    end)
  end)

  describe('.charwidth()', function()
    local s = '0あ😀'

    it('charcter width on screen. half width character must return "1"', function()
      assert.is.equal(1, helper.charwidth(s, 0))
    end)
    it('charcter width on screen. full width character must return "2"', function()
      assert.is.equal(2, helper.charwidth(s, 1))
    end)
    it('charcter width on screen. emoji must return "2"', function()
      assert.is.equal(2, helper.charwidth(s, 2))
    end)
  end)

  describe('replace_lt', function()
    it('replaces "<" with "<lt>"', function()
      local input = '<t> && c < d>'
      local expected = '<lt>t> && c < d>'
      assert.are.equal(expected, helper.replace_lt(input))
    end)
  end)

  describe('.is_enable_user_vars()', function()
    it('returns boolean. should return true', function()
      vim.b.TEMP_TEST_VALUE = 1
      vim.g.TEMP_TEST_VALUE = 1
      assert.is_true(helper.is_enable_user_vars('TEMP_TEST_VALUE'))
      vim.b.TEMP_TEST_VALUE = 1
      vim.g.TEMP_TEST_VALUE = 0
      assert.is_true(helper.is_enable_user_vars('TEMP_TEST_VALUE'))
      vim.b.TEMP_TEST_VALUE = nil
      vim.g.TEMP_TEST_VALUE = true
      assert.is_true(helper.is_enable_user_vars('TEMP_TEST_VALUE'))
    end)
    it('returns boolean. should return false', function()
      vim.b.TEMP_TEST_VALUE = nil
      vim.g.TEMP_TEST_VALUE = false
      assert.is_false(helper.is_enable_user_vars('TEMP_TEST_VALUE'))
      vim.b.TEMP_TEST_VALUE = false
      vim.g.TEMP_TEST_VALUE = nil
      assert.is_false(helper.is_enable_user_vars('TEMP_TEST_VALUE'))
      vim.b.TEMP_TEST_VALUE = nil
      vim.g.TEMP_TEST_VALUE = 0
      assert.is_false(helper.is_enable_user_vars('TEMP_TEST_VALUE'))
      vim.b.TEMP_TEST_VALUE = false
      vim.g.TEMP_TEST_VALUE = false
      assert.is_false(helper.is_enable_user_vars('TEMP_TEST_VALUE'))
      vim.b.TEMP_TEST_VALUE = 0
      vim.g.TEMP_TEST_VALUE = 0
      assert.is_false(helper.is_enable_user_vars('TEMP_TEST_VALUE'))
    end)
    it('returns boolean. should return nil', function()
      vim.b.TEMP_TEST_VALUE = nil
      vim.g.TEMP_TEST_VALUE = nil
      assert.is_nil(helper.is_enable_user_vars('TEMP_TEST_VALUE'))
    end)
  end)

  describe('is_floating_win', function()
    it('returns boolean. should return true for floating window', function()
      local buf = vim.api.nvim_create_buf(false, true)
      local win = vim.api.nvim_open_win(buf, false, {
        relative = 'editor',
        width = 10,
        height = 5,
        row = 10,
        col = 10,
      })
      assert.is_true(helper.is_floating_win(win))
      vim.api.nvim_win_close(win, true)
      vim.api.nvim_buf_delete(buf, { force = true })
    end)
    it('returns boolean. should return false for normal window', function()
      local current_win = vim.api.nvim_get_current_win()
      assert.is_false(helper.is_floating_win(current_win))
    end)
  end)

  describe('parse_path', function()
    it('returns parent directory and file name for file URI', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      local test_path = vim.fn.tempname()
      vim.api.nvim_buf_set_name(bufnr, test_path)
      local wd, name = helper.parse_path(bufnr)
      assert.are.equal(vim.fs.dirname(test_path), wd)
      assert.are.equal(test_path, name)
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
    it('returns empty parent directory and file name for non-file URI', function()
      local bufnr = vim.api.nvim_create_buf(false, true)
      local test_uri = 'git://repository/path/to/file.txt'
      local expected_name = 'git:file.txt'
      vim.api.nvim_buf_set_name(bufnr, test_uri)
      local wd, name = helper.parse_path(bufnr)
      assert.are.equal('', wd)
      assert.are.equal(expected_name, name)
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end)
    it('returns nil for invalid buffer', function()
      local wd, name = helper.parse_path(-1)
      assert.is_nil(wd)
      assert.is_nil(name)
    end)
  end)

  describe('set_hl()', function()
    it('sets highlight group', function()
      local group = 'TartarTestHighlight'
      helper.set_hl({ [group] = { fg = '#FF0000', bg = '#00FF00', bold = true } })
      local hl = vim.api.nvim_get_hl(0, { name = group, create = false })
      assert.are.equal(16711680, hl.fg)
      assert.are.equal(65280, hl.bg)
      assert.is_true(hl.bold)
    end)
  end)

  describe('.autocmd()', function()
    it('"safestate" is specifeid. SafeState event must be executed once by the callback', function()
      local name = 'User'
      local safestate = true
      local group = 'tartar_test'
      local callback = function()
        vim.print('test')
      end
      local opts = { desc = 'decription', pattern = '*', group = group, callback = callback }
      local expects = vim.tbl_deep_extend('force', opts, { once = true, callback = callback })
      local id = vim.api.nvim_create_augroup(group, {})
      helper.autocmd(name, opts, safestate)
      local s = stub(vim.api, 'nvim_create_autocmd')
      vim.api.nvim_exec_autocmds(name, { group = group })
      assert.stub(s).was.called_with('SafeState', expects)
      vim.api.nvim_del_autocmd(id)
    end)
  end)
end)
