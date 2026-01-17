--[[

User

Represents a Discord user. Contains user information like username, avatar, and flags.

--]]

local Types = require("@self/Types")

local User = {}
User.__index = User

export type User = typeof(setmetatable(
    {} :: {
        AccentColor: number?,
        Avatar: string?,
        AvatarDecorationData: { asset: string, sku_id: string }?,
        Banner: string?,
        Bot: boolean,
        Client: Types.Client,
        Discriminator: string,
        GlobalName: string?,
        Id: Types.Snowflake,
        PublicFlags: number,
        System: boolean,
        Username: string,
        _data: Types.APIUser,
    },
    User
))

function User.new(client: Types.Client, data: Types.APIUser): User
    assert(type(client) == "table", "Expected client to be a table")
    assert(type(data) == "table", "Expected data to be a table")

    local self = setmetatable({}, User)

    self.Client = client
    self._data = data

    self:_patch(data)

    return self
end

function User._patch(self: User, data: Types.APIUser)
    self.AccentColor = data.accent_color
    self.Avatar = data.avatar
    self.AvatarDecorationData = data.avatar_decoration_data
    self.Banner = data.banner
    self.Bot = data.bot or false
    self.Discriminator = data.discriminator
    self.GlobalName = data.global_name
    self.Id = data.id
    self.PublicFlags = data.public_flags or 0
    self.System = data.system or false
    self.Username = data.username
end

function User.GetAvatarUrl(self: User, options: { format: string?, size: number? }?): string?
    if not self.Avatar then
        return nil
    end

    local format = options and options.format or "webp"
    local size = options and options.size or 128

    local extension = if self.Avatar:sub(1, 2) == "a_" then "gif" else format

    return `https://cdn.discordapp.com/avatars/{self.Id}/{self.Avatar}.{extension}?size={size}`
end

function User.GetDefaultAvatarUrl(self: User): string
    -- For users with new username system (discriminator "0"), use (userId >> 22) % 6
    -- For legacy users, use discriminator % 5
    local index: number
    if self.Discriminator == "0" then
        index = bit32.rshift(tonumber(self.Id) or 0, 22) % 6
    else
        index = (tonumber(self.Discriminator) or 0) % 5
    end

    return `https://cdn.discordapp.com/embed/avatars/{index}.png`
end

function User.GetDisplayAvatarUrl(self: User, options: { format: string?, size: number? }?): string
    return self:GetAvatarUrl(options) or self:GetDefaultAvatarUrl()
end

function User.GetBannerUrl(self: User, options: { format: string?, size: number? }?): string?
    if not self.Banner then
        return nil
    end

    local format = options and options.format or "webp"
    local size = options and options.size or 512

    local extension = if self.Banner:sub(1, 2) == "a_" then "gif" else format

    return `https://cdn.discordapp.com/banners/{self.Id}/{self.Banner}.{extension}?size={size}`
end

function User.GetTag(self: User): string
    if self.Discriminator == "0" then
        return self.Username
    else
        return `{self.Username}#{self.Discriminator}`
    end
end

function User.GetDisplayName(self: User): string
    return self.GlobalName or self.Username
end

function User.ToString(self: User): string
    return `<@{self.Id}>`
end

function User.__tostring(self: User): string
    return `User({self.Id})`
end

return User
