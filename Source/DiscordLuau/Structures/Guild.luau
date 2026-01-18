--[[

Guild

Represents a Discord guild (server). Contains channels, members, roles, and guild settings.

--]]

local Channel = require("./Channel")
local Member = require("./Member")
local Role = require("./Role")
local Types = require("./Types")

--[=[
    @class Guild
    @tag structure

    Represents a Discord guild (server). Contains channels, members, roles,
    and guild settings. Provides methods for managing the guild.
]=]
local Guild = {}
Guild.__index = Guild

export type Guild = typeof(setmetatable(
    {} :: {
        AfkChannelId: Types.Snowflake?,
        AfkTimeout: number,
        ApplicationId: Types.Snowflake?,
        ApproximateMemberCount: number?,
        ApproximatePresenceCount: number?,
        Banner: string?,
        Channels: { [Types.Snowflake]: Channel.Channel },
        Client: Types.Client,
        DefaultMessageNotifications: number,
        Description: string?,
        DiscoverySplash: string?,
        ExplicitContentFilter: number,
        Features: { string },
        Icon: string?,
        IconHash: string?,
        Id: Types.Snowflake,
        JoinedAt: string?,
        Large: boolean,
        MaxMembers: number?,
        MaxPresences: number?,
        MaxVideoChannelUsers: number?,
        MemberCount: number?,
        Members: { [Types.Snowflake]: Member.Member },
        MfaLevel: number,
        Name: string,
        NsfwLevel: number,
        OwnerId: Types.Snowflake,
        PreferredLocale: string,
        PremiumProgressBarEnabled: boolean,
        PremiumSubscriptionCount: number?,
        PremiumTier: number,
        PublicUpdatesChannelId: Types.Snowflake?,
        Roles: { [Types.Snowflake]: Role.Role },
        RulesChannelId: Types.Snowflake?,
        SafetyAlertsChannelId: Types.Snowflake?,
        Splash: string?,
        SystemChannelFlags: number,
        SystemChannelId: Types.Snowflake?,
        Unavailable: boolean,
        VanityUrlCode: string?,
        VerificationLevel: number,
        VoiceStates: { [Types.Snowflake]: Types.APIVoiceState },
        WidgetChannelId: Types.Snowflake?,
        WidgetEnabled: boolean?,
        _data: Types.APIGuild,
    },
    Guild
))

function Guild.new(client: Types.Client, data: Types.APIGuild): Guild
    assert(type(client) == "table", "Expected client to be a table")
    assert(type(data) == "table", "Expected data to be a table")

    local self = setmetatable({}, Guild)

    self.Client = client
    self.Channels = {}
    self.Members = {}
    self.Roles = {}
    self.VoiceStates = {}
    self._data = data

    self:_patch(data)

    return self
end

function Guild._patch(self: Guild, data: Types.APIGuild)
    self.AfkChannelId = data.afk_channel_id
    self.AfkTimeout = data.afk_timeout
    self.ApplicationId = data.application_id
    self.ApproximateMemberCount = data.approximate_member_count
    self.ApproximatePresenceCount = data.approximate_presence_count
    self.Banner = data.banner
    self.DefaultMessageNotifications = data.default_message_notifications
    self.Description = data.description
    self.DiscoverySplash = data.discovery_splash
    self.ExplicitContentFilter = data.explicit_content_filter
    self.Features = data.features
    self.Icon = data.icon
    self.IconHash = data.icon_hash
    self.Id = data.id
    self.JoinedAt = data.joined_at
    self.Large = data.large or false
    self.MaxMembers = data.max_members
    self.MaxPresences = data.max_presences
    self.MaxVideoChannelUsers = data.max_video_channel_users
    self.MemberCount = data.member_count
    self.MfaLevel = data.mfa_level
    self.Name = data.name
    self.NsfwLevel = data.nsfw_level
    self.OwnerId = data.owner_id
    self.PreferredLocale = data.preferred_locale
    self.PremiumProgressBarEnabled = data.premium_progress_bar_enabled
    self.PremiumSubscriptionCount = data.premium_subscription_count
    self.PremiumTier = data.premium_tier
    self.PublicUpdatesChannelId = data.public_updates_channel_id
    self.RulesChannelId = data.rules_channel_id
    self.SafetyAlertsChannelId = data.safety_alerts_channel_id
    self.Splash = data.splash
    self.SystemChannelFlags = data.system_channel_flags
    self.SystemChannelId = data.system_channel_id
    self.Unavailable = data.unavailable or false
    self.VanityUrlCode = data.vanity_url_code
    self.VerificationLevel = data.verification_level
    self.WidgetChannelId = data.widget_channel_id
    self.WidgetEnabled = data.widget_enabled

    -- Process roles
    if data.roles then
        for _, roleData in data.roles do
            local role = Role.new(self.Client, self, roleData)
            self.Roles[role.Id] = role
        end
    end

    -- Process channels
    if data.channels then
        for _, channelData in data.channels do
            local channel = Channel.new(self.Client, channelData, self)
            self.Channels[channel.Id] = channel
        end
    end

    -- Process members
    if data.members then
        for _, memberData in data.members do
            local member = Member.new(self.Client, self, memberData)
            if member.User then
                self.Members[member.User.Id] = member
            end
        end
    end

    -- Process voice states
    if data.voice_states then
        for _, voiceStateData in data.voice_states do
            if voiceStateData.user_id then
                self.VoiceStates[voiceStateData.user_id] = voiceStateData
            end
        end
    end
