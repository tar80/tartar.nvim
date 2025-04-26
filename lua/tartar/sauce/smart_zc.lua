---@param UNIQUE_NAME string
---@param mod? string 'lsp'|'treesitter'|'both'
---@param initial_time? integer language server initialization wait time
return function(UNIQUE_NAME, mod, initial_time)
  vim.validate('mod', mod, function()
    if mod == 'lsp' or mod == 'treesitter' or mod == 'both' then
      return true
    end
    return false
  end, true)
  vim.validate('initial_time', initial_time, 'number', true)
  local lsp = require('tartar.lsp')
  mod = mod or 'both'
  initial_time = tonumber(initial_time) or 250
  local function _set_foldexpr(submodule)
    vim.opt_local.foldlevel = 99
    vim.opt_local.foldexpr = ('v:lua.vim.%s.foldexpr()'):format(submodule)
    vim.opt_local.foldmethod = 'expr'
  end
  vim.keymap.set('n', 'zc', function()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local wait = 0
    if vim.wo.foldlevel ~= 'expr' and vim.fn.foldlevel(row) == 0 then
      if mod ~= 'treesitter' then
        local clients = lsp.buf_get_clients()
        if clients.count > 0 then
          vim.iter(clients.names):find(function(name)
            if clients[name]:supports_method('textDocument/foldingRange') then
              _set_foldexpr('lsp')
              wait = initial_time
              return
            end
          end)
        end
      elseif mod ~= 'lsp' and vim.treesitter.get_node() then
        _set_foldexpr('treesitter')
      end
    end
    vim.defer_fn(function()
      vim.api.nvim_feedkeys('zc', 'n', false)
    end, wait)
  end, { noremap = true, desc = ('[%s] smart zc'):format(UNIQUE_NAME) })
end
