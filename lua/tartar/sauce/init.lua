local UNIQUE_NAME = 'tartar.nvim'
local ns = vim.api.nvim_create_namespace(UNIQUE_NAME)
local augroup = vim.api.nvim_create_augroup(UNIQUE_NAME, {})

return {
  abbrev = function()
    return require('tartar.sauce.abbrev')
  end,
  align = function(hlgroup)
    return require('tartar.sauce.align')(ns, hlgroup)
  end,
  foldtext = function(separator)
    require('tartar.sauce.foldtext')(UNIQUE_NAME, augroup, separator)
  end,
  live_replace = function()
    return require('tartar.sauce.live_replace')(UNIQUE_NAME, ns, augroup)
  end,
  plugkey = function(mode, name, prefix_key, is_repeatable)
    return require('tartar.sauce.plugkey')(mode, name, prefix_key, is_repeatable)
  end,
  smart_zc = function(mod, initial_time)
    require('tartar.sauce.smart_zc')(UNIQUE_NAME, mod, initial_time)
  end,
  testmode = function(opts)
    require('tartar.sauce.testmode')(UNIQUE_NAME, opts)
  end,
}
