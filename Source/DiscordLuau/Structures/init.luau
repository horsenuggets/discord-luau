--[[

Structures

Discord structure classes representing API objects like Users, Guilds, Channels, Messages,
and more. These classes wrap raw API data and provide convenient methods.

--]]

local Channel = require("@self/Channel")
local Embed = require("@self/Embed")
local Guild = require("@self/Guild")
local Interaction = require("@self/Interaction")
local Member = require("@self/Member")
local Message = require("@self/Message")
local Role = require("@self/Role")
local SlashCommandBuilder = require("@self/SlashCommandBuilder")
local User = require("@self/User")
local VoiceState = require("@self/VoiceState")

local Structures = {
    Channel = Channel,
    Embed = Embed,
    Guild = Guild,
    Interaction = Interaction,
    Member = Member,
    Message = Message,
    Role = Role,
    SlashCommandBuilder = SlashCommandBuilder,
    User = User,
    VoiceState = VoiceState,
}

return table.freeze(Structures)
