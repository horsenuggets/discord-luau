--[[

Rest

Re-exports the Rest class and its type so callers can require the folder directly.

--]]

const Rest = require("@self/Rest")

export type Rest = Rest.Rest

return Rest
