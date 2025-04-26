---@class helper
local M = {}

---@alias LogLevels 'TRACE'|'DEBUG'|'INFO'|'WARN'|'ERROR'|'OFF'
---@alias UtfEncoding 'utf-8'|'utf-16'|'utf-32'

---@param name string
---@param subject string
---@param msg string|string[][]
function M.echo(name, subject, msg)
  if type(msg) == 'string' then
    msg = { { msg } }
  end
  vim.api.nvim_echo({ { string.format('[%s] %s: ', name, subject) }, unpack(msg) }, false, {})
end

---@generic F : fun()
---@param func F
---@return fun(F)|fun()
function M.fast_event_wrap(func)
  return vim.in_fast_event() and vim.schedule_wrap(func) or func
end

-- Get the current utf encoding
---@param encoding? string
---@return string encoding
function M.utf_encoding(encoding)
  encoding = string.lower(encoding or '')
  if encoding == 'utf-8' or encoding == 'utf-16' then
    return encoding
  end
  return 'utf-32'
end

-- Get list of option values
---@param name string vim option name
---@param option? table
---@return string[]
function M.split_option_value(name, option)
  return vim.split(vim.api.nvim_get_option_value(name, option or {}), ',', { plain = true })
end

-- Get the wrap marker status numerically
---@return integer extends,integer precedes
function M.get_wrap_marker_flags()
  local listchars = vim.opt.listchars:get()
  local extends = listchars.extends and 1 or 0
  local precedes = listchars.precedes and 1 or 0
  return extends, precedes
end

---@alias WinPos [integer, integer]

---Get currently selected visual range on zero-based index.
---@param base_row integer Whether the starting row is 0 or 1
---@param base_col integer Whether the starting column is 0 or 1
---@return WinPos,WinPos,boolean
function M.get_selected_range(base_row, base_col, is_blockwise)
  base_row = base_row == 1 and 0 or 1
  base_col = base_col == 1 and 0 or 1
  local cur, op = vim.fn.getpos('.'), vim.fn.getpos('v')
  local is_reverse = false
  if cur[4] > 0 then
    local tail = is_blockwise and cur[3] or 0
    cur[3] = tail + cur[4]
  end
  if op[4] > 0 then
    local tail = is_blockwise and op[3] or 0
    op[3] = tail + op[4]
  end
  if cur[2] > op[2] then
    cur, op = op, cur
    is_reverse = true
  end
  if cur[3] > op[3] then
    cur[3], op[3] = op[3], cur[3]
  end
  local s, e
  s = { cur[2] - base_row, cur[3] - base_col }
  e = { op[2] - base_row, op[3] - base_col }
  return s, e, is_reverse
end

-- Check the number of characters on the display
---@param string string
---@param column integer
---@return integer charwidth
function M.charwidth(string, column)
  return vim.api.nvim_strwidth(vim.fn.strcharpart(string, column, 1, true))
end

---Replaces "<" in the string with "<lt>"
---@param text string
M.replace_lt = function(text)
  return text:gsub('<([%a-]+>)', '<lt>%1')
end

---@return boolean
function M.is_windows()
  return jit.os == 'Windows'
end

---@param sentence string
---@return boolean `Blob or not`
function M.is_blob(sentence)
  return vim.fn.type(sentence) == vim.v.t_blob
end

-- Operator-pending or not
---@param mode? string
function M.is_operator(mode)
  if not mode then
    mode = vim.api.nvim_get_mode().mode
  end
  return mode:find('^no')
end

-- Determine whether the specified string is in insert-mode.
---@param mode? string
---@return boolean
function M.is_insert_mode(mode)
  mode = mode or vim.api.nvim_get_mode().mode
  return mode:find('^[i|R]') ~= nil
end

-- Determines whether the specified string indicates a blockwise.
---@param mode? string
---@return boolean
function M.is_blockwise(mode)
  mode = mode or vim.api.nvim_get_mode().mode
  return mode:find('\x16', 1, true) ~= nil
