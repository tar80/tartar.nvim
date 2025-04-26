local tartar = {}

--[[
  Copyright 2024 folke

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
]]
---@source https://github.com/folke/flash.nvim/blob/main/lua/flash/require.lua
local function _require(module)
  local mod = nil

  local function load()
    if not mod then
      mod = require(module)
      package.loaded[module] = mod
    end
    return mod
  end

  return type(package.loaded[module]) == "table" and package.loaded[module]
    or setmetatable({}, {
      __index = function(_, key)
        return load()[key]
      end,
      __newindex = function(_, key, value)
        load()[key] = value
      end,
      __call = function(_, ...)
        return load()(...)
      end,
    })
end

function tartar.setup()
  local beacon = _require('tartar.beacon')
  local compat = _require('tartar.compat')
  local helper = _require('tartar.helper')
  local highlight = _require('tartar.highlight')
  local lsp = _require('tartar.lsp')
  local render = _require('tartar.render')
  local position = _require('tartar.position')
  local timer = _require('tartar.timer')
  local treesitter = _require('tartar.treesitter')
  local util = _require('tartar.util')
  local icon_symbol = _require('tartar.icon.symbol')
  local icon_ui = _require('tartar.icon.ui')
  package.loaded['fret.beacon'] = beacon
  package.loaded['fret.compat'] = compat
  package.loaded['fret.helper'] = helper
  package.loaded['fret.timer'] = timer
  package.loaded['fret.util'] = util
  package.loaded['rereope.beacon'] = beacon
  package.loaded['rereope.compat'] = compat
  package.loaded['rereope.helper'] = helper
  package.loaded['rereope.highlight'] = highlight
  package.loaded['rereope.render'] = render
  package.loaded['rereope.util'] = util
  package.loaded['staba.compat'] = compat
  package.loaded['staba.helper'] = helper
  package.loaded['staba.lsp'] = lsp
  package.loaded['staba.util'] = util
  package.loaded['staba.icon.symbol'] = icon_symbol
  package.loaded['staba.icon.ui'] = icon_ui
  package.loaded['matchwith.compat'] = compat
  package.loaded['matchwith.helper'] = helper
  package.loaded['matchwith.position'] = position
  package.loaded['matchwith.render'] = render
  package.loaded['matchwith.timer'] = timer
  package.loaded['matchwith.treesitter'] = treesitter
  package.loaded['matchwith.util'] = util
end

return tartar
