--[[

Snowflake

Utilities for working with Discord Snowflake IDs. Snowflakes are 64-bit identifiers that
encode creation timestamp and other metadata.

--]]

-- Discord epoch (2015-01-01T00:00:00.000Z) in milliseconds
local DISCORD_EPOCH = 1420070400000

local Snowflake = {}

-- Helper to divide a large number string by a power of 2 and return quotient and lower bits
local function divideBy(numStr: string, divisor: number): (string, number)
    local result = ""
    local remainder = 0

    for i = 1, #numStr do
        local digit = tonumber(string.sub(numStr, i, i))
        local current = remainder * 10 + digit
        local quotient = math.floor(current / divisor)
        remainder = current % divisor

        if #result > 0 or quotient > 0 then
            result ..= tostring(quotient)
        end
    end

    if result == "" then
        result = "0"
    end

    return result, remainder
end

-- Helper to extract bits from a snowflake string
-- offset: bit position from the right (0-indexed)
-- bits: number of bits to extract
local function extractBits(snowflake: string, offset: number, bits: number): number
    assert(type(snowflake) == "string", "Expected snowflake to be a string")

    -- Validate snowflake is numeric
    if not string.match(snowflake, "^%d+$") then
        error(`Invalid snowflake "{snowflake}"`)
    end

    -- For extracting bits, we need to shift right by offset and mask with (2^bits - 1)
    -- We do this by dividing by 2^offset and taking modulo 2^bits

    local shiftedStr = snowflake
    for _ = 1, offset do
        shiftedStr = divideBy(shiftedStr, 2)
    end

    -- Now extract the lower 'bits' bits
    local mask = (2 ^ bits) - 1
    local value = 0
    local multiplier = 1

    for _ = 1, bits do
        local _, remainder = divideBy(shiftedStr, 2)
        shiftedStr = divideBy(shiftedStr, 2)
        value += remainder * multiplier
        multiplier *= 2
    end

    return math.floor(value % (mask + 1))
end

-- Helper to extract timestamp (top 42 bits after shifting by 22)
local function extractTimestamp(snowflake: string): number
    assert(type(snowflake) == "string", "Expected snowflake to be a string")

    if not string.match(snowflake, "^%d+$") then
        error(`Invalid snowflake "{snowflake}"`)
    end

    -- Divide by 2^22 to shift right by 22 bits
    local shiftedStr = snowflake
    for _ = 1, 22 do
        shiftedStr = divideBy(shiftedStr, 2)
    end

    -- Convert the result to a number and add Discord epoch
    local timestamp = tonumber(shiftedStr) or 0
    return timestamp + DISCORD_EPOCH
end

function Snowflake.getTimestamp(snowflake: string): number
    return extractTimestamp(snowflake)
end

-- Note: getDate is not available in standard Luau/Lune. Use getTimestamp and convert manually.
-- For Roblox, you can use: DateTime.fromUnixTimestampMillis(Snowflake.getTimestamp(snowflake))

function Snowflake.getWorkerId(snowflake: string): number
    return extractBits(snowflake, 17, 5)
end

function Snowflake.getProcessId(snowflake: string): number
    return extractBits(snowflake, 12, 5)
end

function Snowflake.getIncrement(snowflake: string): number
    return extractBits(snowflake, 0, 12)
end

function Snowflake.compare(a: string, b: string): number
    assert(type(a) == "string", "Expected a to be a string")
    assert(type(b) == "string", "Expected b to be a string")

    -- Validate both are numeric strings
    if not string.match(a, "^%d+$") then
        error(`Invalid snowflake "{a}"`)
    end
    if not string.match(b, "^%d+$") then
        error(`Invalid snowflake "{b}"`)
    end

    -- Compare by length first (longer number is larger)
    if #a < #b then
        return -1
    elseif #a > #b then
        return 1
    end

    -- Same length, compare lexicographically (works for equal-length numeric strings)
    if a < b then
        return -1
    elseif a > b then
        return 1
    else
        return 0
    end
end

return table.freeze(Snowflake)
