local TEMPLATE = {
  '-- Instant Benchmark -----------------------------------------------------------',
  '---@desc Use the `bench.clear()` method to clear the block.',
  'local bench = require("tartar.sauce.bench")',
  '',
  '-- @generic Ret any',
  '-- @param loop_count integer',
  '-- @param ... (fun():Ret)[]',
  '-- @return {[integer]: {return:Ret, time:number}}',
  '-- print(loop_count, ...)',
  '-- notify(loop_count, ...)',
  'bench.print(1, function()',
  '%s',
  '%sreturn',
  'end, function()',
  '%sreturn',
  'end)',
  '--------------------------------------------------------------------------------',
}

---@generic Ret any
---@alias ResultTable {[integer]: [number, Ret]}
---@param loop_count integer
---@param ... (fun():Ret)[]
---@return ResultTable
local function _bench(loop_count, ...)
  vim.validate('loop_count', loop_count, 'number')
  local result = {}
  vim.iter({ ... }):enumerate():each(function(n, f)
    if type(f) == 'function' then
      local ret
      local s = vim.fn.reltime()
      for _ = 1, loop_count do
        ret = f()
      end
      result[n] = { time = vim.trim(vim.fn.reltimestr(vim.fn.reltime(s))), ret = ret }
    end
  end)
  return result
end

local function _do_staba_update_mark()
  if package.loaded['staba'] then
    vim.cmd([[silent! doautocmd User StabaUpdateMark]])
  end
end

---@param is_notify boolean Use vim.notify as notifier
---@param start_mark string Mark to be set at the start line of the template
---@param end_mark string Mark to be set at the end line of the template
local function _insert_template(is_notify, start_mark, end_mark)
  start_mark = start_mark or 'a'
  end_mark = end_mark or 'b'
  local bufnr = vim.api.nvim_win_get_buf(0)
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local sts = vim.bo.softtabstop
  local indent = string.rep(' ', sts)
  local template = vim
    .iter(TEMPLATE)
    :map(function(ctx)
      if is_notify and ctx:find('bench.print', 1, true) then
        ctx = ctx:gsub('print', 'notify')
      end
      return ctx:find('%s', 1, true) and ctx:format(indent) or ctx
    end)
    :totable()
  vim.b.tartar_benchmark_mark = { start_mark, end_mark }
  vim.api.nvim_buf_set_lines(bufnr, row, row, true, template)
  vim.api.nvim_buf_set_mark(bufnr, start_mark, row + 1, 0, {})
  vim.api.nvim_buf_set_mark(bufnr, end_mark, row + #template, 0, {})
  vim.cmd([[undojoin|delete|norm 11j$]])
  _do_staba_update_mark()
end

local function _clear()
  local marks = vim.b.tartar_benchmark_mark
  if marks then
    local bufnr = vim.api.nvim_win_get_buf(0)
    vim.cmd(("'%s,'%sd"):format(marks[1], marks[2]))
    vim.api.nvim_buf_del_mark(bufnr, marks[1])
    vim.api.nvim_buf_del_mark(bufnr, marks[2])
    vim.b.tartar_benchmark_mark = nil
    _do_staba_update_mark()
  end
end

---@param tbl ResultTable
---@return string msg
local function _format_msg(tbl)
  local msg = ''
  vim.iter(tbl):enumerate():each(function(n, t)
    msg = ('%s[%s] (%s) - %s\n'):format(msg, n, t.time, t.ret)
  end)
  return msg
end

local function _print(loop_count, ...)
  local result = _bench(loop_count, ...)
  local msg = _format_msg(result)
  print(msg)
end

local function _notify(loop_count, ...)
  local result = _bench(loop_count, ...)
  local msg = _format_msg(result)
  vim.notify(msg, vim.log.levels.DEBUG, { title = 'Instant Benchmark' })
end

return {
  run = _bench,
  print = _print,
  notify = _notify,
  insert_template = _insert_template,
  clear = _clear,
}
