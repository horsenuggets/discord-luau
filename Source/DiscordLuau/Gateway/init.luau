--[[

Gateway

Re-exports the Gateway class and its type so callers can require the folder directly.

--]]

const Gateway = require("@self/Gateway")

export type Gateway = Gateway.Gateway

return Gateway
