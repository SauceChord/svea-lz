---@diagnostic disable: lowercase-global

---Utility for sanity checking input
---@param param any object to be tested for integer
---@param paramName string parameter name
function assert_is_int(param, paramName)
    assert(type(param) == "number" and math.floor(param) == param,
        string.format("%s (%s) must be an integer",
            paramName,
            type(param)))
end

---Utility for sanity checking input
---@param param any object to be tested for string
---@param paramName string parameter name
function assert_is_string(param, paramName)
    assert(type(param) == "string",
        string.format("%s (%s) must be a string",
            paramName,
            type(param)))
end

function assert_is_in_range(lower, upper, param, paramName)
    assert(param >= lower and param <= upper,
        string.format("%s (%s) must be in range %s to %s inclusive",
            paramName,
            tostring(param),
            tostring(lower),
            tostring(upper)))
end
