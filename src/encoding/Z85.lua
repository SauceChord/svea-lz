local Z85 = {}

require "asserts.Extra"

-- Initialize Lookup tables
local _encode = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-:+=^!/*?&<>()[]{}@%$#"
local _decode = { } -- maps an ascii character code to a number in the range of 0-84
for i = 1, #_encode do
    _decode[_encode:byte(i)] = i-1
end

---@param s string
---@param stringIndex integer
---@return string
local function encodeChunk(s, stringIndex)
    local v = string.unpack(">I4", s, stringIndex)
    local a, b, c, d, e = (v // 85 ^ 4) % 85, (v // 85 ^ 3) % 85, (v // 85 ^ 2) % 85, (v // 85) % 85, v % 85
    return string.char(_encode:byte(a+1), _encode:byte(b+1), _encode:byte(c+1), _encode:byte(d+1), _encode:byte(e+1))
end

--- There is an asymmetry with encodeChunk: decoding the last chunk requires a variable amount
--- of characters written to the result. I found no easy way of solving that with string.pack. 
---@param s string
---@param i integer
---@return integer
local function decodeChunkToUInt32(s, i)
    local v = string.unpack(">I5", s, i)
    return _decode[v >> 32] * 85^4 + _decode[v >> 24 & 255] * 85^3 + _decode[v >> 16 & 255] * 85^2 + _decode[v >> 8 & 255] * 85 + _decode[v & 255]
end

---@param s string
---@return string
function Z85.encode(s)
    assert_is_string(s, "s")
    local chunks, unsafeChunk = {}, (#s // 4) * 4
    for i = 1, unsafeChunk, 4 do
        table.insert(chunks, encodeChunk(s, i))
    end
    local charsMissingForChunk = #s - unsafeChunk
    if charsMissingForChunk > 0 then
        s = s:sub(unsafeChunk + 1) .. string.rep("\0", 4 - charsMissingForChunk)
        table.insert(chunks, encodeChunk(s, 1):sub(1, charsMissingForChunk + 1))
    end
    return table.concat(chunks)
end

---@param s string
---@return string
function Z85.decode(s)
    assert_is_string(s, "s")
    local chunks, unsafeChunk = {}, (#s // 5) * 5
    for i = 1, unsafeChunk, 5 do
        table.insert(chunks, string.pack(">I4", decodeChunkToUInt32(s, i)))
    end
    local charsMissingForChunk = #s - unsafeChunk
    if charsMissingForChunk > 0 then
        s = s:sub(unsafeChunk + 1) .. string.rep("#", 5 - charsMissingForChunk)
        local u32 = decodeChunkToUInt32(s, 1)
        local remaining = {}
        for char = 1, charsMissingForChunk - 1 do
            remaining[char] = string.char(u32 >> (32 - char * 8) & 255)
        end
        table.insert(chunks, table.concat(remaining))
    end
    return table.concat(chunks)
end

return Z85
