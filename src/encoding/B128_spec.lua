local B128 = require "encoding.B128"

describe("B128", function()
    describe("encode", function()
        describe("when given valid inputs", function()
            it("should encode an empty string", function()
                assert.are.same("", B128.encode(""))
            end)
            it("should encode 'a'", function()
                local expected = string.char(97, 0)
                local actual = B128.encode("a")

                assert.are.same(#expected, #actual, "encoded length")
                for i = 1, #expected do
                    assert.are.same(expected:byte(i), actual:byte(i), "byte at " .. i)
                end
            end)
            it("should encode (255, 255)", function()
                local expected = string.char(127, 127, 3)
                local actual = B128.encode(string.char(255, 255))

                assert.are.same(#expected, #actual, "encoded length")
                for i = 1, #expected do
                    assert.are.same(expected:byte(i), actual:byte(i), "byte at " .. i)
                end
            end)
            it("should encode (255, 255, 255)", function()
                local expected = string.char(127, 127, 127, 7)
                local actual = B128.encode(string.char(255, 255, 255))

                assert.are.same(#expected, #actual, "encoded length")
                for i = 1, #expected do
                    assert.are.same(expected:byte(i), actual:byte(i), "byte at " .. i)
                end
            end)
            it("should encode (255, 255, 255, 255, 255, 255, 255, 255)", function()
                local expected = string.char(127, 127, 127, 127, 127, 127, 127, 127, 127, 1)
                local actual = B128.encode(string.char(255, 255, 255, 255, 255, 255, 255, 255))

                assert.are.same(#expected, #actual, "encoded length")
                for i = 1, #expected do
                    assert.are.same(expected:byte(i), actual:byte(i), "byte at " .. i)
                end
            end)
            it("should encode 'This is a test'", function()
                -- "This is a test" in binary:
                --   01010100 01101000 01101001 01110011 00100000 01101001 01110011
                --   00100000 01100001 00100000 01110100 01100101 01110011 01110100
                -- Should encode to:
                --   01010100 01010000 00100101 00011011 00000111 00100100 01011010 00111001
                --   00100000 01000010 00000001 00100001 01010111 01101100 00011100 00111010
                -- Encoded numbers:
                --   84, 80, 37, 27, 7, 36, 90, 57,
                --   32, 66, 1, 33, 87, 108, 28, 58, 0
                local expected = string.char(84, 80, 37, 27, 7, 36, 90, 57, 32, 66, 1, 33, 87, 108, 28, 58)
                local actual = B128.encode("This is a test")

                assert.are.same(#expected, #actual, "encoded length")
                for i = 1, #expected do
                    assert.are.same(expected:byte(i), actual:byte(i), "byte at " .. i)
                end
            end)
        end)
    end)
    describe("decode", function()
        describe("when given valid inputs", function()
            it("should decode an empty string", function()
                assert.are.same("", B128.decode(""))
            end)
            it("should decode to 'a'", function()
                local expected = "a"
                local actual = B128.decode(string.char(97, 0))

                assert.are.same(#expected, #actual, "decoded length")
                for i = 1, #expected do
                    assert.are.same(expected:byte(i), actual:byte(i), "byte at " .. i)
                end
            end)
            it("should decode to (255, 255)", function()
                local expected = string.char(255, 255)
                local actual = B128.decode(string.char(127, 127, 3))

                assert.are.same(#expected, #actual, "decoded length")
                for i = 1, #expected do
                    assert.are.same(expected:byte(i), actual:byte(i), "byte at " .. i)
                end
            end)
            it("should decode to (255, 255, 255)", function()
                local expected = string.char(255, 255, 255)
                local actual = B128.decode(string.char(127, 127, 127, 7))

                assert.are.same(#expected, #actual, "decoded length")
                for i = 1, #expected do
                    assert.are.same(expected:byte(i), actual:byte(i), "byte at " .. i)
                end
            end)
            it("should decode to (255, 255, 255, 255, 255, 255, 255, 255)", function()
                local expected = string.char(255, 255, 255, 255, 255, 255, 255, 255)
                local actual = B128.decode(string.char(127, 127, 127, 127, 127, 127, 127, 127, 127, 1))

                assert.are.same(#expected, #actual, "decoded length")
                for i = 1, #expected do
                    assert.are.same(expected:byte(i), actual:byte(i), "byte at " .. i)
                end
            end)
            it("should decode to 'This is a test'", function()
                -- "This is a test" in binary:
                --   01010100 01101000 01101001 01110011 00100000 01101001 01110011
                --   00100000 01100001 00100000 01110100 01100101 01110011 01110100
                -- Should encode to:
                --   01010100 01010000 00100101 00011011 00000111 00100100 01011010 00111001
                --   00100000 01000010 00000001 00100001 01010111 01101100 00011100 00111010
                -- Encoded numbers:
                --   84, 80, 37, 27, 7, 36, 90, 57,
                --   32, 66, 1, 33, 87, 108, 28, 58, 0
                local expected = "This is a test"
                local actual = B128.decode(string.char(84, 80, 37, 27, 7, 36, 90, 57, 32, 66, 1, 33, 87, 108, 28, 58))

                assert.are.same(#expected, #actual, "decoded length")
                for i = 1, #expected do
                    assert.are.same(expected:byte(i), actual:byte(i), "byte at " .. i)
                end
            end)
        end)
    end)
end)
