local M = {}

---@alias BgMode "light"|"dark"

---@alias RGB {[1]:Red,[2]:Green,[3]:Blue}
---@alias Red integer 0-255
---@alias Green integer 0-255
---@alias Blue integer 0-255

---@param hex  string
---@return RGB
function M.to_rgb(hex)
  hex = string.lower(hex)
  return { tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16) }
end

---Adjusts the brightness of an HSL color.
---@param luminance number[] HSL color table
---@param adjustment number Brightness adjustment value
---@return number
function M.adjust_luminance(luminance, adjustment)
  return math.max(0, math.min(100, luminance + adjustment))
end

---Adjusts the contrast of a given hex color.
---@param hex string The hex color to adjust (e.g., "#RRGGBB")
---@param scale number The scale or rgb values
---@param contrast number The contrast adjustment factor
---@return string: The adjusted hex color.
function M.adjust_contrast(hex, scale, contrast)
  local rgb = M.to_rgb(hex)
  scale = scale or 0.9
  contrast = contrast or 1.5

  local contrast_channel = function(i)
    local ret = rgb[i] / 255 - scale
    ret = ret * contrast
    ret = (ret + scale) * 255
    return math.max(0, math.min(255, ret))
  end

  return string.format('#%02x%02x%02x', contrast_channel(1), contrast_channel(2), contrast_channel(3))
end

---@param mode string 'light' or 'dark'
---@return function fun(target:RGB,base:RGB):R,G,B
function M.combine(mode)
  local function _combine_light(target, base)
    return math.max(0, target[1] - (255 - base[1])),
      math.max(0, target[2] - (255 - base[2])),
      math.max(0, target[3] - (255 - base[3]))
  end
  local function _combine_dark(target, base)
    return math.min(255, target[1] + base[1]), math.min(255, target[2] + base[2]), math.min(255, target[3] + base[3])
  end

  return mode == 'light' and _combine_light or _combine_dark
end

---@param rgb RGB
---@return BgMode
function M.estimate_bg_mode(rgb)
  ---@see https://github.com/catppuccin/nvim/blob/fa42eb5e26819ef58884257d5ae95dd0552b9a66/lua/catppuccin/utils/colors.lua#L75
  local luminance = (0.299 * rgb[1] + 0.587 * rgb[2] + 0.114 * rgb[3]) / 255
  return luminance > 0.5 and 'light' or 'dark'
end

---@param int integer
---@return string hex
local function num_to_hex(int)
  local hex = string.format('%X', int)
  local len = #hex
  if len <= 6 then
    hex = string.rep('0', 6 - len) .. hex
  end
  return '#' .. hex
end

---@param value string|number
---@return boolean ok, string hex
local function value_to_hex(value)
  local value_type = type(value)
  if value_type == 'number' then
    value = num_to_hex(value)
  end
  if value:len() ~= 7 or not value:lower():match('^#[1234567890abcdef]*$') then
    return false, ''
  end

  return true, value
end

---Simple RGB color fader
---@param rgb string|integer
---@param attenuation number
---@return boolean ok, string RGB
function M.fade_color(rgb, attenuation)
  local ok, hex = value_to_hex(rgb)
  if not ok then
    return false, 'rgb must be color-code.'
  end
  local r = tonumber(hex:sub(1, 2), 16)
  local g = tonumber(hex:sub(3, 4), 16)
  local b = tonumber(hex:sub(5, 6), 16)

  if attenuation < 0 or attenuation > 100 then
    return false, 'Invalid attenuation value'
  end

  attenuation = (attenuation / 100) * 255

  if vim.go.background == 'light' then
    r = math.min(255, r + attenuation * (1 - r / 255))
    g = math.min(255, g + attenuation * (1 - g / 255))
    b = math.min(255, b + attenuation * (1 - b / 255))
  else
    r = math.max(0, r - attenuation)
    g = math.max(0, g - attenuation)
    b = math.max(0, b - attenuation)
  end

  return true, ('#%02X%02X%02X'):format(r, g, b)
end

return M
