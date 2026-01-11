---@alias TaplePosition [integer,integer]:[lnum,col]
---@alias VisualStartPoint TaplePosition
---@alias VisualEndPoint TaplePosition

---@class LiveReplaceOpts
---@field after? boolean Insert after cursor position
---@field zero? boolean Insert zero column position
---@field fill? boolean Fill virtual column with spaces
---@field is_replace? boolean Whether to replace the selected range
---@field send_key? boolean @deprecated
---@field overwrite? boolean Whether to send keys that overwrite the selection
---@field linewise_blockify? boolean Enables block editing in linewise visual mode
---@field higroup? string Highlight for cursor position marker

return function(unique_name, ns, augroup)
  local helper = require('tartar.helper')
  local with_unique_name = require('tartar.util').name_formatter(unique_name)

  ---Get the column width after replacement
  ---@param col integer
  ---@return integer col
  local function _get_new_endcol(col)
    local text = vim.fn.histget('cmd', -1):gsub('^.*/(.*)/[&cegiInp#lr]*$', '%1')
    return col + #text - 1
  end

  ---Post-processing after replacement
  ---@param s VisualStartPoint
  ---@param e VisualEndPoint
  ---@param after boolean?
  ---@param modified boolean?
  local function _set_autocmd(s, e, after, modified)
    vim.api.nvim_create_autocmd('CmdlineLeave', {
      desc = with_unique_name('%s: live rectangle replacement'),
      group = augroup,
      once = true,
      callback = function(ev)
        local is_abort = vim.v.event.abort
        vim.schedule(function()
          local start_col, end_col = s[2], s[2]
          if after then
            start_col, end_col = e[2], e[2]
            s[2] = s[2] - 1
            e[2] = e[2] - 1
          end
          vim.api.nvim_win_set_cursor(0, { s[1], start_col })
          if is_abort then
            start_col, end_col = s[2], e[2]
            if modified then
              vim.api.nvim_input('u')
            end
          else
            end_col = _get_new_endcol(end_col)
          end
          vim.api.nvim_buf_set_mark(ev.buf, '<', s[1], start_col, {})
          vim.api.nvim_buf_set_mark(ev.buf, '>', e[1], end_col, {})
        end)
      end,
    })
  end

  ---Marker placed at replacement position
  local function _cursor_marker(bufnr, start_row, start_col, end_row, end_col, marker_higroup)
    require('tartar.beacon').cursor_marker(bufnr, ns, augroup, start_row, start_col, {
      end_row = end_row,
      end_col = end_col,
      higroup = marker_higroup,
      close_event = { 'CmdlineLeave', 'CmdlineChanged' },
    })
  end

  ---Correct the selection range considering virtual column
  ---@param bufnr integer
  ---@param s VisualStartPoint
  ---@param e VisualEndPoint
  ---@param fill_in 'start'|'end'|nil
  ---@return VisualStartPoint, VisualEndPoint, boolean
  local function _normalize_range(bufnr, s, e, fill_in)
    local lines = vim.api.nvim_buf_get_lines(bufnr, s[1] - 1, e[1], false)
    local start_row, start_col = s[1], s[2]
    local end_row, end_col = e[1], e[2]
    local modified = false
    local it = vim.iter(lines):enumerate()
    if fill_in ~= nil then
      local _col = fill_in == 'start' and start_col or end_col
      it:each(function(i, line)
        local width = #line
        if start_col > width then
          lines[i] = line .. (' '):rep(_col - width)
          modified = true
        end
      end)
      if modified then
        vim.api.nvim_buf_set_lines(bufnr, start_row - 1, end_row, true, lines)
      end
    else
      local reversed = false
      local i, line = it:next()
      repeat
        local width = #line
        if start_col <= width then
          if not reversed then
            start_row = s[1] + i - 1
            reversed = true
            it:rev()
          else
            end_row = s[1] + i - 1
            break
          end
        end
        i, line = it:next()
      until not i
    end
    return { start_row, s[2] }, { end_row, e[2] }, modified
  end

  local function _adjust_width(opts, s, e)
    local _width = { s[2], s[2] }
    if opts.is_replace then
      _width = { s[2], e[2] }
    elseif opts.after then
      _width = { e[2], e[2] }
    end
    return _width
  end

  local hatpos = vim.api.nvim_replace_termcodes('<C-v>^o^', true, false, true)
  local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
  local cursor_back = vim.api.nvim_replace_termcodes('<Left><Left>', true, false, true)
  local insert = [[s/\%V//g]] .. cursor_back
  local replace = [[s/\%V.*\%V.//g]] .. cursor_back
  local add = [[s/$//g]] .. cursor_back

  ---@param key string
  ---@param opts? LiveReplaceOpts
  return function(key, opts)
    opts = opts or {}
    if opts.send_key then
      opts.overwrite = opts.overwrite or opts.send_key
      vim.notify_once(
        [=[tartar.nvim(live_rectangle_replace): The "send_key" option has been renamed to "overwrite".]=],
        vim.log.levels.WARN,
        {}
      )
    end
    local bufnr = vim.api.nvim_win_get_buf(0)
    local mode = vim.api.nvim_get_mode().mode
    if not helper.is_blockwise(mode) then
      if opts.linewise_blockify and mode:find('[vV]') then
        if opts.after then
          vim.api.nvim_feedkeys(':' .. add, 'n', false)
        else
          if opts.zero then
            vim.api.nvim_feedkeys('0', 'n', false)
          else
            vim.api.nvim_feedkeys(hatpos, 'n', false)
          end
          vim.schedule(function()
            vim.api.nvim_feedkeys(':' .. insert, 'n', false)
            local s, e, _ = helper.get_selected_range(1, 0, true)
            _cursor_marker(bufnr, s[1] - 1, s[2], e[1] - 1, s[2] + 1, opts.higroup)
          end)
        end
      else
        vim.api.nvim_feedkeys(key, 'n', false)
      end
      return
    end
    opts.fill = opts.fill or opts.overwrite
    local base_col = opts.after and 1 or 0
    local s, e, _ = helper.get_selected_range(1, base_col, true)
    local leave = opts.overwrite and key .. esc or esc
    vim.api.nvim_feedkeys(leave, 'n', false)
    vim.opt.eventignore:append('CmdlineChanged')
    local modified = false
    local fill_in = opts.fill and ((opts.after or opts.is_replace) and 'end' or 'start') or nil
    s, e, modified = _normalize_range(bufnr, s, e, fill_in)
    _set_autocmd(s, e, opts.after, modified)
    local width = _adjust_width(opts, s, e)
    vim.schedule(function()
      vim.api.nvim_buf_set_mark(bufnr, '<', s[1], width[1], {})
      vim.api.nvim_buf_set_mark(bufnr, '>', e[1], width[2], {})
      local input = ':*' .. (opts.is_replace and replace or insert)
      vim.api.nvim_feedkeys(input, 'n', false)
      vim.opt.eventignore:remove('CmdlineChanged')
      if not opts.overwrite then
        _cursor_marker(bufnr, s[1] - 1, width[1], e[1] - 1, width[2] + 1, opts.higroup)
      end
    end)
  end
end
