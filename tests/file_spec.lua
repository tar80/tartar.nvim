---@diagnostic disable: need-check-nil
local assert = require('luassert')
local tartar_file = require('tartar.file')

describe('tartar.file', function()
  describe('.write()', function()
    local base_temp = vim.env.TEMPDIR or vim.env.TMP or vim.env.TEMP or '/tmp'
    local root_dir = vim.fs.normalize(base_temp .. '/nvim_tartar_test')

    it('writes data to a file', function()
      local test_path = root_dir .. '/test_file.txt'
      local test_contents = 'Hello, world!'
      local ok, message = tartar_file.write(test_path, test_contents)

      assert.is_true(ok)
      assert.equal('Created the file.', message)
      local file = io.open(test_path, 'r')
      assert.is_not_nil(file)
      local read_contents = file:read('*a')
      assert.equal(test_contents, read_contents)
      file:close()
    end)

    it('writes table contents to a file, separated by newlines', function()
      local test_path = root_dir .. '/test_file_table.txt'
      local test_contents = { 'line 1', 'line 2', 'line 3' }
      local expected_contents = 'line 1\nline 2\nline 3'
      local ok, message = tartar_file.write(test_path, test_contents)

      assert.is_true(ok)
      assert.equal('Created the file.', message)
      local file = io.open(test_path, 'r')
      assert.is_not_nil(file)
      local read_contents = file:read('*a')
      assert.equal(expected_contents, read_contents)
      file:close()
    end)

    it('creates parent directories if they do not exist', function()
      local test_path = root_dir .. '/subdir/another_file.txt'
      local test_contents = 'Content in nested file.'
      local ok, message = tartar_file.write(test_path, test_contents)

      assert.is_true(ok)
      assert.equal('Created the file.', message)
      local file = io.open(test_path, 'r')
      assert.is_not_nil(file)
      local read_contents = file:read('*a')
      assert.equal(test_contents, read_contents)
      file:close()
    end)

    it('returns false if file cannot be opened', function()
      local invalid_path
      if vim.fn.has('win32') == 1 then
        invalid_path = 'invalid*/no_permission.txt'
      else
        invalid_path = '/root/no_permission.txt'
      end
      local test_contents = 'This should not be written.'
      local ok, message = tartar_file.write(invalid_path, test_contents)

      assert.is_false(ok)
      assert.is_string(message)
    end)
    vim.fn.delete(root_dir, 'rf')
  end)
end)
