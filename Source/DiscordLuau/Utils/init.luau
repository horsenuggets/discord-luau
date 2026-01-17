--[[

Utils

Utility modules for the Discord library including event handling, snowflake operations,
and common helper functions.

--]]

local Connection = require("@self/Connection")
local Signal = require("@self/Signal")
local Snowflake = require("@self/Snowflake")

local Utils = {
    Connection = Connection,
    Signal = Signal,
    Snowflake = Snowflake,
}

return table.freeze(Utils)
