--[[

Enums

Discord API enumerations including channel types, message types, intents, opcodes, and
permission flags.

--]]

const ApplicationCommandOptionType = require("@self/ApplicationCommandOptionType")
const ApplicationCommandType = require("@self/ApplicationCommandType")
const ChannelType = require("@self/ChannelType")
const GatewayCloseCode = require("@self/GatewayCloseCode")
const GatewayIntent = require("@self/GatewayIntent")
const GatewayOpcode = require("@self/GatewayOpcode")
const InteractionResponseType = require("@self/InteractionResponseType")
const InteractionType = require("@self/InteractionType")
const MessageType = require("@self/MessageType")
const Permission = require("@self/Permission")

const Enums = {
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
