--[[

Member

Represents a guild member, which is a user within a specific guild. Contains guild-specific
information like nickname, roles, and join date.

--]]

local Types = require("@self/Types")
local User = require("@self/User")

local Member = {}
Member.__index = Member

export type Member = typeof(setmetatable(
    {} :: {
        Avatar: string?,
        Client: Types.Client,
        CommunicationDisabledUntil: string?,
        Deaf: boolean,
        Flags: number,
        Guild: Types.Guild,
        GuildId: Types.Snowflake,
        JoinedAt: string,
        Mute: boolean,
        Nick: string?,
        Pending: boolean,
        Permissions: string?,
        PremiumSince: string?,
        Roles: { Types.Snowflake },
        User: User.User?,
        _data: Types.APIMember,
    },
    Member
))

function Member.new(client: Types.Client, guild: Types.Guild, data: Types.APIMember): Member
    assert(type(client) == "table", "Expected client to be a table")
    assert(type(guild) == "table", "Expected guild to be a table")
    assert(type(data) == "table", "Expected data to be a table")

    local self = setmetatable({}, Member)

    self.Client = client
    self.Guild = guild
    self.GuildId = guild.Id
    self._data = data

    self:_patch(data)

    return self
end

function Member._patch(self: Member, data: Types.APIMember)
    self.Avatar = data.avatar
    self.CommunicationDisabledUntil = data.communication_disabled_until
    self.Deaf = data.deaf
    self.Flags = data.flags
    self.JoinedAt = data.joined_at
    self.Mute = data.mute
    self.Nick = data.nick
    self.Pending = data.pending or false
    self.Permissions = data.permissions
    self.PremiumSince = data.premium_since
    self.Roles = data.roles

    if data.user then
        self.User = User.new(self.Client, data.user)
    end
end

function Member.GetDisplayName(self: Member): string
    if self.Nick then
        return self.Nick
    elseif self.User then
        return self.User:GetDisplayName()
    else
        return "Unknown"
    end
end

function Member.GetAvatarUrl(self: Member, options: { format: string?, size: number? }?): string?
    if not self.Avatar then
        return nil
    end

    local format = options and options.format or "webp"
    local size = options and options.size or 128

    local extension = if self.Avatar:sub(1, 2) == "a_" then "gif" else format

    return `https://cdn.discordapp.com/guilds/{self.GuildId}/users/{self.User and self.User.Id or "0"}/avatars/{self.Avatar}.{extension}?size={size}`
end

function Member.GetDisplayAvatarUrl(self: Member, options: { format: string?, size: number? }?): string
    local guildAvatar = self:GetAvatarUrl(options)
    if guildAvatar then
        return guildAvatar
    end

    if self.User then
        return self.User:GetDisplayAvatarUrl(options)
    end

    return "https://cdn.discordapp.com/embed/avatars/0.png"
end

function Member.HasPermission(self: Member, permission: number): boolean
    if not self.Permissions then
        return false
    end

    local permissions = tonumber(self.Permissions) or 0

    -- Administrator has all permissions
    if bit32.band(permissions, bit32.lshift(1, 3)) ~= 0 then
        return true
    end

    return bit32.band(permissions, permission) ~= 0
end

function Member.IsTimedOut(self: Member): boolean
    if not self.CommunicationDisabledUntil then
        return false
    end

    -- Parse ISO timestamp and compare with current time
    -- For now, just check if the field exists
    return true
end

function Member.ToString(self: Member): string
    if self.User then
        return `<@{self.User.Id}>`
    end
    return "<@0>"
end

function Member.__tostring(self: Member): string
    local userId = self.User and self.User.Id or "unknown"
    return `Member({userId} in {self.GuildId})`
end

return Member