end

function Guild.GetIconUrl(self: Guild, options: { format: string?, size: number? }?): string?
    if not self.Icon then
        return nil
    end

    local format = options and options.format or "webp"
    local size = options and options.size or 128

    local extension = if self.Icon:sub(1, 2) == "a_" then "gif" else format

    return `https://cdn.discordapp.com/icons/{self.Id}/{self.Icon}.{extension}?size={size}`
end

function Guild.GetBannerUrl(self: Guild, options: { format: string?, size: number? }?): string?
    if not self.Banner then
        return nil
    end

    local format = options and options.format or "webp"
    local size = options and options.size or 512

    local extension = if self.Banner:sub(1, 2) == "a_" then "gif" else format

    return `https://cdn.discordapp.com/banners/{self.Id}/{self.Banner}.{extension}?size={size}`
end

function Guild.GetSplashUrl(self: Guild, options: { format: string?, size: number? }?): string?
    if not self.Splash then
        return nil
    end

    local format = options and options.format or "webp"
    local size = options and options.size or 512

    return `https://cdn.discordapp.com/splashes/{self.Id}/{self.Splash}.{format}?size={size}`
end

function Guild.GetDiscoverySplashUrl(self: Guild, options: { format: string?, size: number? }?): string?
    if not self.DiscoverySplash then
        return nil
    end

    local format = options and options.format or "webp"
    local size = options and options.size or 512

    return `https://cdn.discordapp.com/discovery-splashes/{self.Id}/{self.DiscoverySplash}.{format}?size={size}`
end

function Guild.GetChannel(self: Guild, channelId: Types.Snowflake): Channel.Channel?
    return self.Channels[channelId]
end

function Guild.GetRole(self: Guild, roleId: Types.Snowflake): Role.Role?
    return self.Roles[roleId]
end

function Guild.GetMember(self: Guild, userId: Types.Snowflake): Member.Member?
    return self.Members[userId]
end

function Guild.GetEveryoneRole(self: Guild): Role.Role?
    return self.Roles[self.Id]
end

-- Voice state methods
function Guild.GetVoiceState(self: Guild, userId: Types.Snowflake): Types.APIVoiceState?
    return self.VoiceStates[userId]
end

function Guild.GetVoiceChannelMembers(self: Guild, channelId: Types.Snowflake): { Types.APIVoiceState }
    local members = {}
    for _, voiceState in self.VoiceStates do
        if voiceState.channel_id == channelId then
            table.insert(members, voiceState)
        end
    end
    return members
end

-- Moderation methods
function Guild.BanMember(
    self: Guild,
    userId: Types.Snowflake,
    options: { deleteMessageSeconds: number?, reason: string? }?
)
    assert(self.Client.Rest, "Client is not logged in")

    local apiOptions = nil
    if options and options.deleteMessageSeconds then
        apiOptions = { delete_message_seconds = options.deleteMessageSeconds }
    end

    self.Client.Rest:CreateGuildBan(self.Id, userId, apiOptions, options and options.reason)
end

function Guild.UnbanMember(self: Guild, userId: Types.Snowflake, reason: string?)
    assert(self.Client.Rest, "Client is not logged in")

    self.Client.Rest:RemoveGuildBan(self.Id, userId, reason)
end

function Guild.KickMember(self: Guild, userId: Types.Snowflake, reason: string?)
    assert(self.Client.Rest, "Client is not logged in")

    self.Client.Rest:RemoveGuildMember(self.Id, userId, reason)
end

function Guild.FetchMember(self: Guild, userId: Types.Snowflake): Member.Member
    assert(self.Client.Rest, "Client is not logged in")

    local data = self.Client.Rest:GetGuildMember(self.Id, userId)
    local member = Member.new(self.Client, self, data)
    if member.User then
        self.Members[member.User.Id] = member
    end

    return member
end

function Guild.FetchBans(self: Guild): { { reason: string?, user: Types.APIUser } }
    assert(self.Client.Rest, "Client is not logged in")

    return self.Client.Rest:GetGuildBans(self.Id)
end

function Guild.__tostring(self: Guild): string
    return `Guild({self.Id})`
end

return Guild
