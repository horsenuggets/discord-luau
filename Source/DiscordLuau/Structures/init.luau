--[[

Structures

Discord structure classes representing API objects like Users, Guilds, Channels, Messages,
and more. These classes wrap raw API data and provide convenient methods.

--]]

const Channel = require("@self/Channel")
const Embed = require("@self/Embed")
const Guild = require("@self/Guild")
const Interaction = require("@self/Interaction")
const Member = require("@self/Member")
const Message = require("@self/Message")
const Role = require("@self/Role")
const SlashCommandBuilder = require("@self/SlashCommandBuilder")
const User = require("@self/User")
const VoiceState = require("@self/VoiceState")

const Structures = {
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
