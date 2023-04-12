local BitReader = { }

local function assert_is_int(arg, argName)
    assert(type(arg) == "number" and math.floor(arg) == arg, argName .. " must be an integer")
end

--[[
function BitReader:writeBits(value, width)
    assert_is_int(value, "value")
    assert_is_int(width, "width")
    assert(width >= 0 and width <= 64, "Valid range for width is 0-64 inclusive, got " .. tostring(width))
    while width > 0 do
        local byteIndex = self.bits // 8 + 1
        local bitIndex = self.bits % 8
        self.bytes[byteIndex] = (self.bytes[byteIndex] or 0) | value << bitIndex & 255
        -- Update bit details
        local writtenBitCount = math.min(8 - bitIndex, width)
        self.bits = self.bits + writtenBitCount
        width = width - writtenBitCount
        value = value >> writtenBitCount
    end
end
--]]

function BitReader:tostring()
    assert(false, "todo")
end

local mt = { __index = BitReader, __tostring = BitReader.tostring }

function BitReader.new(buffer, i)
    i = i or 0
    assert(#buffer >= (i-1) + 8, "buffer too small to read bit length header")
    local o = {
        bits = string.unpack("J", buffer, i),
        location = 0,
        bytes = { }
    }
    local firstContentIndex = i + 8 + 1
    local lastContentIndex = firstContentIndex + math.ceil(o.bits / 8)
    local contentSize = lastContentIndex - firstContentIndex
    assert(#buffer >= i + 8 + contentSize, "buffer too small to read " .. contentSize .. " bytes")
    if contentSize > 0 then
        o.bytes = table.pack(string.byte(buffer, firstContentIndex, lastContentIndex))
    end
    setmetatable(o, mt)
    return o
end

function BitReader:readBits(width)
    assert_is_int(width, "width")
    assert(width >= 0 and self.location + width <= math.min(64, self.bits), "Out of bounds error, can't read " .. width .. " bits")
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

return BitReader