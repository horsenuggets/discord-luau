--[[

VoiceState

Represents a user's voice connection state within a guild. Contains information about which
voice channel they are in, their mute/deaf status, and streaming state.

--]]

local Types = require("./Types")

local VoiceState = {}
VoiceState.__index = VoiceState

export type VoiceState = typeof(setmetatable(
    {} :: {
        ChannelId: Types.Snowflake?,
        Client: Types.Client,
        Deaf: boolean,
        Guild: Types.Guild?,
        GuildId: Types.Snowflake?,
        Member: Types.APIMember?,
        Mute: boolean,
        RequestToSpeakTimestamp: string?,
        SelfDeaf: boolean,
        SelfMute: boolean,
        SelfStream: boolean,
        SelfVideo: boolean,
        SessionId: string,
        Suppress: boolean,
        UserId: Types.Snowflake,
        _data: Types.APIVoiceState,
    },
    VoiceState
))

function VoiceState.new(client: Types.Client, data: Types.APIVoiceState, guild: Types.Guild?): VoiceState
    assert(type(client) == "table", "Expected client to be a table")
    assert(type(data) == "table", "Expected data to be a table")

    local self = setmetatable({}, VoiceState)

    self.Client = client
    self.Guild = guild
    self._data = data

    self:_patch(data)

    return self
end

function VoiceState._patch(self: VoiceState, data: Types.APIVoiceState)
    self.ChannelId = data.channel_id
    self.Deaf = data.deaf or false
    self.GuildId = data.guild_id
    self.Member = data.member
    self.Mute = data.mute or false
    self.RequestToSpeakTimestamp = data.request_to_speak_timestamp
    self.SelfDeaf = data.self_deaf or false
    self.SelfMute = data.self_mute or false
    self.SelfStream = data.self_stream or false
    self.SelfVideo = data.self_video or false
    self.SessionId = data.session_id
    self.Suppress = data.suppress or false
    self.UserId = data.user_id
end

function VoiceState.IsConnected(self: VoiceState): boolean
    return self.ChannelId ~= nil
end

function VoiceState.GetChannel(self: VoiceState): Types.Channel?
    if not self.ChannelId then
        return nil
    end

    -- Try to get from guild first
    if self.Guild then
        return self.Guild.Channels[self.ChannelId]
    end

    -- Fall back to client cache
    return self.Client.Channels[self.ChannelId]
end

function VoiceState.GetGuild(self: VoiceState): Types.Guild?
    if self.Guild then
        return self.Guild
    end

    if self.GuildId then
        return self.Client.Guilds[self.GuildId]
    end

    return nil
end

function VoiceState.IsMuted(self: VoiceState): boolean
    return self.Mute or self.SelfMute
end

function VoiceState.IsDeafened(self: VoiceState): boolean
    return self.Deaf or self.SelfDeaf
end

function VoiceState.IsStreaming(self: VoiceState): boolean
    return self.SelfStream
end

function VoiceState.IsSuppressed(self: VoiceState): boolean
    return self.Suppress
end

function VoiceState.__tostring(self: VoiceState): string
    local channelPart = self.ChannelId or "none"
    return `VoiceState({self.UserId} in {channelPart})`
end

return VoiceState
