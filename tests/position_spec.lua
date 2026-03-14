local assert = require('luassert')
local pos = require('tartar.position')

describe('position', function()
  it('to_range4 should convert row and col to a range', function()
    local range = pos.to_range4(3, 5)
    assert.are.same({ 3, 5, 3, 6 }, range)
  end)
end)
