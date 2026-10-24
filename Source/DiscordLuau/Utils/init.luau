--[[

Utils

Utility modules for the Discord library including event handling, snowflake operations,
and common helper functions.

--]]

const Connection = require("@self/Connection")
const Signal = require("@self/Signal")
const Snowflake = require("@self/Snowflake")

const Utils = {
    Connection = Connection,
    Signal = Signal,
    Snowflake = Snowflake,
}

return table.freeze(Utils)
