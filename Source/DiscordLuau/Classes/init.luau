--[[

Classes

Core classes for the Discord library including the main Client class.

--]]

local Client = require("@self/Client")

local Classes = {
    Client = Client,
}

return table.freeze(Classes)
