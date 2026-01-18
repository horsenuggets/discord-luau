--[[

Channel

Represents a Discord channel. Channels can be text, voice, category, thread, forum, or DM
channels, each with different capabilities.

--]]

local Types = require("./Types")

local Channel = {}
Channel.__index = Channel

export type Channel = typeof(setmetatable(
    {} :: {
        ApplicationId: Types.Snowflake?,
        Bitrate: number?,
        Client: Types.Client,
        DefaultAutoArchiveDuration: number?,
        DefaultForumLayout: number?,
        DefaultSortOrder: number?,
        DefaultThreadRateLimitPerUser: number?,
        Flags: number?,
        Guild: Types.Guild?,
        GuildId: Types.Snowflake?,
        Icon: string?,
        Id: Types.Snowflake,
        LastMessageId: Types.Snowflake?,
        LastPinTimestamp: string?,
        Managed: boolean?,
        MemberCount: number?,
        MessageCount: number?,
        Name: string?,
        Nsfw: boolean,
        OwnerId: Types.Snowflake?,
        ParentId: Types.Snowflake?,
        PermissionOverwrites: { Types.APIOverwrite }?,
        Position: number?,
        RateLimitPerUser: number?,
        Recipients: { Types.APIUser }?,
        RtcRegion: string?,
        Topic: string?,
        TotalMessageSent: number?,
        Type: number,
        UserLimit: number?,
        VideoQualityMode: number?,
        _data: Types.APIChannel,
    },
    Channel
))

function Channel.new(client: Types.Client, data: Types.APIChannel, guild: Types.Guild?): Channel
    assert(type(client) == "table", "Expected client to be a table")
    assert(type(data) == "table", "Expected data to be a table")

    local self = setmetatable({}, Channel)

    self.Client = client
    self.Guild = guild
    self._data = data

    self:_patch(data)

    return self
end

function Channel._patch(self: Channel, data: Types.APIChannel)
    self.ApplicationId = data.application_id
    self.Bitrate = data.bitrate
    self.DefaultAutoArchiveDuration = data.default_auto_archive_duration
    self.DefaultForumLayout = data.default_forum_layout
    self.DefaultSortOrder = data.default_sort_order
    self.DefaultThreadRateLimitPerUser = data.default_thread_rate_limit_per_user
    self.Flags = data.flags
    self.GuildId = data.guild_id
    self.Icon = data.icon
    self.Id = data.id
    self.LastMessageId = data.last_message_id
    self.LastPinTimestamp = data.last_pin_timestamp
    self.Managed = data.managed
    self.MemberCount = data.member_count
    self.MessageCount = data.message_count
    self.Name = data.name
    self.Nsfw = data.nsfw or false
    self.OwnerId = data.owner_id
    self.ParentId = data.parent_id
    self.PermissionOverwrites = data.permission_overwrites
    self.Position = data.position
    self.RateLimitPerUser = data.rate_limit_per_user
    self.Recipients = data.recipients
    self.RtcRegion = data.rtc_region
    self.Topic = data.topic
    self.TotalMessageSent = data.total_message_sent
    self.Type = data.type
    self.UserLimit = data.user_limit
    self.VideoQualityMode = data.video_quality_mode
end

function Channel.IsText(self: Channel): boolean
    -- Text channel types: GuildText (0), DM (1), GroupDM (3), GuildAnnouncement (5),
    -- AnnouncementThread (10), PublicThread (11), PrivateThread (12)
    local textTypes = { [0] = true, [1] = true, [3] = true, [5] = true, [10] = true, [11] = true, [12] = true }
    return textTypes[self.Type] == true
end

function Channel.IsVoice(self: Channel): boolean
    -- Voice channel types: GuildVoice (2), GuildStageVoice (13)
    return self.Type == 2 or self.Type == 13
end

function Channel.IsCategory(self: Channel): boolean
    return self.Type == 4
end

function Channel.IsThread(self: Channel): boolean
    -- Thread types: AnnouncementThread (10), PublicThread (11), PrivateThread (12)
    return self.Type == 10 or self.Type == 11 or self.Type == 12
end

function Channel.IsForum(self: Channel): boolean
    return self.Type == 15
end

function Channel.IsMedia(self: Channel): boolean
    return self.Type == 16
end

function Channel.IsDM(self: Channel): boolean
    return self.Type == 1 or self.Type == 3
end

function Channel.IsGuildBased(self: Channel): boolean
    return self.GuildId ~= nil
end

function Channel.Send(self: Channel, options: string | Types.MessageSendOptions): any
    assert(self:IsText(), "Cannot send messages to non-text channels")

    local body: Types.MessageSendOptions
    if type(options) == "string" then
        body = { content = options }
    else
        body = options
    end

    local data = self.Client.Rest:CreateMessage(self.Id, body)

    -- Use the Client's message factory to avoid cyclic dependency
    if self.Client._createMessage then
        return self.Client._createMessage(data, self)
    end

    -- Fallback: return raw data if factory not available
    return data
end

function Channel.GetIconUrl(self: Channel, options: { format: string?, size: number? }?): string?
    if not self.Icon then
        return nil
    end

    local format = options and options.format or "webp"
    local size = options and options.size or 64

    return `https://cdn.discordapp.com/channel-icons/{self.Id}/{self.Icon}.{format}?size={size}`
end

function Channel.GetUrl(self: Channel): string
    if self.GuildId then
        return `https://discord.com/channels/{self.GuildId}/{self.Id}`
    else
        return `https://discord.com/channels/@me/{self.Id}`
    end
end

function Channel.ToString(self: Channel): string
    return `<#{self.Id}>`
end

function Channel.__tostring(self: Channel): string
    return `Channel({self.Id})`
end

return Channel
