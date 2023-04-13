local Z85 = require "encoding.Z85"

describe("Z85", function()
    describe("encode", function()
        describe("with valid inputs", function()
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

        describe("with invalid inputs", function()
            it("should raise an error on nil for example", function()
                assert.has.error(function() Z85.encode(nil) end)
            end)
        end)
    end)

    describe("decode", function()
        describe("with valid inputs", function()
            it("should decode an empty string into an empty string", function()
                assert.is.same("", Z85.decode(""))
            end)

            it("should decode a one letter string into an empty string", function()
                assert.is.same("", Z85.decode("f"))
            end)

            it("should decode a two letter string into one letter", function()
                assert.is.same("1", Z85.decode("f-"))
            end)

            it("should decode a three letter string into two letters", function()
                assert.is.same("12", Z85.decode("f!@"))
            end)

            it("should decode a four letter string into three letters", function()
                assert.is.same("123", Z85.decode("f!$J"))
            end)

            it("should decode a five letter string into four letters", function()
                assert.is.same("1234", Z85.decode("f!$Kw"))
            end)

            it("should decode a seven letter string into five letters", function()
                assert.is.same("12345", Z85.decode("f!$Kwh2"))
            end)

            it("should decode a longer string into a known output", function()
                local encoded = "q=VsMavQfTz!9N1xcp]aavHuXy-(.}x)a6dB7C"
                local expected = "SVEA Encoding in Dual Universe"

                assert.are.same(expected, Z85.decode(encoded))
            end)
        end)

        describe("with invalid inputs", function()
            it("should raise an error on nil for example", function()
---@diagnostic disable-next-line: param-type-mismatch
                assert.has.error(function() Z85.decode(nil) end)
            end)
        end)
    end)
end)
