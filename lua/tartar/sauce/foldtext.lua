local helper = require('tartar.helper')

---@param UNIQUE_NAME string
---@param augroup integer
---@param separator? string
return function(UNIQUE_NAME, augroup, separator)
  local DEFAULT_SEPARATOR = '»'
  local fold_sep = separator or DEFAULT_SEPARATOR
  local foldmarker = helper.split_option_value('foldmarker')

  -- This function is based on https://github.com/tamton-aquib/essentials.nvim
  -- is publicly available under the terms of the MIT license.
  function Tartar_fold()
    local cms = vim.api.nvim_get_option_value('commentstring', {})
    cms = cms:gsub('(%S+)%s*%%s.*', '%1')
    local open, close = vim.v.foldstart, vim.v.foldend
    local line_count = ('%s lines'):format(close - open)
    local startline = vim.api.nvim_buf_get_lines(0, open - 1, open, false)[1]
    startline = startline:gsub(string.format('%s%%s*%s%%d*', cms, foldmarker[1]), '')
    local endline = vim.api.nvim_buf_get_lines(0, close - 1, close, false)[1]
    local end_string = vim.api.nvim_get_option_value('foldexpr', {}):find('vim.lsp.foldexpr', 1, true) and '' or endline
    endline = endline:find(foldmarker[2], 1, true) and endline:sub(0, endline:find(cms, 1, true) - 1)
      or end_string:gsub('%s*', '')
    local linewise = ('%s %s %s... %s'):format(startline, fold_sep, line_count, endline)
    local blank = (' '):rep(vim.go.columns - #linewise)
    return linewise .. blank
  end

  vim.api.nvim_set_option_value('foldtext', 'v:lua.Tartar_fold()', { win = 0 })
  vim.api.nvim_create_autocmd('OptionSet', {
    desc = ('[%s] update foldmarker'):format(UNIQUE_NAME),
    group = augroup,
    pattern = { 'foldmarker' },
    callback = function()
      foldmarker = helper.split_option_value('foldmarker')
    end,
  })
end
