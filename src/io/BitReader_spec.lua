local say = require "say"

local function is_binary(state, arguments)
    return tonumber(arguments[1], 2) == arguments[2]
end

say:set_namespace("en")
say:set("assertion.is_binary.positive", "Expected binary %s to equal %s")     -- Wish I could format the second string to a binary string
say:set("assertion.is_binary.negative", "Expected binary %s to not equal %s") -- Wish I could format the second string to a binary string
assert:register("assertion", "is_binary", is_binary, "assertion.is_binary.positive", "assertion.is_binary.negative")

describe("BitReader's function", function()
    local BitReader

    setup(function()
        BitReader = require "io.BitReader"
    end)

    teardown(function()
        BitReader = nil
    end)

    describe("new, given an encoded string it", function()
        it("should allocate zero bytes", function()
            local s = string.pack("J", 0)
            local reader = BitReader.new(s)

            assert.is.same(0, reader.bits)
            assert.is.same(0, reader.location)
            assert.is.same(0, #reader.bytes)
        end)

        it("should allocate one byte", function()
            local s = string.pack("JB", 8, 255)
            local reader = BitReader.new(s)

            assert.is.same(8, reader.bits)
            assert.is.same(0, reader.location)
            assert.is.same(1, #reader.bytes)
        end)

        it("should allocate two bytes", function()
            local s = string.pack("JBB", 9, 255, 1)
            local reader = BitReader.new(s)

            assert.is.same(9, reader.bits)
            assert.is.same(0, reader.location)
            assert.is.same(2, #reader.bytes)
        end)
    end)

    describe("readBits should raise an error when it", function()
        it("is reading an empty stream", function()
            local s = string.pack("J", 0)
            local reader = BitReader.new(s)

            assert.has.error(function() reader:readBits(1) end)
        end)

        it("is passed a non-integer width", function()
            local s = string.pack("JB", 1, 1)
            local reader = BitReader.new(s)

            assert.has.error(function() reader:readBits(1.2) end)
        end)

        it("is passed a negative width", function()
            local s = string.pack("JB", 1, 1)
            local reader = BitReader.new(s)

            assert.has.error(function() reader:readBits(-1) end)
        end)

        it("is asked to provide more than 64 bits", function()
            local s = string.pack("JJJ", 128, 0, 0)
            local reader = BitReader.new(s)

            assert.has.error(function() reader:readBits(65) end)
        end)

        it("is called with zero width", function()
            local s = string.pack("J", 0)
            local reader = BitReader.new(s)

            assert.has.error(function() reader:readBits(0) end)
        end)
    end)

    describe("readBits should return non-zero extended integer(s) when it", function()
        it("is called once with a 3 bit request", function()
            local s = string.pack("JB", 3, 5)
            local reader = BitReader.new(s)

            assert.is.same(0, reader.location)
            assert.is.same(5, reader:readBits(3))
            assert.is.same(3, reader.location)
        end)

        it("is called twice with a 3 bit request", function()
            local s = string.pack("JB", 6, tonumber("101111", 2))
            local reader = BitReader.new(s)

            assert.is_binary("111", reader:readBits(3))
            assert.is_binary("101", reader:readBits(3))
        end)

        it("is called three times with a 3 bit request", function()
            local s = string.pack("JI2", 9, tonumber("101100001", 2))
            local reader = BitReader.new(s)

            assert.is_binary("001", reader:readBits(3))
            assert.is_binary("100", reader:readBits(3))
            assert.is_binary("101", reader:readBits(3))
        end)

        it("is called once with a 24 bit request", function()
            local s = string.pack("JI3", 24, tonumber("111111010000001011110000", 2))
            local reader = BitReader.new(s)

            assert.is_binary("111111010000001011110000", reader:readBits(24))
        end)

        it("is called 6 times with a 4 bit request", function()
            local s = string.pack("JI3", 24, tonumber("111111010000001011110000", 2))
            local reader = BitReader.new(s)

            assert.is_binary("0000", reader:readBits(4))
            assert.is_binary("1111", reader:readBits(4))
            assert.is_binary("0010", reader:readBits(4))
            assert.is_binary("0000", reader:readBits(4))
            assert.is_binary("1101", reader:readBits(4))
            assert.is_binary("1111", reader:readBits(4))
        end)
    end)

    describe("readBool should raise an error when it", function()
        it("has reached end of stream", function()
            local s = string.pack("J", 0)
            local reader = BitReader.new(s)

            assert.has.error(function() reader:readBool() end)
        end)
    end)

    describe("readBool", function()
        it("should return false on 0", function()
            local s = string.pack("JB", 1, 0)
            local reader = BitReader.new(s)

            assert.is_not_true(reader:readBool())
        end)
    end)

    describe("readBool", function()
        it("should return true on 1", function()
            local s = string.pack("JB", 1, 1)
            local reader = BitReader.new(s)

            assert.is_true(reader:readBool())
        end)
    end)

    describe("tostring", function()
        it("should return a format of its size and location", function()
            local s = string.pack("JB", 2, 0)
            local reader = BitReader.new(s)

            reader:readBool()

            assert.are.same("{ bits = 2, location = 1 }", tostring(reader))
        end)
    end)
end)
