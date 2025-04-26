---@param keys string|string[]
local _iter_maps = function(keys, callback)
  local t = type(keys)
  if t == 'string' then
    callback(keys)
  elseif t == 'table' then
    vim.iter(keys):each(function(key)
      callback(key)
    end)
  end
end

-- A operator that issues a specific key standby
---@param mode string A list of modes
---@param name string A plugkey name
---@param prefix_key string A trigger key spec
---@param is_repeatable? boolean Whether to repeat the key sequence
---@return fun(keys: string|string[], addkey?: string):nil
return function(mode, name, prefix_key, is_repeatable)
  local plug = ('<Plug>(%s)'):format(name)
  if is_repeatable then
    return function(keys, replacekey)
      if replacekey and keys == prefix_key then
        vim.keymap.set(mode, prefix_key, prefix_key .. plug, { remap = false })
        vim.keymap.set(mode, plug .. keys, replacekey .. plug, { remap = false })
      else
        _iter_maps(keys, function(nextkey)
          if type(nextkey) == 'table' then
            vim.validate('nextkey', nextkey, function()
              return type(nextkey[1]) == 'string' and type(nextkey[2]) == 'string'
            end)
            vim.keymap.set(mode, prefix_key .. nextkey[1], nextkey[2] .. plug)
            vim.keymap.set(mode, plug .. nextkey[1], nextkey[2] .. plug)
          else
            local repeatkey = prefix_key .. nextkey
            vim.keymap.set(mode, repeatkey, repeatkey .. plug)
            vim.keymap.set(mode, plug .. nextkey, repeatkey .. plug)
          end
        end)
      end
    end
  else
    vim.keymap.set(mode, prefix_key, plug)
    return function(keys)
      _iter_maps(keys, function(nextkey)
        if type(nextkey) == 'table' then
          vim.validate('nextkey', nextkey, function()
            return type(nextkey[1]) == 'string' and type(nextkey[2]) == 'function'
          end)
          vim.keymap.set(mode, plug .. nextkey[1], nextkey[2], { expr = true })
        else
          vim.keymap.set(mode, plug .. nextkey, prefix_key .. nextkey)
        end
      end)
    end
  end
end

