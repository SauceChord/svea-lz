---@class BitReader
---@field new function
---@field readBits function
---@field readBit function
---@field tostring function
---@field bits integer The number of bits in this stream. Do not modify unless you know what you are doing.
---@field location integer The current location counted in bits from beginning. Do not modify unless you know what you are doing.
---@field bytes table The underlying byte array from which data is read. Do not modify unless you know what you are doing.
local BitReader = { }

local function assert_is_int(arg, argName)
    assert(type(arg) == "number" and math.floor(arg) == arg, argName .. " must be an integer")
end

function BitReader:tostring()
    return string.format("{ bits = %d, location = %d }", self.bits, self.location)
end

local mt = { __index = BitReader, __tostring = BitReader.tostring }

function BitReader.new(buffer, i)
    i = i or 1
    assert(i > 0 and #buffer >= i + 7, "buffer too small to read bit length header")
    local o = {
        bits = string.unpack("J", buffer, i),
        location = 0,
        bytes = { }
    }
    local firstContentIndex = i + 8
    local lastContentIndex = firstContentIndex + math.ceil(o.bits / 8)
    local contentSize = lastContentIndex - firstContentIndex
    assert(#buffer >= i + 7 + contentSize, "buffer too small to read " .. contentSize .. " bytes")
    if contentSize > 0 then
        o.bytes = table.pack(string.byte(buffer, firstContentIndex, lastContentIndex))
    end
    setmetatable(o, mt)
    return o
end

function BitReader:readBits(width)
    assert_is_int(width, "width")
    assert(width > 0 and self.location + width <= self.bits and width <= 64, "Out of bounds error, can't read " .. width .. " bits")
    local result = 0
    local bitOffset = 0
    while width > 0 do
        local byteIndex = self.location // 8 + 1
        local bitIndex = self.location % 8
        local readBitCount = math.min(8 - bitIndex, width)
        result = result | (self.bytes[byteIndex] >> bitIndex & ~(255 << readBitCount)) << bitOffset
        self.location = self.location + readBitCount
        width = width - readBitCount
        bitOffset = bitOffset + readBitCount
    end
    return result
end

function BitReader:readBool()
    assert(self.location < self.bits, "Out of bounds error, can't read 1 bit")
    local byteIndex = self.location // 8 + 1
    local bitIndex = self.location % 8
    self.location = self.location + 1
    return (self.bytes[byteIndex] >> bitIndex & 1) == 1
end

return BitReader