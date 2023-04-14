---@class B128 Binary Base128 encoder/decoder
local B128 = {}

---Encodes the string to its binary base 128 string.
---The resulting encoded string contain characters whole byte is 0 to 127.
---@param s string String to encode to base 128.
---@return string encoded Base 128 encoded string.
function B128.encode(s)
    local sLen = #s
    if sLen == 0 then return "" end
    local b256 = table.pack(s:byte(1, #s))
    local b128Out = {}
    local b128OF = 0
    local b128OFLen = 0
    for i = 1, sLen do
        local shl = (i - 1) % 7
        local b128 = ((b256[i] & 127) << shl) | (b128OF & ~(-1 << shl))
        b128OF = b256[i] >> (7 - shl)
        b128OFLen = b128OFLen + 1
        table.insert(b128Out, b128 & 127)
        if b128OFLen == 7 then
            table.insert(b128Out, b128OF)
            b128OFLen = 0
            b128OF = 0
        end
    end
    if b128OFLen then
        table.insert(b128Out, b128OF)
    end
    return string.char(table.unpack(b128Out))
end

return B128
