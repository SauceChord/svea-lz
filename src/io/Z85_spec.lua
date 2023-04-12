local Z85 = require "io.Z85"

describe("Z85", function()
    describe("encode with valid inputs", function()
        it("should encode an empty string into an empty string", function()
            assert.are.same("", Z85.encode(""))
        end)

        it("should encode a one letter string into two letters", function()
            assert.are.same("f-", Z85.encode("1"))
        end)

        it("should encode a two letter string into three letters", function()
            assert.are.same("f!@", Z85.encode("12"))
        end)

        it("should encode a three letter string into four letters", function()
            assert.are.same("f!$J", Z85.encode("123"))
        end)

        it("should encode a four letter string into five letters", function()
            assert.are.same("f!$Kw", Z85.encode("1234"))
        end)

        it("should encode a five letter string into seven letters", function()
            assert.are.same("f!$Kwh2", Z85.encode("12345"))
        end)

        it("should encode a longer string into a known output", function()
            local input = "SVEA Encoding in Dual Universe"
            local expected = "q=VsMavQfTz!9N1xcp]aavHuXy-(.}x)a6dB7C"

            assert.are.same(expected, Z85.encode(input))
        end)
    end)

    describe("encode with invalid inputs", function()
        it("should raise an error on nil for example", function()
            assert.has.error(function() Z85.encode(nil) end)
        end)
    end)
end)