end

---@param value string|integer
---@return boolean|nil
local function _is_truthy(value)
  return value and tonumber(value) ~= 0
end

---Check the boolean value of user variables set locally/globally
---@param name string
---@return boolean|nil
function M.is_enable_user_vars(name)
  local b = vim.b[name]
  local g = vim.g[name]
  return _is_truthy(b) or _is_truthy(g)
end

---@param winid integer
---@return boolean
function M.is_floating_win(winid)
  return vim.api.nvim_win_get_config(winid).relative ~= ''
end

-- Function to parse a file URI and retrieve the parent directory and file name
---@param bufnr integer The buffer number
---@return string? wd The parent directory name
---@return string? filename The file name
function M.parse_path(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil, nil
  end
  ---@type string,string
  local wd, name
  local uri = vim.uri_from_bufnr(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  if uri:find('file://', 1, true) then
    name = path
    wd = vim.fs.dirname(path)
  else
    local scheme_end = uri:find('://', 1, true)
    if scheme_end then
      name = uri:sub(1, scheme_end) .. path:gsub('^.*[\\/]', '')
      wd = ''
    else
      name = path
      wd = ''
    end
  end
  return wd, name
end

local function _value_converter(value)
  local tbl = {}
  local t = type(value)
  if t == 'function' then
    tbl = value()
    return type(tbl) == 'table' and tbl or {}
  elseif t == 'string' then
    return { value }
  elseif t == 'table' then
    for att, _value in pairs(value) do
      local att_t = type(_value)
      if att_t == 'function' then
        _value = _value()
        if _value then
          tbl[att] = _value
        end
      end
      tbl[att] = _value
    end
    return tbl
  end
  return tbl
end

-- Set default highlights
---@param hlgroups table<string,vim.api.keyset.highlight>
function M.set_hl(hlgroups)
  vim.iter(hlgroups):each(function(name, value)
    local hl = _value_converter(value)
    hl['default'] = true
    vim.api.nvim_set_hl(0, name, hl)
  end)
end

-- Set reverse highlights
---@param hlgroups string[]
function M.set_reverse_hl(hlgroups)
  vim.iter(hlgroups):each(function(name)
    local ref_hl = vim.api.nvim_get_hl(0, { name = name, create = false })
    if ref_hl.link then
      ref_hl = vim.api.nvim_get_hl(0, { name = ref_hl.link, create = false })
    end
    local new_hl = {
      fg = ref_hl.bg,
      bg = ref_hl.fg,
    }
    if type(ref_hl.cterm) == 'table' then
      new_hl = vim.tbl_deep_extend('force', new_hl, ref_hl.cterm)
    end

    vim.api.nvim_set_hl(0, name .. 'Reverse', new_hl)
  end)
end

---@param name string|string[]
---@param opts vim.api.keyset.create_autocmd
---@param safestate? boolean
function M.autocmd(name, opts, safestate)
  local callback = opts.callback
  opts.pattern = opts.pattern or '*'
  if safestate then
    opts.callback = function()
      opts.once = true
      opts.callback = callback
      vim.api.nvim_create_autocmd('SafeState', opts)
    end
  end
  vim.api.nvim_create_autocmd(name, opts)
end

---@param sep_l string Left spearator
---@param sep_r string Right spearator
---@param hlgroup string Hlgroup
---@return string[] float_border
function M.generate_decorative_line(sep_l, sep_r, hlgroup)
  local l = sep_l and { sep_l, hlgroup } or ''
  local r = sep_r and { sep_r, hlgroup } or ''
  return { '', '', '', r, '', '', '', l }
end

---@param hlgroup string Hlgroup
---@return string[] float_border
function M.generate_quotation(hlgroup)
  return { '', '', '', '', '', '', '', { '▋', hlgroup or 'SpecialKey' } }
end

return M
