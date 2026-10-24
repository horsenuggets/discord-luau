--[[

DiscordLuau

A comprehensive Discord API library for Luau, inspired by discord.js. Provides a
full-featured client for building Discord bots with event handling, REST API access,
and WebSocket gateway support.

--]]

const Classes = require("@self/Classes")
const Enums = require("@self/Enums")
const Gateway = require("@self/Gateway")
const Lavalink = require("@self/Lavalink")
const Rest = require("@self/Rest")
const Structures = require("@self/Structures")
const Types = require("@self/Structures/Types")
const Utils = require("@self/Utils")

-- Re-export commonly used classes at top level
const Client = Classes.Client
const Embed = Structures.Embed
const SlashCommandBuilder = Structures.SlashCommandBuilder

-- Re-export enums at top level
const ApplicationCommandOptionType = Enums.ApplicationCommandOptionType
const ApplicationCommandType = Enums.ApplicationCommandType
const ChannelType = Enums.ChannelType
const GatewayCloseCode = Enums.GatewayCloseCode
const GatewayIntent = Enums.GatewayIntent
const GatewayOpcode = Enums.GatewayOpcode
const InteractionResponseType = Enums.InteractionResponseType
const InteractionType = Enums.InteractionType
const MessageType = Enums.MessageType
const Permission = Enums.Permission

-- Convenience aliases
const Intents = GatewayIntent

const DiscordLuau = {
    -- Main client class
    Client = Client,

    -- Convenience exports
    Embed = Embed,
    SlashCommandBuilder = SlashCommandBuilder,

    -- Enums
    ApplicationCommandOptionType = ApplicationCommandOptionType,
    ApplicationCommandType = ApplicationCommandType,
    ChannelType = ChannelType,
    Enums = Enums,
    GatewayCloseCode = GatewayCloseCode,
    GatewayIntent = GatewayIntent,
    GatewayOpcode = GatewayOpcode,
    Intents = Intents,
    InteractionResponseType = InteractionResponseType,
    InteractionType = InteractionType,
    MessageType = MessageType,
    Permission = Permission,

    -- Audio (Lavalink integration)
    Lavalink = Lavalink,

    -- Internal modules (for advanced usage)
    Classes = Classes,
    Gateway = Gateway,
    Rest = Rest,
    Structures = Structures,
    Types = Types,
    Utils = Utils,
}

return table.freeze(DiscordLuau)
