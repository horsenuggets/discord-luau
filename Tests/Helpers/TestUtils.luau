--[[

TestUtils

Helper functions for testing Discord-Luau structures.

--]]

local TestUtils = {}

-- Check if a string contains a substring (plain text, not pattern)
function TestUtils.contains(str: string?, substring: string): boolean
    if str == nil then
        return false
    end
    return string.find(str, substring, 1, true) ~= nil
end

return TestUtils
