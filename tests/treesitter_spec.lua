---@diagnostic disable: param-type-mismatch, need-check-nil, missing-parameter, duplicate-set-field, redefined-local, unused-local
local assert = require('luassert')
local ts = require('tartar.treesitter')

describe('treesitter', function()
  describe('.get_language()', function()
    it('returns the correct language for a given filetype', function()
      local filetype = 'lua'
      local expected_filetype = 'lua'
      assert.are.equal(expected_filetype, ts.get_language(filetype))
      filetype = 'help'
      expected_filetype = 'vimdoc'
      assert.are.equal(expected_filetype, ts.get_language(filetype))
      filetype = 'unknown filetype'
      expected_filetype = 'unknown filetype'
      assert.are.equal(expected_filetype, ts.get_language(filetype))
      filetype = ''
      assert.is_nil(ts.get_language(filetype))
    end)
  end)

  describe('.get_highlights_query()', function()
    it('returns a query object for a supported language', function()
      local language = 'lua'
      local query = ts.get_highlights_query(language)
      assert.is.equal(language, query.lang)
      assert.is_userdata(query.query)
    end)

    it('returns nil for an unsupported language', function()
      local language = 'unsupported_language'
      assert.is_nil(ts.get_highlights_query(language))
      language = ''
      assert.is_nil(ts.get_highlights_query(language))
    end)
  end)

  describe('.range4()', function()
    it('returns a range table for a given node', function()
      local node = {
        range = function()
          return 1, 2, 3, 4
        end,
      }
      local expected_range = { 1, 2, 3, 4 }
      assert.are.same(expected_range, ts.range4(node))
    end)
  end)

  describe('.is_contains()', function()
    it('returns true if the position is within the range', function()
      local range = { 1, 2, 3, 4 }
      assert.is_true(ts.is_contains(range, 1, 2))
      assert.is_true(ts.is_contains(range, 3, 3))
    end)

    it('returns false if the position is outside the range', function()
      local range = { 1, 2, 3, 4 }
      assert.is_false(ts.is_contains(range, 0, 0))
      assert.is_false(ts.is_contains(range, 3, 4))
    end)
  end)

  describe('.node_contains()', function()
    it('returns true if range1 contains range2', function()
      local range1 = { 1, 2, 3, 4 }
      local range2 = { 2, 3, 2, 4 }
      assert.is_true(ts.node_contains(range1, range2))
    end)

    it('returns false if range1 does not contain range2', function()
      local range1 = { 1, 2, 3, 4 }
      local range2 = { 0, 0, 0, 0 }
      assert.is_false(ts.node_contains(range1, range2))
    end)
  end)

  describe('.get_node()', function()
    it('returns nil when tree_for_range returns nil', function()
      local mock_tree_no_range = {
        lang = 'lua',
        tree_for_range = function()
          return nil
        end,
      }
      local root = mock_tree_no_range
      local range = { 1, 0, 1, 5 }

      local original_convert_range4 = ts._convert_range4
      ts._convert_range4 = function(range)
        return range
      end

      local found_tree, found_node = ts.get_node(root, range)

      assert.is_nil(found_tree)
      assert.is_nil(found_node)

      ts._convert_range4 = original_convert_range4
    end)
  end)

  describe('.get_text_at_pos()', function()
    it('returns the text within the node range', function()
      local mock_bufnr = 1
      local mock_node = {
        range = function()
          return 1, 0, 1, 5
        end,
      }
      local expected_text = 'hello'

      local original_nvim_buf_get_text = vim.api.nvim_buf_get_text
      vim.api.nvim_buf_get_text = function(buf, s_row, s_col, e_row, e_col, opts)
        assert.are.equal(mock_bufnr, buf)
        assert.are.equal(1, s_row)
        assert.are.equal(0, s_col)
        assert.are.equal(1, e_row)
        assert.are.equal(5, e_col)
        return { 'hello' }
      end

      local text = ts.get_text_at_pos(mock_bufnr, mock_node)
      assert.are.equal(expected_text, text)

      vim.api.nvim_buf_get_text = original_nvim_buf_get_text
    end)

    it('adjusts start row and col when top is provided', function()
      local mock_bufnr = 1
      local mock_node = {
        range = function()
          return 1, 5, 1, 10
        end,
      }
      local top = 1
      local bottom = nil
      local expected_text = 'world'

      local original_nvim_buf_get_text = vim.api.nvim_buf_get_text
      vim.api.nvim_buf_get_text = function(buf, s_row, s_col, e_row, e_col, opts)
        assert.are.equal(mock_bufnr, buf)
        assert.are.equal(1, s_row)
        assert.are.equal(5, s_col)
        assert.are.equal(1, e_row)
        assert.are.equal(10, e_col)
        return { 'world' }
      end

      vim.api.nvim_buf_get_text(mock_bufnr, 1, 5, 1, 10, {})

      local text = ts.get_text_at_pos(mock_bufnr, mock_node, top, bottom)
      assert.are.equal(expected_text, text)

      vim.api.nvim_buf_get_text = original_nvim_buf_get_text
    end)

    it('adjusts end row and col when bottom is provided', function()
      local mock_bufnr = 1
      local mock_node = {
        range = function()
          return 1, 0, 5, 10
        end,
      }
      local top = nil
      local bottom = 3
      local expected_text = 'hello\nthere'

      local original_nvim_buf_get_text = vim.api.nvim_buf_get_text
      vim.api.nvim_buf_get_text = function(buf, s_row, s_col, e_row, e_col, opts)
        assert.are.equal(mock_bufnr, buf)
        assert.are.equal(1, s_row)
        assert.are.equal(0, s_col)
        assert.are.equal(3, e_row)
        assert.are.equal(vim.fn.col({ 3 + 1, '$' }), e_col)
        return { 'hello', 'there' }
      end

      local original_vim_fn_col = vim.fn.col
      vim.fn.col = function(opts)
        if opts == { 3 + 1, '$' } then
          return 10
        end
        return 0
      end

      local text = ts.get_text_at_pos(mock_bufnr, mock_node, top, bottom)
      assert.are.equal(expected_text, text)

      vim.api.nvim_buf_get_text = original_nvim_buf_get_text
      vim.fn.col = original_vim_fn_col
    end)

    it('returns correct text when top and bottom are provided', function()
      local mock_bufnr = 1
      local mock_node = {
        range = function()
          return 1, 0, 5, 10
        end,
      }
      local top = 2
      local bottom = 4
      local expected_text = 'line2\nline3\nline4'

      local original_nvim_buf_get_text = vim.api.nvim_buf_get_text
      vim.api.nvim_buf_get_text = function(buf, s_row, s_col, e_row, e_col, opts)
        assert.are.equal(mock_bufnr, buf)
        assert.are.equal(2, s_row)
        assert.are.equal(0, s_col)
        assert.are.equal(4, e_row)
        assert.are.equal(vim.fn.col({ 4 + 1, '$' }), e_col)
        return { 'line2', 'line3', 'line4' }
      end

      local original_vim_fn_col = vim.fn.col
      vim.fn.col = function(opts)
        if opts == { 4 + 1, '$' } then
          return 10
        end
        return 0
      end

      local text = ts.get_text_at_pos(mock_bufnr, mock_node, top, bottom)
      assert.are.equal(expected_text, text)

      vim.api.nvim_buf_get_text = original_nvim_buf_get_text
      vim.fn.col = original_vim_fn_col
    end)

    it('handles empty text return from nvim_buf_get_text', function()
      local mock_bufnr = 1
      local mock_node = {
        range = function()
          return 1, 0, 1, 5
        end,
      }
      local expected_text = ''

      local original_nvim_buf_get_text = vim.api.nvim_buf_get_text
      vim.api.nvim_buf_get_text = function(buf, s_row, s_col, e_row, e_col, opts)
        return {}
      end

      local text = ts.get_text_at_pos(mock_bufnr, mock_node)
      assert.are.equal(expected_text, text)

      vim.api.nvim_buf_get_text = original_nvim_buf_get_text
    end)
  end)
end)
