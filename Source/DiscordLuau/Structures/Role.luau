--[[

Role

Represents a guild role with permissions, color, and position settings.

--]]

local Types = require("@self/Types")

local Role = {}
Role.__index = Role

export type Role = typeof(setmetatable(
    {} :: {
        Client: Types.Client,
        Color: number,
        Guild: Types.Guild,
        GuildId: Types.Snowflake,
        Hoist: boolean,
        Icon: string?,
        Id: Types.Snowflake,
        Managed: boolean,
        Mentionable: boolean,
        Name: string,
        Permissions: string,
        Position: number,
        Tags: {
            available_for_purchase: boolean?,
            bot_id: Types.Snowflake?,
            guild_connections: boolean?,
            integration_id: Types.Snowflake?,
            premium_subscriber: boolean?,
            subscription_listing_id: Types.Snowflake?,
        }?,
        UnicodeEmoji: string?,
        _data: Types.APIRole,
    },
    Role
))

function Role.new(client: Types.Client, guild: Types.Guild, data: Types.APIRole): Role
    assert(type(client) == "table", "Expected client to be a table")
    assert(type(guild) == "table", "Expected guild to be a table")
    assert(type(data) == "table", "Expected data to be a table")

    local self = setmetatable({}, Role)

    self.Client = client
    self.Guild = guild
    self.GuildId = guild.Id
    self._data = data

    self:_patch(data)

    return self
end

function Role._patch(self: Role, data: Types.APIRole)
    self.Color = data.color
    self.Hoist = data.hoist
    self.Icon = data.icon
    self.Id = data.id
    self.Managed = data.managed
    self.Mentionable = data.mentionable
    self.Name = data.name
    self.Permissions = data.permissions
    self.Position = data.position
    self.Tags = data.tags
    self.UnicodeEmoji = data.unicode_emoji
end

function Role.GetIconUrl(self: Role, options: { format: string?, size: number? }?): string?
    if not self.Icon then
        return nil
    end

    local format = options and options.format or "webp"
    local size = options and options.size or 64

    return `https://cdn.discordapp.com/role-icons/{self.Id}/{self.Icon}.{format}?size={size}`
end

function Role.GetHexColor(self: Role): string
    return string.format("#%06X", self.Color)
end

function Role.HasPermission(self: Role, permission: number): boolean
    local permissions = tonumber(self.Permissions) or 0

    -- Administrator has all permissions
    if bit32.band(permissions, bit32.lshift(1, 3)) ~= 0 then
        return true
    end

    return bit32.band(permissions, permission) ~= 0
end

function Role.IsEveryone(self: Role): boolean
    return self.Id == self.GuildId
end

function Role.IsBotRole(self: Role): boolean
    return self.Tags ~= nil and self.Tags.bot_id ~= nil
end

function Role.IsBoosterRole(self: Role): boolean
    return self.Tags ~= nil and self.Tags.premium_subscriber == true
end

function Role.ComparePositionTo(self: Role, other: Role): number
    if self.Position > other.Position then
        return 1
    elseif self.Position < other.Position then
        return -1
    else
        -- If same position, compare by ID (lower ID = created first = higher priority)
        local selfId = tonumber(self.Id) or 0
        local otherId = tonumber(other.Id) or 0

        if selfId < otherId then
            return 1
        elseif selfId > otherId then
            return -1
        else
            return 0
        end
    end
end

function Role.ToString(self: Role): string
    return `<@&{self.Id}>`
end

function Role.__tostring(self: Role): string
    return `Role({self.Id})`
end

return Role
