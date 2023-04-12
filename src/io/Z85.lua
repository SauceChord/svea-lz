local Z85 = {}

local S85String = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-:+=^!/*?&<>()[]{}@%$#"

---@param base85 integer
---@return integer
local function Base85ToS85Byte(base85)
    return S85String:byte(base85 + 1)
end

---@param s string
---@param i integer
---@return string
function Z85.encodeChunk(s, i)
    local j = string.unpack(">I4", s, i)
    local a, b, c, d, e = (j // 85 ^ 4) % 85, (j // 85 ^ 3) % 85, (j // 85 ^ 2) % 85, (j // 85) % 85, j % 85
    return string.char(Base85ToS85Byte(a), Base85ToS85Byte(b), Base85ToS85Byte(c), Base85ToS85Byte(d), Base85ToS85Byte(e))
end

---@param s string
---@return string
function Z85.encode(s)
    assert(type(s) == "string", "Can only encode strings but was passed: " .. type(s))
    local chunks, unsafeChunk = {}, (#s // 4) * 4
    for i = 1, unsafeChunk, 4 do
        chunks[#chunks + 1] = Z85.encodeChunk(s, i)
    end
    local charsMissingForChunk = #s - unsafeChunk
    if charsMissingForChunk > 0 then
        s = s .. string.rep(string.char(0), 4 - charsMissingForChunk)
        chunks[#chunks + 1] = Z85.encodeChunk(s, unsafeChunk + 1):sub(1, charsMissingForChunk + 1)
    end
    return table.concat(chunks)
end

return Z85
