local say = require "say"
local LZWS = require "compression.LZWS"
local BitReader = require "io.BitReader"
local BitWriter = require "io.BitWriter"

-- LZWS contains a predefined dictionary and FIRST_CODE is where compressed entries start counting from
local FIRST_CODE = 256

describe("when LZWS", function()
    describe("compresses", function()
        describe("with valid inputs it", function()
            it("should generate a header for a zero width string", function()
                local actual = LZWS.compress("")
                local content = BitReader.new(actual)

                assert.are.same(40, content.bits, "content.bits")
                -- Header tests
                assert.are.same(0, content:readBits(3), "version")
                assert.are.same(8, content:readBits(5), "code width")
                assert.are.same(0, content:readBits(32), "code count")
            end)
            it("should output a code for a single character", function()
                local actual = LZWS.compress("a")
                local content = BitReader.new(actual)

                assert.are.same(48, content.bits, "content.bits")
                -- Header tests
                assert.are.same(0, content:readBits(3), "version")
                assert.are.same(8, content:readBits(5), "code width")
                assert.are.same(1, content:readBits(32), "code count")
                -- Content tests
                assert.are.same(string.byte("a"), content:readBits(8), "expects 'a' in contents")
            end)
            it("should output two codes for two repeating characters", function()
                local actual = LZWS.compress("aa")
                local content = BitReader.new(actual)

                assert.are.same(40 + 2 * 9, content.bits, "content.bits")
                -- Header tests
                assert.are.same(0, content:readBits(3), "version")
                assert.are.same(9, content:readBits(5), "code width")
                assert.are.same(2, content:readBits(32), "code count")
                -- Content tests
                assert.are.same(string.byte("a"), content:readBits(9), "'a', index 1")
                assert.are.same(string.byte("a"), content:readBits(9), "'a', index 2")
            end)
            it("should output two codes for three repeating characters", function()
                local actual = LZWS.compress("aaa")
                local content = BitReader.new(actual)

                assert.are.same(40 + 2 * 9, content.bits, "content.bits")
                -- Header tests
                assert.are.same(0, content:readBits(3), "version")
                assert.are.same(9, content:readBits(5), "code width")
                assert.are.same(2, content:readBits(32), "code count")
                -- Content tests
                assert.are.same(string.byte("a"), content:readBits(9), "'a'")
                assert.are.same(FIRST_CODE, content:readBits(9), "compressed code")
            end)
            it("should compress 'TOBEORNOTTOBEORTOBEORNOT'", function()
                local actual = LZWS.compress("TOBEORNOTTOBEORTOBEORNOT")
                local content = BitReader.new(actual)

                assert.are.same(40 + 16 * 9, content.bits, "content.bits")
                -- Header tests
                assert.are.same(0, content:readBits(3), "version")
                assert.are.same(9, content:readBits(5), "code width")
                assert.are.same(16, content:readBits(32), "code count")
                -- Content tests, literal data
                assert.are.same(string.byte("T"), content:readBits(9), "expects 'T' at content index 1")
                assert.are.same(string.byte("O"), content:readBits(9), "expects 'O' at content index 2")
                assert.are.same(string.byte("B"), content:readBits(9), "expects 'B' at content index 3")
                assert.are.same(string.byte("E"), content:readBits(9), "expects 'E' at content index 4")
                assert.are.same(string.byte("O"), content:readBits(9), "expects 'O' at content index 5")
                assert.are.same(string.byte("R"), content:readBits(9), "expects 'R' at content index 6")
                assert.are.same(string.byte("N"), content:readBits(9), "expects 'N' at content index 7")
                assert.are.same(string.byte("O"), content:readBits(9), "expects 'O' at content index 8")
                assert.are.same(string.byte("T"), content:readBits(9), "expects 'T' at content index 9")
                -- Content tests, compressed data
                assert.are.same(FIRST_CODE + 0, content:readBits(9), "expects 'TO'  at content index 10")
                assert.are.same(FIRST_CODE + 2, content:readBits(9), "expects 'BE'  at content index 11")
                assert.are.same(FIRST_CODE + 4, content:readBits(9), "expects 'OR'  at content index 12")
                assert.are.same(FIRST_CODE + 9, content:readBits(9), "expects 'TOB' at content index 13")
                assert.are.same(FIRST_CODE + 3, content:readBits(9), "expects 'EO'  at content index 14")
                assert.are.same(FIRST_CODE + 5, content:readBits(9), "expects 'RN'  at content index 15")
                assert.are.same(FIRST_CODE + 7, content:readBits(9), "expects 'OT'  at content index 16")
            end)
            it("should compress 'XYZYZYXXYZXYZYYYYYYXYZY'", function()
                -- https://tmager.github.io/COMP150-lzw/background-lzw.html
                local actual = LZWS.compress("XYZYZYXXYZXYZYYYYYYXYZY")
                local content = BitReader.new(actual)

                assert.are.same(40 + 13 * 9, content.bits, "content.bits")
                -- Header tests
                assert.are.same(0, content:readBits(3), "version")
                assert.are.same(9, content:readBits(5), "code width")
                assert.are.same(13, content:readBits(32), "code count")
                -- Content tests, literal data
                local CODE_X = string.byte("X")
                local CODE_Y = string.byte("Y")
                local CODE_Z = string.byte("Z")
                assert.are.same(CODE_X, content:readBits(9), "'X' at index 1")
                assert.are.same(CODE_Y, content:readBits(9), "'Y' at index 2")
                assert.are.same(CODE_Z, content:readBits(9), "'Z' at index 3")
                assert.are.same(FIRST_CODE + 1, content:readBits(9), "'YZ' at index 4")
                assert.are.same(CODE_Y, content:readBits(9), "'Y' at index 5")
                assert.are.same(CODE_X, content:readBits(9), "'X' at index 6")
                assert.are.same(FIRST_CODE + 0, content:readBits(9), "'XY' at index 7")
                assert.are.same(CODE_Z, content:readBits(9), "'Z' at index 8")
                assert.are.same(FIRST_CODE + 6, content:readBits(9), "'XYZ' at index 9")
                assert.are.same(CODE_Y, content:readBits(9), "'Y' at index 10")
                assert.are.same(FIRST_CODE + 9, content:readBits(9), "'YY' at index 11")
                assert.are.same(FIRST_CODE + 10, content:readBits(9), "'YYY' at index 12")
                assert.are.same(FIRST_CODE + 8, content:readBits(9), "'XYZY' at index 13")
            end)
            it("should compress 'XYZ'", function()
                local actual = LZWS.compress("XYZ")
                local content = BitReader.new(actual)

                assert.are.same(40 + 3 * 9, content.bits, "content.bits")
                -- Header tests
                assert.are.same(0, content:readBits(3), "version")
                assert.are.same(9, content:readBits(5), "code width")
                assert.are.same(3, content:readBits(32), "code count")
                -- Content tests, literal data
                local CODE_X = string.byte("X")
                local CODE_Y = string.byte("Y")
                local CODE_Z = string.byte("Z")
                assert.are.same(CODE_X, content:readBits(9), "'X' at index 1")
                assert.are.same(CODE_Y, content:readBits(9), "'Y' at index 2")
                assert.are.same(CODE_Z, content:readBits(9), "'Z' at index 3")
            end)
            it("should compress 'XYZYZYXXYZXYZYYYYYYXYZYXYZYZY'", function()
                local actual = LZWS.compress("XYZYZYXXYZXYZYYYYYYXYZYXYZYZY")
                local content = BitReader.new(actual)

                assert.are.same(40 + 15 * 9, content.bits, "content.bits")
                -- Header tests
                assert.are.same(0, content:readBits(3), "version")
                assert.are.same(9, content:readBits(5), "code width")
                assert.are.same(15, content:readBits(32), "code count")
                -- Content tests, literal data
                local CODE_X = string.byte("X")
                local CODE_Y = string.byte("Y")
                local CODE_Z = string.byte("Z")
                assert.are.same(CODE_X, content:readBits(9), "'X' at index 1")
                assert.are.same(CODE_Y, content:readBits(9), "'Y' at index 2")
                assert.are.same(CODE_Z, content:readBits(9), "'Z' at index 3")
                assert.are.same(FIRST_CODE + 1, content:readBits(9), "'YZ' at index 4")
                assert.are.same(CODE_Y, content:readBits(9), "'Y' at index 5")
                assert.are.same(CODE_X, content:readBits(9), "'X' at index 6")
                assert.are.same(FIRST_CODE + 0, content:readBits(9), "'XY' at index 7")
                assert.are.same(CODE_Z, content:readBits(9), "'Z' at index 8")
                assert.are.same(FIRST_CODE + 6, content:readBits(9), "'XYZ' at index 9")
                assert.are.same(CODE_Y, content:readBits(9), "'Y' at index 10")
                assert.are.same(FIRST_CODE + 9, content:readBits(9), "'YY' at index 11")
                assert.are.same(FIRST_CODE + 10, content:readBits(9), "'YYY' at index 12")
                assert.are.same(FIRST_CODE + 8, content:readBits(9), "'XYZY' at index 13")
                -- remaining part is "XYZYZY"
                assert.are.same(FIRST_CODE + 8, content:readBits(9), "'XYZY' at index 14")
                -- remaining part is "ZY"
                assert.are.same(FIRST_CODE + 2, content:readBits(9), "'ZY' at index 15")
            end)
            it("should compress 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'", function()
                local actual = LZWS.compress("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
                local content = BitReader.new(actual)

                assert.are.same(40 + 9 * 9, content.bits, "content.bits")
                -- Header tests
                assert.are.same(0, content:readBits(3), "version")
                assert.are.same(9, content:readBits(5), "code width")
                assert.are.same(9, content:readBits(32), "code count")
                -- Content tests, literal data
                local CODE_X = string.byte("X")
                assert.are.same(CODE_X, content:readBits(9), "'X' at index 1")
                assert.are.same(FIRST_CODE + 0, content:readBits(9), "'XX' at index 2")
                assert.are.same(FIRST_CODE + 1, content:readBits(9), "'XXX' at index 3")
                assert.are.same(FIRST_CODE + 2, content:readBits(9), "'XXXX' at index 4")
                assert.are.same(FIRST_CODE + 3, content:readBits(9), "'XXXXX' at index 5")
                assert.are.same(FIRST_CODE + 4, content:readBits(9), "'XXXXXX' at index 6")
                assert.are.same(FIRST_CODE + 5, content:readBits(9), "'XXXXXXX' at index 7")
                assert.are.same(FIRST_CODE + 6, content:readBits(9), "'XXXXXXXX' at index 8")
                -- input: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                -- read:  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  - one X missing
                assert.are.same(CODE_X, content:readBits(9), "'X' at index 9")
            end)
            it("should compress 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'", function()
                local actual = LZWS.compress("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
                local content = BitReader.new(actual)

                assert.are.same(40 + 9 * 9, content.bits, "content.bits")
                -- Header tests
                assert.are.same(0, content:readBits(3), "version")
                assert.are.same(9, content:readBits(5), "code width")
                assert.are.same(9, content:readBits(32), "code count")
                -- Content tests, literal data
                local CODE_X = string.byte("X")
                assert.are.same(CODE_X, content:readBits(9), "'X' at index 1")
                assert.are.same(FIRST_CODE + 0, content:readBits(9), "'XX' at index 2")
                assert.are.same(FIRST_CODE + 1, content:readBits(9), "'XXX' at index 3")
                assert.are.same(FIRST_CODE + 2, content:readBits(9), "'XXXX' at index 4")
                assert.are.same(FIRST_CODE + 3, content:readBits(9), "'XXXXX' at index 5")
                assert.are.same(FIRST_CODE + 4, content:readBits(9), "'XXXXXX' at index 6")
                assert.are.same(FIRST_CODE + 5, content:readBits(9), "'XXXXXXX' at index 7")
                assert.are.same(FIRST_CODE + 6, content:readBits(9), "'XXXXXXXX' at index 8")
                -- input: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
                -- read:  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  - XX missing
                assert.are.same(FIRST_CODE + 0, content:readBits(9), "'XX' at index 9")
            end)
        end)
        describe("with invalid inputs it", function()
            it("should reject bitWidth less than 9", function()
                assert.has.error(function() LZWS.compress("", 8) end, "maxBitWidth (8) must be in range 9 to 24 inclusive")
            end)
            it("should reject bitWidth greater than 24", function()
                assert.has.error(function() LZWS.compress("", 25) end, "maxBitWidth (25) must be in range 9 to 24 inclusive")
            end)
            it("should reject nil string input", function()
                assert.has.error(function() LZWS.compress(nil) end, "s (nil) must be a string")
            end)
            it("should reject decimal bitWidth input", function()
                assert.has.error(function() LZWS.compress("", 10.5) end, "maxBitWidth (number) must be an integer")
            end)
        end)
    end)
    describe("decompresses", function()
        describe("with valid inputs it", function()
            it("should generate ''", function()
                local content = BitWriter.new()
                content:writeBits(0, 3)  -- Version
                content:writeBits(8, 5)  -- Code width
                content:writeBits(0, 32) -- Code count

                local actual = LZWS.decompress(tostring(content))

                assert.are.same("", actual, "decompressed string")
            end)
            it("should generate 'a'", function()
                local content = BitWriter.new()
                content:writeBits(0, 3)  -- Version
                content:writeBits(8, 5)  -- Code width
                content:writeBits(1, 32) -- Code count
                content:writeBits(string.byte("a"), 8)

                local actual = LZWS.decompress(tostring(content))

                assert.are.same("a", actual, "decompressed string")
            end)
            it("should generate 'aa'", function()
                local content = BitWriter.new()
                content:writeBits(0, 3)  -- Version
                content:writeBits(8, 5)  -- Code width
                content:writeBits(2, 32) -- Code count
                content:writeBits(string.byte("a"), 8)
                content:writeBits(string.byte("a"), 8)

                local actual = LZWS.decompress(tostring(content))

                assert.are.same("aa", actual, "decompressed string")
            end)
            it("should generate 'aaa'", function()
                local content = BitWriter.new()
                content:writeBits(0, 3)  -- Version
                content:writeBits(9, 5)  -- Code width
                content:writeBits(2, 32) -- Code count
                content:writeBits(string.byte("a"), 9)
                content:writeBits(FIRST_CODE, 9)

                local actual = LZWS.decompress(tostring(content))

                assert.are.same("aaa", actual, "decompressed string")
            end)
            it("should generate 'XYZYZYXXYZXYZYYYYYYXYZY'", function()
                -- https://tmager.github.io/COMP150-lzw/background-lzw.html
                local content = BitWriter.new()
                local CODE_X = string.byte("X")
                local CODE_Y = string.byte("Y")
                local CODE_Z = string.byte("Z")
                -- Header
                content:writeBits(0, 3)   -- Version
                content:writeBits(9, 5)   -- Code width
                content:writeBits(13, 32) -- Code count
                -- Codes
                content:writeBits(CODE_X, 9)
                content:writeBits(CODE_Y, 9)
                content:writeBits(CODE_Z, 9)
                content:writeBits(FIRST_CODE + 1, 9)
                content:writeBits(CODE_Y, 9)
                content:writeBits(CODE_X, 9)
                content:writeBits(FIRST_CODE + 0, 9)
                content:writeBits(CODE_Z, 9)
                content:writeBits(FIRST_CODE + 6, 9)
                content:writeBits(CODE_Y, 9)
                content:writeBits(FIRST_CODE + 9, 9)
                content:writeBits(FIRST_CODE + 10, 9)
                content:writeBits(FIRST_CODE + 8, 9)

                local actual = LZWS.decompress(tostring(content))
                assert.are.same("XYZYZYXXYZXYZYYYYYYXYZY", actual)
            end)
            it("should generate 'XYZYZYXXYZXYZYYYYYYXYZYXYZYZY'", function()
                local content = BitWriter.new()
                local CODE_X = string.byte("X")
                local CODE_Y = string.byte("Y")
                local CODE_Z = string.byte("Z")
                -- Header
                content:writeBits(0, 3)   -- Version
                content:writeBits(9, 5)   -- Code width
                content:writeBits(15, 32) -- Code count
                -- Codes
                content:writeBits(CODE_X, 9)
                content:writeBits(CODE_Y, 9)
                content:writeBits(CODE_Z, 9)
                content:writeBits(FIRST_CODE + 1, 9)
                content:writeBits(CODE_Y, 9)
                content:writeBits(CODE_X, 9)
                content:writeBits(FIRST_CODE + 0, 9)
                content:writeBits(CODE_Z, 9)
                content:writeBits(FIRST_CODE + 6, 9)
                content:writeBits(CODE_Y, 9)
                content:writeBits(FIRST_CODE + 9, 9)
                content:writeBits(FIRST_CODE + 10, 9)
                content:writeBits(FIRST_CODE + 8, 9)
                -- XYZY
                content:writeBits(FIRST_CODE + 8, 9)
                -- ZY
                content:writeBits(FIRST_CODE + 2, 9)

                local actual = LZWS.decompress(tostring(content))
                assert.are.same("XYZYZYXXYZXYZYYYYYYXYZYXYZYZY", actual)
            end)
        end)
        describe("#end-to-end compress and decompress", function()
            it("should work on this source file (run busted from project root)", function()
                local f = assert(io.open("src/compression/LZWS_spec.lua", "r"))
                local contents = f:read("*all")
                f:close()

                local compressed = LZWS.compress(contents)
                local decompressed = LZWS.decompress(compressed)

                assert.is_true(decompressed == contents, "file content mismatch")
            end)
            it("should work on 'KwKwK'", function()
                -- https://courses.cs.duke.edu/spring03/cps296.5/papers/welch_1984_technique_for.pdf 
                -- Page 17, top left: "The abnormal case..."
                assert.are.same("KwKwK", LZWS.decompress(LZWS.compress("KwKwK")))
            end)
        end)
    end)
end)
