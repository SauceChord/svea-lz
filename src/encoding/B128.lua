---@class B128 Binary Base128 encoder/decoder
local B128 = {}

---Encodes a string to its binary base 128 string.
---The resulting encoded string contain characters whole byte is 0 to 127.
---@param s string String to encode to base 128.
---@return string encoded Base 128 encoded string.
function B128.encode(s)
    local len = #s
    if len == 0 then return "" end
    local bytes, out, extra, extraLen = table.pack(s:byte(1, #s)), {}, 0, 0
    for i = 1, len do
        local shl = (i - 1) % 7
        local b128 = ((bytes[i] & 127) << shl) | (extra & ~(-1 << shl))
        extra = bytes[i] >> (7 - shl)
        extraLen = extraLen + 1
        table.insert(out, b128 & 127)
        if extraLen == 7 then
            table.insert(out, extra)
            extraLen = 0
            extra = 0
        end
    end
    if extraLen > 0 then
        table.insert(out, extra)
    end
    return string.char(table.unpack(out))
end

---Decodes a binary base 128 string to an original string previously encoded.
---@param s string String to decode from base 128.
---@return string decodedString
function B128.decode(s)
    local len = #s
    if len == 0 then return "" end
    local bytes, out, bits, buf = table.pack(s:byte(1, #s)), {}, 0, 0
    for i = 1, len do
        buf = buf | ((bytes[i] & 127) << bits)
        bits = bits + 7
        if bits >= 8 then
            table.insert(out, buf & 255)
            buf = buf >> 8
            bits = bits - 8
        end
    end
    return string.char(table.unpack(out))
end

return B128
