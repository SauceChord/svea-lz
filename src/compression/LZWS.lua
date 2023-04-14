local BitWriter = require "io.BitWriter"
local BitReader = require "io.BitReader"

---@class LZWS
---@field compress function
local LZWS = {}

---Utility for sanity checking input
---@param param any object to be tested for integer
---@param paramName string parameter name
local function assert_is_int(param, paramName)
    assert(type(param) == "number" and math.floor(param) == param, paramName .. " must be an integer")
end

local function makeStringToCode()
    local t = {}
    for i = 0, 255 do
        t[string.char(i)] = i
    end
    return t, 256
end

local function makeCodeToString()
    local t = {}

    for i = 0, 255 do
        t[i] = string.char(i)
    end

    function t:append(lastWord, word)
        self[self.count] = lastWord .. word
        self.count = self.count + 1
    end

    t.count = 256
    return t
end


---Writes header and codes for version 0 of LZWS content.
---@param writer BitWriter Utility to write bits with.
---@param codes table Array of integer codes where no integer should be greater than dictSize
---@param dictSize integer Size of the dictionary this set was compressed with
local function encodeVersion0ToWriter(writer, codes, dictSize)
    local bitsPerCode = math.ceil(math.log(dictSize, 2))
    assert(bitsPerCode <= 24, "Abnormally large code dictionary, aborting encoding")
    writer:writeBits(bitsPerCode, 5)
    writer:writeBits(#codes, 32)
    for i = 1, #codes do
        writer:writeBits(codes[i], bitsPerCode)
    end
end

---Encodes a string of compressed codes (characters range from 0 to 255)
---@param codes table An array of codes generated by LZWS.encode
---@param dictSize integer Dictionary size
---@return string string Compressed codes
local function encodeToString(codes, dictSize)
    local writer = BitWriter.new()
    writer:writeBits(0, 3) -- Version 0
    encodeVersion0ToWriter(writer, codes, dictSize)
    return tostring(writer)
end

---Compresses any string into a smaller string
---The return value not safe to send over emitters in Dual Universe since they cannot handle \0 chars.
---Encode the resulting string with Z85 for example before sending (adds 20% to your compressed string size).
---@param s string The string to be compressed.
---@param maxBitWidth integer|nil Optional max bit width of codes. Valid range is 9-24. Default is 12 which makes for 4096 entries in the dictionary.
---@return string string A compressed string which characters may occupy all ranges 0-255.
function LZWS.compress(s, maxBitWidth)
    assert(type(s) == "string", "s must be a string")
    maxBitWidth = maxBitWidth or 12
    assert_is_int(maxBitWidth, "maxBitWidth")
    assert(maxBitWidth >= 9 and maxBitWidth <= 24, "bitCount has to be in range 9 to 24")

    local stringToCode, count = makeStringToCode()
    local output = {}

    if #s == 0 then
        return encodeToString(output, count)
    end

    local maxCodes = 2 ^ maxBitWidth
    local currentWord = ""
    local lastKnownWord = nil
    local nextCharacter = nil

    for i = 1, #s do
        nextCharacter = s:sub(i,i)
        local newWord = currentWord .. nextCharacter
        if (stringToCode[newWord] and #output < maxCodes)  then
            lastKnownWord = newWord
            currentWord = newWord
        else
            table.insert(output, stringToCode[currentWord])
            stringToCode[newWord] = count
            count = count + 1
            currentWord = nextCharacter
            lastKnownWord = nil
        end
    end

    if lastKnownWord then
        local code = stringToCode[lastKnownWord]
        table.insert(output, code)
    else
        local code = stringToCode[nextCharacter]
        table.insert(output, code)
    end

    return encodeToString(output, count)
end

---Decodes Version 0 of LZWS strings
---@param reader BitReader a utility to read data with
---@return string result a decoded string
local function decodeVersion0(reader)
    local codeWidth = reader:readBits(5)
    local codeWords = reader:readBits(32)

    -- Quit early if no content
    if codeWords == 0 then return "" end

    local dictionary = makeCodeToString()
    -- Read first code outside the loop. Because...
    -- I haven't found a way to generalize for cases like { 97, 256 } ('aaa')
    -- and the 'XYZYZYXXYZXYZYYYYYYXYZY' test sample.
    local code = reader:readBits(codeWidth)
    local word = dictionary[code]
    local lastWord = word
    local result = {}
    table.insert(result, word)

    for i = 2, codeWords do
        code = reader:readBits(codeWidth)
        word = dictionary[code]
        if word == nil then
            word = lastWord .. lastWord:sub(1, 1)
        end
        dictionary:append(lastWord, word:sub(1, 1))
        table.insert(result, word)
        lastWord = word
    end

    return table.concat(result)
end

---Decompresses a LZWS compressed string
---@param s string A LZWS compressed string
---@return string result A decompressed string
function LZWS.decompress(s)
    local reader = BitReader.new(s)
    local version = reader:readBits(3)
    assert(version == 0, "LZWS version must be 0 but got " .. version)
    return decodeVersion0(reader)
end

return LZWS
