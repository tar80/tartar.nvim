---@diagnostic disable: param-type-mismatch
local assert = require('luassert')
local util = require('tartar.util')

describe('util', function()
  describe('.value_or_nil()', function()
    it('returns the value if the boolean is true', function()
      local bool = true
      local value = 'test'
      assert.are.equal(value, util.value_or_nil(bool, value))
    end)

    it('returns nil if the boolean is neither true nor false', function()
      local bool = false
      local bool_nil = nil
      local bool_number = 123
      local bool_string = 'true'
      local value = 'test'
      assert.is_nil(util.value_or_nil(bool, value))
      assert.is_nil(util.value_or_nil(bool_nil, value))
      assert.is_nil(util.value_or_nil(bool_number, value))
      assert.is_nil(util.value_or_nil(bool_string, value))
    end)
  end)

  describe('.name_formatter()', function()
    it('returns a formatted message with the given name', function()
      local name = 'test_name'
      local message = 'Hello, %s!'
      local formatter = util.name_formatter(name)
      assert.are.equal('Hello, test_name!', formatter(message))
    end)

    it('handles empty name correctly', function()
      local name = ''
      local message = 'Name: %s'
      local formatter = util.name_formatter(name)
      assert.are.equal('Name: ', formatter(message))
    end)

    it('handles name with special characters', function()
      local name = '!@#$%^&*'
      local message = 'Special: %s'
      local formatter = util.name_formatter(name)
      assert.are.equal('Special: !@#$%^&*', formatter(message))
    end)
  end)

  describe('.evaluated_condition()', function()
    it('returns the first argument if the value matches the validator', function()
      local value = 'string'
      local validator = 'string'
      local condition = util.evaluated_condition(value, validator)
      assert.are.equal('first', condition('first', 'second'))
    end)

    it('returns the second argument if the value does not match the validator', function()
      local value = 'string'
      local validator = 'number'
      local condition = util.evaluated_condition(value, validator)
      assert.are.equal('second', condition('first', 'second'))
    end)

    it('returns the second argument if value is nil', function()
      local value = nil
      local validator = 'string'
      local condition = util.evaluated_condition(value, validator)
      assert.are.equal('second', condition('first', 'second'))
    end)

    it('returns the second argument if validator is nil', function()
      local value = 'string'
      local validator = nil
      local condition = util.evaluated_condition(value, validator)
      assert.are.equal('second', condition('first', 'second'))
    end)

    it('handles type mismatch with unexpected validator type', function()
      local value = 'string'
      local validator = { type = 'string' } -- validator is not a simple string
      local condition = util.evaluated_condition(value, validator)
      assert.are.equal('second', condition('first', 'second'))
    end)
  end)

  describe('.repeat_pattern()', function()
    it('returns the repeated pattern if count is a valid number', function()
      local pattern = 'abc'
      local count = 3
      assert.are.equal('abcabcabc', util.repeat_pattern(pattern, count))
    end)

    it('returns an empty string if count is not a valid number', function()
      local pattern = 'abc'
      local count = 'invalid'
      assert.are.equal('', util.repeat_pattern(pattern, count))
    end)

    it('returns an empty string if pattern is empty', function()
      local pattern = ''
      local count = 5
      assert.are.equal('', util.repeat_pattern(pattern, count))
    end)

    it('returns an empty string if count is 0', function()
      local pattern = 'abc'
      local count = 0
      assert.are.equal('', util.repeat_pattern(pattern, count))
    end)

    it('returns an empty string if count is negative', function()
      local pattern = 'abc'
      local count = -2
      assert.are.equal('', util.repeat_pattern(pattern, count))
    end)

    it('handles large count', function()
      local pattern = 'a'
      local count = 1000000 -- A large number
      local expected_pattern = string.rep(pattern, count) -- Lua's built-in string.rep
      assert.are.equal(expected_pattern, util.repeat_pattern(pattern, count))
    end)
  end)

  describe('.extract_filename()', function()
    it('returns the filename from a given filepath', function()
      local filepath = '/path/to/file.txt'
      assert.are.equal('file.txt', util.extract_filename(filepath))
      filepath = 'C:\\path\\to\\file.txt'
      assert.are.equal('file.txt', util.extract_filename(filepath))
    end)

    it('returns an empty string if filepath is empty', function()
      local filepath = ''
      assert.are.equal('', util.extract_filename(filepath))
    end)

    it('returns the original string if no path separator is present', function()
      local filepath = 'myfile.txt'
      assert.are.equal('myfile.txt', util.extract_filename(filepath))
    end)

    it('returns an empty string if filepath ends with a path separator', function()
      local filepath = '/path/to/'
      assert.are.equal('', util.extract_filename(filepath))
    end)

    it('handles file with multiple dots in name', function()
      local filepath = '/path/to/archive.tar.gz'
      assert.are.equal('archive.tar.gz', util.extract_filename(filepath))
    end)
  end)

  describe('.extract_fileext()', function()
    it('returns the file extension from a given filepath', function()
      local filepath = '/path/to/file.txt'
      assert.are.equal('txt', util.extract_fileext(filepath))
    end)

    it('returns the file extension from a given filepath with backslashes', function()
      local filepath = 'C:\\path\\to\\file.txt'
      assert.are.equal('txt', util.extract_fileext(filepath))
    end)

    it('returns an empty string if filepath is empty', function()
      local filepath = ''
      assert.are.equal('', util.extract_fileext(filepath))
    end)

    it('returns an empty string if filepath has no extension', function()
      local filepath = '/path/to/myfile'
      assert.are.equal('', util.extract_fileext(filepath))
    end)

    it('returns an empty string if filepath ends with a dot', function()
      local filepath = '/path/to/myfile.'
      assert.are.equal('', util.extract_fileext(filepath))
    end)

    it('handles file with multiple dots in name', function()
      local filepath = '/path/to/archive.tar.gz'
      assert.are.equal('gz', util.extract_fileext(filepath))
    end)

    it('handles Windows paths with drive letter', function()
      local filepath = 'D:\\Documents\\report.docx'
      assert.are.equal('docx', util.extract_fileext(filepath))
    end)
  end)

  describe('.tbl_insert()', function()
    local tbl
    before_each(function()
      tbl = { a = 1, b = 2, c = { 3 } }
    end)

    it('not specified "pos", the value must be inserted at the end', function()
      local key = 'c'
      local value = 4
      local expects = { a = 1, b = 2, c = { 3, 4 } }
      util.tbl_insert(tbl, key, value)
      assert.are.same(expects, tbl)
    end)

    it('specified "pos", the value must be inserted at the specified position', function()
      local key = 'c'
      local value = 4
      local expects = { a = 1, b = 2, c = { 4, 3 } }
      util.tbl_insert(tbl, key, 1, value)
      assert.are.same(expects, tbl)
    end)

    it('does not exist "key" in the specified table, "key" must be added', function()
      local key = 'd'
      local value = 4
      local expects = { a = 1, b = 2, c = { 3 }, d = { 4 } }
      util.tbl_insert(tbl, key, value)
      assert.are.same(expects, tbl)
    end)

    it('inserts into a non-table input for tbl', function()
      local invalid_tbl = 123
      local key = 'd'
      local value = 4
      assert.has_error(function()
        util.tbl_insert(invalid_tbl, key, value)
      end, "Argument 'tbl' must be a table.")
    end)
  end)
end)
