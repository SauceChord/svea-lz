---@class BitWriter
---@field bytes table
---@field writeBits function 
---@field writeBool function
---@field tostring function
---@field new function
local BitWriter = { }

require "asserts.Extra"

function BitWriter:writeBits(value, width)
    assert_is_int(value, "value")
    assert_is_int(width, "width")
    assert(width >= 0 and width <= 64, "Valid range for width is 0-64 inclusive, got " .. tostring(width))
    while width > 0 do
        local byteIndex = self.bits // 8 + 1
        local bitIndex = self.bits % 8
        self.bytes[byteIndex] = (self.bytes[byteIndex] or 0) | value << bitIndex & 255
        local writtenBitCount = math.min(8 - bitIndex, width)
        self.bits = self.bits + writtenBitCount
        width = width - writtenBitCount
        value = value >> writtenBitCount
    end
end

function BitWriter:writeBool(bit)
    bit = bit == 0 and 0 or bit and 1 or 0
    local byteIndex = self.bits // 8 + 1
    local bitIndex = self.bits % 8
    self.bytes[byteIndex] = (self.bytes[byteIndex] or 0) | bit << bitIndex & 255
    self.bits = self.bits + 1
end

function BitWriter:tostring()
    return string.pack("J", self.bits) .. string.char(table.unpack(self.bytes))
end

local mt = { __index = BitWriter, __tostring = BitWriter.tostring }

function BitWriter.new()
    local o = {
        bits = 0,
        bytes = {},
    }
    setmetatable(o, mt)
    return o
end

return BitWriter