local helper = require('tartar.helper')

local function _get_expand_lines(startline, endline)
  local lines = { base = vim.api.nvim_buf_get_lines(0, startline, endline + 1, false) }
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value('expandtab', true, { buf = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines.base)
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd.retab()
    lines.expand = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  end)
  vim.api.nvim_buf_delete(bufnr, { force = true })
  return lines
end

local function _get_match_index(ctx, block)
  local _re = vim.regex(ctx)
  return block
      and function(line)
        local match = _re:match_str(line:sub(block[1] + 1, block[2] + 1))
        if match then
          return block[1] + match
        end
      end
    or function(line)
      return _re:match_str(line)
    end
end

local _rgx = { prefix = [[\%[?$]], suffix = [[^\%[?]] }
local _align = {
  -- This function is based on https://github.com/RRethy/nvim-align
  -- is publicly available under the terms of the Vim license.
  ---@param block integer[]|false Index of start and end columns
  ---@return string[]? result Aligned lines
  align = function(self, ctx, block)
    local max = -1
    local acc = {}
    local result = {}
    local base_lines = self.lines.base
    local expand_lines = self.lines.expand
    local count = #base_lines
    local match_idx = _get_match_index(ctx, block)
    for n = 1, count, 1 do
      local base_line = base_lines[n]
      local expand_line = expand_lines[n]
      local idx_expand = match_idx(expand_line)
      if idx_expand then
        local idx = match_idx(base_line)
        ---@cast idx integer
        idx = vim.str_utfindex(base_line, helper.utf_encoding(), idx, false)
        max = math.max(idx_expand, max)
        acc[n] = { idx = idx, idx_expand = idx_expand, first = base_line:sub(1, idx), second = base_line:sub(idx + 1) }
      else
        acc[n] = { first = base_line, second = '' }
      end
    end
    if max == -1 then
      return
    end
    vim.iter(acc):enumerate():each(function(n, tbl)
      local aligned_line ---@type string
      if tbl.idx then
        local blank = (' '):rep(max - tbl.idx_expand)
        self:set_extmark(self.startline + n - 1, tbl.idx, blank)
        aligned_line = ('%s%s%s'):format(tbl.first, blank, tbl.second)
      else
        aligned_line = tbl.first
      end
      result[n] = aligned_line
    end)
    return result
  end,

  end_align = function(self)
    vim.on_key(nil, self.ns, {})
    self:clear_namespace()
    vim.api.nvim_input('<Esc>')
  end,

  ---@param typed string
  ---@param escape boolean
  ---@return nil|boolean|string
  input = function(self, typed, escape)
    if typed == '' then
      return
    end
    local key = vim.fn.keytrans(typed):lower()
    if key == '<cr>' then
      return true
    end
    if key == '<esc>' or key == '<c-c>' then
      return false
    end
    if key == '<del>' then
      if escape and self.ctx[2]:find(_rgx.suffix) then
        self.ctx[2] = self.ctx[2]:gsub(_rgx.suffix, '')
      else
        self.ctx[2] = self.ctx[2]:sub(2)
      end
    elseif key == '<bs>' or key == '<c-h>' then
      if escape and self.ctx[1]:find(_rgx.prefix) then
        self.ctx[1] = self.ctx[1]:gsub(_rgx.prefix, '')
      else
        self.ctx[1] = self.ctx[1]:sub(1, -2)
      end
    elseif key == '<left>' or key == '<c-b>' then
      self.ctx[2] = self.ctx[1]:sub(-1) .. self.ctx[2]
      self.ctx[1] = self.ctx[1]:sub(1, -2)
    elseif key == '<right>' or key == '<c-f>' then
      self.ctx[1] = self.ctx[1] .. self.ctx[2]:sub(1, 1)
      self.ctx[2] = self.ctx[2]:sub(2)
    elseif key == '<c-u>' then
      self.ctx[1] = ''
    elseif key == '<c-w>' then
      self.ctx[1] = self.ctx[1]:match('^(.*) ')
    elseif not typed:find('\x80') then
      if escape and typed:find('[', 1, true) then
        if not typed:find('\\[', 1, true) then
          typed = '\\['
        end
      end
      self.ctx[1] = self.ctx[1] .. typed
    end

    return self.ctx[1] .. self.ctx[2]
  end,

  ---@param row integer
  ---@param col integer
  ---@param blank string
  set_extmark = function(self, row, col, blank)
    vim.api.nvim_buf_set_extmark(self.bufnr, self.ns, row, col, {
      virt_text = { { blank, self.hlgroup } },
      virt_text_pos = 'inline',
    })
  end,

  clear_namespace = function(self)
    vim.api.nvim_buf_clear_namespace(self.bufnr, self.ns, self.startline, self.endline + 1)
  end,
}
_align.__index = _align

---@param ns integer
---@param hlgroup string
return function(ns, hlgroup)
  vim.validate('hlgroup', hlgroup, 'string', true)
  local aligned_lines ---@type string[]?
  local s, e = helper.get_selected_range(0, 0)
  local is_blockwise = helper.is_blockwise()
  local instance = setmetatable({
    ns = ns,
    bufnr = vim.api.nvim_get_current_buf(),
    hlgroup = (hlgroup or 'IncSearch'),
    lines = _get_expand_lines(s[1], e[1]),
    startline = s[1],
    endline = e[1] + 1,
    ctx = { '', '' },
  }, _align)
  vim.on_key(function(_, typed)
    local _ctx = instance:input(typed, true)

    if not _ctx then
      return
    end

    if type(_ctx) == 'boolean' then
      instance:end_align()
      return
    end
    instance:clear_namespace()
    if _ctx ~= '' then
      local block = is_blockwise and { s[2], e[2] }
      aligned_lines = instance:align(_ctx, block)
    end
    vim.cmd.redraw()
  end, ns, {})
  vim.ui.input({ prompt = 'align(regex): ' }, function(input)
    if input and input ~= '' and aligned_lines then
      vim.api.nvim_buf_set_lines(0, instance.startline, instance.endline, false, aligned_lines)
    end
    instance:end_align()
  end)
end
