local say = require "say"

local function is_binary(state, arguments)
    return tonumber(arguments[1], 2) == arguments[2]
end

say:set_namespace("en")
say:set("assertion.is_binary.positive", "Expected binary %s to equal %s")     -- Wish I could format the second string to a binary string
say:set("assertion.is_binary.negative", "Expected binary %s to not equal %s") -- Wish I could format the second string to a binary string
assert:register("assertion", "is_binary", is_binary, "assertion.is_binary.positive", "assertion.is_binary.negative")

describe("BitWriter", function()
    local BitWriter

    setup(function()
        BitWriter = require "io.BitWriter"
    end)

    teardown(function()
        BitWriter = nil
    end)

    it("should have a module", function()
        assert.is_not.same(nil, BitWriter)
    end)

    it("should create a new instance", function()
        assert.is_not.same(nil, BitWriter:new())
    end)

    it("should allocate zero bytes on new", function()
        local writer = BitWriter.new()

        assert.is.same(0, #writer.bytes)
    end)

    describe("writeBits", function()
        it("should allocate one byte on writeBits(0, 8)", function()
            local writer = BitWriter.new()

            writer:writeBits(0, 8)

            assert.is.same(8, writer.bits)
            assert.is.same(1, #writer.bytes)
        end)

        it("should store one byte value on writeBits(255, 8)", function()
            local writer = BitWriter.new()

            writer:writeBits(255, 8)

            assert.is.same(8, writer.bits)
            assert.is.same(1, #writer.bytes)
            assert.is_binary("11111111", writer.bytes[1])
        end)

        it("should write two bits", function()
            local writer = BitWriter.new()

            writer:writeBits(1, 1)
            writer:writeBits(1, 1)

            assert.is.same(2, writer.bits)
            assert.is.same(1, #writer.bytes)
            assert.is_binary("11", writer.bytes[1])
        end)

        it("should write nine bits", function()
            local writer = BitWriter.new()

            writer:writeBits(1, 1)
            writer:writeBits(tonumber("10011010", 2), 8)

            assert.is.same(9, writer.bits)
            assert.is.same(2, #writer.bytes)
            assert.is_binary("00110101", writer.bytes[1])
            assert.is_binary("00000001", writer.bytes[2])
        end)

        it("should write 32 bits", function()
            local writer = BitWriter.new()

            writer:writeBits(tonumber("11110000000011111111111100000000", 2), 32)

            assert.is.same(32, writer.bits)
            assert.is.same(4, #writer.bytes)
            assert.is_binary("00000000", writer.bytes[1])
            assert.is_binary("11111111", writer.bytes[2])
            assert.is_binary("00001111", writer.bytes[3])
            assert.is_binary("11110000", writer.bytes[4])
        end)

        it("should write 64 bits", function()
            local writer = BitWriter.new()

            writer:writeBits(tonumber("1111000000001111111111110000000011110000000011111111111100000000", 2), 64)

            assert.is.same(64, writer.bits)
            assert.is.same(8, #writer.bytes)
            assert.is_binary("00000000", writer.bytes[1])
            assert.is_binary("11111111", writer.bytes[2])
            assert.is_binary("00001111", writer.bytes[3])
            assert.is_binary("11110000", writer.bytes[4])
            assert.is_binary("00000000", writer.bytes[5])
            assert.is_binary("11111111", writer.bytes[6])
            assert.is_binary("00001111", writer.bytes[7])
            assert.is_binary("11110000", writer.bytes[8])
        end)

        it("should handle negative values", function()
            local writer = BitWriter.new()

            writer:writeBits(-1, 64)

            assert.is.same(64, writer.bits)
            assert.is.same(8, #writer.bytes)
            assert.is_binary("11111111", writer.bytes[1])
            assert.is_binary("11111111", writer.bytes[2])
            assert.is_binary("11111111", writer.bytes[3])
            assert.is_binary("11111111", writer.bytes[4])
            assert.is_binary("11111111", writer.bytes[5])
            assert.is_binary("11111111", writer.bytes[6])
            assert.is_binary("11111111", writer.bytes[7])
            assert.is_binary("11111111", writer.bytes[8])
        end)

        it("should allow 0 bits with no effect", function()
            local writer = BitWriter.new()

            writer:writeBits(1234, 0)

            assert.is.same(0, writer.bits)
            assert.is.same(0, #writer.bytes)
        end)

        it("should not write over 64 bits", function()
            local writer = BitWriter.new()

            assert.has.errors(function() writer:writeBits(0, 65) end)
        end)

        it("should not write -1 bits", function()
            local writer = BitWriter.new()

            assert.has.errors(function() writer:writeBits(0, -1) end)
        end)

        it("should raise errors on non-integer input and have no side effect", function()
            local writer = BitWriter.new()

            assert.has.errors(function() writer:writeBits(nil, nil) end)
            assert.has.errors(function() writer:writeBits("123", "1") end)
            assert.has.errors(function() writer:writeBits(10.2, 2.2) end)
            assert.is.same(0, writer.bits)
            assert.is.same(0, #writer.bytes)
        end)
    end)

    describe("tostring formats", function()
        it("no bits generates a 8 byte header", function()
            local writer = BitWriter.new()

            local actual = tostring(writer)

            assert.is.same(8, #actual)
            assert.is.same(0, string.unpack("J", actual))
        end)

        it("one bit generates 8+1=9 bytes", function()
            local writer = BitWriter.new()
            writer:writeBits(1, 1)

            local actual = tostring(writer)

            assert.is.same(9, #actual)
            assert.is.same(1, string.unpack("J", actual))
            assert.is.same(1, actual:byte(9))
        end)

        it("two bits generates 8+1=9 bytes", function()
            local writer = BitWriter.new()
            writer:writeBits(6, 3)

            local actual = tostring(writer)

            assert.is.same(9, #actual)
            assert.is.same(3, string.unpack("J", actual))
            assert.is.same(6, actual:byte(9))
        end)

        it("17 bits generates 8+3=11 bytes", function()
            local writer = BitWriter.new()
            writer:writeBits(tonumber("11100110011110000", 2), 17)

            local actual = tostring(writer)

            assert.is.same(11, #actual)
            assert.is.same(17, string.unpack("J", actual))
            assert.is_binary("11110000", actual:byte(9))
            assert.is_binary("11001100", actual:byte(10))
            assert.is_binary("00000001", actual:byte(11))
        end)
    end)
end)
