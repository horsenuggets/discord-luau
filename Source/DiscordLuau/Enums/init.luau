--[[

Enums

Discord API enumerations including channel types, message types, intents, opcodes, and
permission flags.

--]]

local ApplicationCommandOptionType = require("@self/ApplicationCommandOptionType")
local ApplicationCommandType = require("@self/ApplicationCommandType")
local ChannelType = require("@self/ChannelType")
local GatewayCloseCode = require("@self/GatewayCloseCode")
local GatewayIntent = require("@self/GatewayIntent")
local GatewayOpcode = require("@self/GatewayOpcode")
local InteractionResponseType = require("@self/InteractionResponseType")
local InteractionType = require("@self/InteractionType")
local MessageType = require("@self/MessageType")
local Permission = require("@self/Permission")

local Enums = {
    ApplicationCommandOptionType = ApplicationCommandOptionType,
    ApplicationCommandType = ApplicationCommandType,
    ChannelType = ChannelType,
    GatewayCloseCode = GatewayCloseCode,
    GatewayIntent = GatewayIntent,
    GatewayOpcode = GatewayOpcode,
    InteractionResponseType = InteractionResponseType,
    InteractionType = InteractionType,
    MessageType = MessageType,
    Permission = Permission,
}

return table.freeze(Enums)
