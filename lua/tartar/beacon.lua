---@class Beacon:BeaconInstance
---@field new fun(hl:string,interval:integer,blend:integer,decay:integer):BeaconInstance
---@field around_cursor? fun(self,winid:integer)
---@field replaced_region fun(self,regcontents:string,height:integer,end_point:boolean)

---@class BeaconInstance
---@field timer uv.uv_timer_t
---@field is_running boolean
---@field hlgroup string
---@field interval integer
---@field blend integer
---@field decay integer

---@class Beacon
local M = {}
local helper = require('tartar.helper')
local compat = require('tartar.compat')

---@private
local DEFAULT_OPTIONS = {
  relative = 'win',
  height = 1,
  focusable = false,
  noautocmd = true,
  border = false,
  style = 'minimal',
}

---@param hlgroup string Hlgroup
---@param interval integer repeat interval
---@param blend integer Initial value of winblend
---@param decay integer winblend becay
function M.new(hlgroup, interval, blend, decay)
  vim.validate('hlgroup', hlgroup, 'string', true)
  vim.validate('interval', interval, 'number', true)
  vim.validate('blend', blend, 'number', true)
  vim.validate('decay', decay, 'number', true)
  return setmetatable({
    timer = assert(vim.uv.new_timer()),
    is_running = false,
    hlgroup = hlgroup or 'IncSearch',
    interval = interval or 100,
    blend = blend or 0,
    decay = decay or 15,
  }, { __index = M })
end

-- Flash around the cursor
---@param winid integer
function M:around_cursor(winid)
  local text = vim.api.nvim_get_current_line()
  local cur_col = vim.api.nvim_win_get_cursor(winid)[2]
  local charidx = compat.str_utfindex(text, 'utf-32', cur_col, false)
  local cur_charwidth = helper.charwidth(text, charidx)
  local next_charwidth = helper.charwidth(text, charidx + 1)
  local winwidth = next_charwidth == 0 and cur_charwidth * 3 or cur_charwidth * 2 + next_charwidth
  local row = vim.fn.winline() - 1
  local col = vim.fn.wincol() - 1 - cur_charwidth
  local relative = 'win'
  self:flash({ height = 1, width = math.max(1, winwidth), row = row, col = col, relative = relative })
end

---@alias WindowRelative 'editor'|'win'|'cursor'|'mouse'
---@alias WindowRegion {height:integer,width:integer,row:integer,col:integer,relative:WindowRelative}

---@param text string The text that was replaced.
---@param height integer The height of the replaced region.
---@param end_point boolean Indicates whether the replacement happened at the end of a line.
function M:replaced_region(text, height, end_point)
  local textwidth = vim.api.nvim_strwidth(text)
  local cur_charwidth = helper.charwidth(text, 0)
  local region = {
    height = height,
    width = textwidth,
    row = end_point and (1 - height) or 0,
    col = end_point and (cur_charwidth - textwidth) or 0,
    relative = 'cursor',
  }
  self:flash(region)
end

-- Flash around the cursor position
---@param region {height:integer,width:integer,row:integer,col:integer,relative?:string}
function M:flash(region)
  if not self.is_running then
    self.is_running = true
    vim.schedule(function()
      local opts = vim.tbl_extend('force', DEFAULT_OPTIONS, region)
      local bufnr = vim.api.nvim_create_buf(false, true)
      self.winid = vim.api.nvim_open_win(bufnr, false, opts)
      vim.api.nvim_set_option_value(
        'winhighlight',
        ('Normal:%s,EndOfBuffer:%s'):format(self.hlgroup, self.hlgroup),
        { win = self.winid }
      )
      vim.api.nvim_set_option_value('winblend', self.blend, { win = self.winid })
      self.timer:start(
        0,
        self.interval,
        vim.schedule_wrap(function()
          if not vim.api.nvim_win_is_valid(self.winid) then
            return
          end
          local blending = vim.api.nvim_get_option_value('winblend', { win = self.winid }) + self.decay
          if blending > 100 then
            blending = 100
          end
          vim.api.nvim_set_option_value('winblend', blending, { win = self.winid })
          if vim.api.nvim_get_option_value('winblend', { win = self.winid }) == 100 and self.timer:is_active() then
            self.timer:stop()
            self.is_running = false
            vim.api.nvim_win_close(self.winid, true)
          end
        end)
      )
    end)
  else
    vim.api.nvim_win_set_config(self.winid, region)
    vim.api.nvim_set_option_value('winblend', self.blend, { win = self.winid })
  end
end

---@class CursorMarkerOptions
---@field end_row? integer
---@field end_col? integer
---@field higroup? string
---@field priority? integer
---@field timeout? integer
---@field close_event? string|string[]

---@param bufnr integer
---@param ns integer
---@param augroup integer
---@param line integer
---@param col integer
---@param opts CursorMarkerOptions
---@return fun()? close_func
function M.cursor_marker(bufnr, ns, augroup, line, col, opts)
  bufnr = bufnr ~= 0 and bufnr or vim.api.nvim_win_get_buf(0)
  local higroup = opts.higroup or 'Search'
  local start = { line, col }
  local finish = { opts.end_row or line, opts.end_col or col + 1 }
  local cmd_opts = {
    regtype = '\x16',
    inclusive = false,
    priority = opts.priority,
    timeout = opts.timeout or 2000,
  }
  local timer, close_func = vim.hl.range(bufnr, ns, higroup, start, finish, cmd_opts)
  if opts.close_event and type(close_func) == 'function' then
    ---@cast timer uv.uv_timer_t
    timer:stop()
    timer:close()
    vim.api.nvim_create_autocmd('SafeState', {
      group = augroup,
      buffer = bufnr,
      once = true,
      callback = function()
        vim.api.nvim_create_autocmd(opts.close_event, {
          group = augroup,
          buffer = bufnr,
          callback = function(ev)
            close_func()
            vim.api.nvim_del_autocmd(ev.id)
          end,
        })
      end,
    })
  end
  return close_func
end

return M
