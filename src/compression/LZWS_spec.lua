local LZWS = require "compression.LZWS"
local BitReader = require "io.BitReader"

-- LZWS contains a predefined dictionary and FIRST_COMPRESSED_CODE is where compressed entries start counting from
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
        end)
        describe("with invalid inputs it", function()
            it("should reject bitWidth less than 9", function()
                assert.has.error(function() LZWS.compress("", 8) end, "bitCount has to be in range 9 to 24")
            end)
            it("should reject bitWidth greater than 24", function()
                assert.has.error(function() LZWS.compress("", 25) end, "bitCount has to be in range 9 to 24")
            end)
            it("should reject nil string input", function()
                assert.has.error(function() LZWS.compress(nil) end, "s must be a string")
            end)
            it("should reject decimal bitWidth input", function()
                assert.has.error(function() LZWS.compress("", 10.5) end, "maxBitWidth must be an integer")
            end)
        end)
    end)
end)
