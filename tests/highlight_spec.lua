local assert = require('luassert')
local hl = require('tartar.highlight')

describe('.to_rgb()', function()
  it('should convert hex to RGB', function()
    local rgb = hl.to_rgb('#FF5733')
    assert.are.same({ 255, 87, 51 }, rgb)
  end)
end)

describe('.adjusted_luminance()', function()
  it('should adjust luminance within bounds when increasing', function()
    local hsl_color = { 100, 50, 50 }
    local adjustment = 50
    local expected_hsl = { 100, 50, 100 }
    local actual_hsl = hl.adjust_luminance(hsl_color, adjustment)
    assert.are.same(expected_hsl, actual_hsl, 'Increasing luminance to max')
  end)

  it('should adjust luminance within bounds when decreasing', function()
    local hsl_color = { 100, 50, 70 }
    local adjustment = -30
    local expected_hsl = { 100, 50, 40 }
    local actual_hsl = hl.adjust_luminance(hsl_color, adjustment)
    assert.are.same(expected_hsl, actual_hsl, 'Decreasing luminance within bounds')
  end)

  it('should clamp luminance at 0 when adjustment goes below min', function()
    local hsl_color = { 100, 50, 20 }
    local adjustment = -30
    local expected_hsl = { 100, 50, 0 }
    local actual_hsl = hl.adjust_luminance(hsl_color, adjustment)
    assert.are.same(expected_hsl, actual_hsl, 'Clamping luminance at 0')
  end)

  it('should return a new table, not modify the original', function()
    local original_hsl = { 100, 50, 60 }
    local original_hsl_copy = vim.deepcopy(original_hsl)
    local adjustment = 10
    hl.adjust_luminance(original_hsl, adjustment)
    assert.are.same(original_hsl_copy, original_hsl, 'Original HSL table should not be modified')
  end)

  it('should adjust contrast. The returned value contains lowercase letters', function()
    assert.are.same('#ffffff', hl.adjust_contrast('#FFFFFF', 0.9, 1.5))
    assert.are.same('#000000', hl.adjust_contrast('#000000', 0.9, 1.5))
    assert.are.same('#4d4d4d', hl.adjust_contrast('#808080', 0.9, 1.5))
  end)
end)

describe('.combine()', function()
  local light_combiner
  local dark_combiner

  before_each(function()
    light_combiner = hl.combine('light', 1)
    dark_combiner = hl.combine('dark', 1)
  end)

  it('light combiner should darken target color', function()
    local r, g, b = light_combiner({ 100, 150, 200 }, { 200, 100, 50 })
    assert.are.same({ 45, 0, 0 }, { r, g, b })
  end)

  it('dark combiner should brighten target color', function()
    local r, g, b = dark_combiner({ 100, 150, 200 }, { 50, 50, 50 })
    assert.are.same({ 150, 200, 250 }, { r, g, b })
  end)

  it('combine with intensity should adjust blending', function()
    local light_combiner_half_intensity = hl.combine('light', 0.5)
    local r, g, b = light_combiner_half_intensity({ 100, 150, 200 }, { 200, 100, 50 })
    assert.are.same({ 72.5, 72.5, 97.5 }, { r, g, b })
  end)
end)

describe('.estimate_bg_mode()', function()
  it('should estimate background mode', function()
    assert.are.same('light', hl.estimate_bg_mode({ 200, 220, 240 }))
    assert.are.same('dark', hl.estimate_bg_mode({ 30, 40, 50 }))
    assert.are.same('light', hl.estimate_bg_mode({ 150, 150, 150 }))
  end)
end)

describe('.fade_color()', function()
  it('should fade color correctly for light background', function()
    vim.go.background = 'light'
    local ok, faded_color = hl.fade_color('#336699', 50)
    assert.is_true(ok)
    assert.are.same('#99B2CC', faded_color)
  end)

  it('should fade color correctly for dark background', function()
    vim.go.background = 'dark'
    local ok, faded_color = hl.fade_color('#336699', 50)
    assert.is_true(ok)
    assert.are.same('#19334C', faded_color)
  end)

  it('should return error for invalid hex code', function()
    local ok, err = hl.fade_color('invalid-hex', 50)
    assert.is_false(ok)
    assert.are.same('rgb must be color-code.', err)
  end)

  it('should return error for invalid attenuation', function()
    local ok, err = hl.fade_color('#FFFFFF', 150)
    assert.is_false(ok)
    assert.are.same('Invalid attenuation value', err)
  end)
end)
