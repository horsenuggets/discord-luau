--[[

DiscordLuau

A comprehensive Discord API library for Luau, inspired by discord.js. Provides a
full-featured client for building Discord bots with event handling, REST API access,
and WebSocket gateway support.

--]]

local Classes = require("@self/Classes")
local Enums = require("@self/Enums")
local Gateway = require("@self/Gateway")
local Rest = require("@self/Rest")
local Structures = require("@self/Structures")
local Types = require("@self/Structures/Types")
local Utils = require("@self/Utils")

-- Re-export commonly used classes at top level
local Client = Classes.Client
local Embed = Structures.Embed
local SlashCommandBuilder = Structures.SlashCommandBuilder

-- Re-export enums at top level
local ApplicationCommandOptionType = Enums.ApplicationCommandOptionType
local ApplicationCommandType = Enums.ApplicationCommandType
local ChannelType = Enums.ChannelType
local GatewayCloseCode = Enums.GatewayCloseCode
local GatewayIntent = Enums.GatewayIntent
local GatewayOpcode = Enums.GatewayOpcode
local InteractionResponseType = Enums.InteractionResponseType
local InteractionType = Enums.InteractionType
local MessageType = Enums.MessageType
local Permission = Enums.Permission

-- Convenience aliases
local Intents = GatewayIntent

local DiscordLuau = {
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

    -- Internal modules (for advanced usage)
    Classes = Classes,
    Gateway = Gateway,
    Rest = Rest,
    Structures = Structures,
    Types = Types,
    Utils = Utils,
}

return table.freeze(DiscordLuau)
