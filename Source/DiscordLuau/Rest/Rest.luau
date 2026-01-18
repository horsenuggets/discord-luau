--[[

Rest

Discord REST API client for making HTTP requests to Discord endpoints. Handles
authentication, rate limiting, and request formatting.

--]]

local net = require("@lune/net")
local serde = require("@lune/serde")
local task = require("@lune/task")

local Types = require("../Structures/Types")

local API_VERSION = 10
local API_BASE_URL = `https://discord.com/api/v{API_VERSION}`
local _CDN_BASE_URL = "https://cdn.discordapp.com"

local Rest = {}
Rest.__index = Rest

export type Rest = typeof(setmetatable(
    {} :: {
        _client: Types.Client,
        _rateLimits: { [string]: { limit: number, remaining: number, reset: number } },
        _token: string,
    },
    Rest
))

function Rest.new(client: Types.Client, token: string): Rest
    assert(type(client) == "table", "Expected client to be a table")
    assert(type(token) == "string", "Expected token to be a string")

    local self = setmetatable({}, Rest)

    self._client = client
    self._rateLimits = {}
    self._token = token

    return self
end

function Rest._request(self: Rest, method: string, endpoint: string, body: { [string]: any }?, reason: string?): any
    local url = `{API_BASE_URL}{endpoint}`

    local headers: { [string]: string } = {
        ["Authorization"] = `Bot {self._token}`,
        ["Content-Type"] = "application/json",
        ["User-Agent"] = "DiscordLuau (https://github.com/horsenuggets/discord-luau, 0.0.0)",
    }

    if reason then
        headers["X-Audit-Log-Reason"] = reason
    end

    local response = net.request({
        body = body and serde.encode("json", body) or nil,
        headers = headers,
        method = method,
        url = url,
    })

    -- Parse rate limit headers
    local rateLimitBucket = response.headers["x-ratelimit-bucket"]
    if rateLimitBucket then
        self._rateLimits[rateLimitBucket] = {
            limit = tonumber(response.headers["x-ratelimit-limit"]) or 0,
            remaining = tonumber(response.headers["x-ratelimit-remaining"]) or 0,
            reset = tonumber(response.headers["x-ratelimit-reset"]) or 0,
        }
    end

    -- Handle rate limiting
    if response.statusCode == 429 then
        local retryAfter = tonumber(response.headers["retry-after"]) or 1
        warn(`Rate limited. Retrying after {retryAfter} seconds.`)
        task.wait(retryAfter)
        return self:_request(method, endpoint, body, reason)
    end

    -- Handle errors
    if not response.ok then
        local errorBody = response.body
        local success, decoded = pcall(function()
            return serde.decode("json", errorBody)
        end)

        if success and decoded then
            error(`Discord API error {response.statusCode}: {decoded.message or "Unknown error"}`)
        else
            error(`Discord API error {response.statusCode}: {errorBody}`)
        end
    end

    -- Parse response body
    if response.body and #response.body > 0 then
        local success, decoded = pcall(function()
            return serde.decode("json", response.body)
        end)

        if success then
            return decoded
        end
    end

    return nil
end

-- Channel endpoints
function Rest.GetChannel(self: Rest, channelId: Types.Snowflake): Types.APIChannel
    assert(type(channelId) == "string", "Expected channelId to be a string")

    return self:_request("GET", `/channels/{channelId}`)
end

function Rest.ModifyChannel(
    self: Rest,
    channelId: Types.Snowflake,
    data: { [string]: any },
    reason: string?
): Types.APIChannel
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(data) == "table", "Expected data to be a table")

    return self:_request("PATCH", `/channels/{channelId}`, data, reason)
end

function Rest.DeleteChannel(self: Rest, channelId: Types.Snowflake, reason: string?)
    assert(type(channelId) == "string", "Expected channelId to be a string")

    self:_request("DELETE", `/channels/{channelId}`, nil, reason)
end

-- Permission overwrite endpoints
function Rest.EditChannelPermissions(
    self: Rest,
    channelId: Types.Snowflake,
    overwriteId: Types.Snowflake,
    data: { allow: string?, deny: string?, type: number },
    reason: string?
)
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(overwriteId) == "string", "Expected overwriteId to be a string")
    assert(type(data) == "table", "Expected data to be a table")

    self:_request("PUT", `/channels/{channelId}/permissions/{overwriteId}`, data, reason)
end

function Rest.DeleteChannelPermission(
    self: Rest,
    channelId: Types.Snowflake,
    overwriteId: Types.Snowflake,
    reason: string?
)
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(overwriteId) == "string", "Expected overwriteId to be a string")

    self:_request("DELETE", `/channels/{channelId}/permissions/{overwriteId}`, nil, reason)
end

-- Message endpoints
function Rest.GetChannelMessages(
    self: Rest,
    channelId: Types.Snowflake,
    options: { after: string?, around: string?, before: string?, limit: number? }?
): { Types.APIMessage }
    assert(type(channelId) == "string", "Expected channelId to be a string")

    local query = ""
    if options then
        local params = {}
        if options.after then
            table.insert(params, `after={options.after}`)
        end
        if options.around then
            table.insert(params, `around={options.around}`)
        end
        if options.before then
            table.insert(params, `before={options.before}`)
        end
        if options.limit then
            table.insert(params, `limit={options.limit}`)
        end
        if #params > 0 then
            query = "?" .. table.concat(params, "&")
        end
    end

    return self:_request("GET", `/channels/{channelId}/messages{query}`)
end

function Rest.GetChannelMessage(self: Rest, channelId: Types.Snowflake, messageId: Types.Snowflake): Types.APIMessage
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(messageId) == "string", "Expected messageId to be a string")

    return self:_request("GET", `/channels/{channelId}/messages/{messageId}`)
end

function Rest.CreateMessage(self: Rest, channelId: Types.Snowflake, data: Types.MessageSendOptions): Types.APIMessage
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(data) == "table", "Expected data to be a table")

    return self:_request("POST", `/channels/{channelId}/messages`, data)
end

function Rest.EditMessage(
    self: Rest,
    channelId: Types.Snowflake,
    messageId: Types.Snowflake,
    data: Types.MessageSendOptions
): Types.APIMessage
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(messageId) == "string", "Expected messageId to be a string")
    assert(type(data) == "table", "Expected data to be a table")

    return self:_request("PATCH", `/channels/{channelId}/messages/{messageId}`, data)
end

function Rest.DeleteMessage(self: Rest, channelId: Types.Snowflake, messageId: Types.Snowflake, reason: string?)
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(messageId) == "string", "Expected messageId to be a string")

    self:_request("DELETE", `/channels/{channelId}/messages/{messageId}`, nil, reason)
end

function Rest.BulkDeleteMessages(
    self: Rest,
    channelId: Types.Snowflake,
    messageIds: { Types.Snowflake },
    reason: string?
)
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(messageIds) == "table", "Expected messageIds to be a table")
    assert(#messageIds >= 2 and #messageIds <= 100, "Must delete between 2 and 100 messages")

    self:_request("POST", `/channels/{channelId}/messages/bulk-delete`, { messages = messageIds }, reason)
end

function Rest.CrosspostMessage(self: Rest, channelId: Types.Snowflake, messageId: Types.Snowflake): Types.APIMessage
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(messageId) == "string", "Expected messageId to be a string")

    return self:_request("POST", `/channels/{channelId}/messages/{messageId}/crosspost`)
end

-- Reaction endpoints
function Rest.CreateReaction(self: Rest, channelId: Types.Snowflake, messageId: Types.Snowflake, emoji: string)
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(messageId) == "string", "Expected messageId to be a string")
    assert(type(emoji) == "string", "Expected emoji to be a string")

    -- URL encode the emoji
    local encodedEmoji = net.urlEncode(emoji)

    self:_request("PUT", `/channels/{channelId}/messages/{messageId}/reactions/{encodedEmoji}/@me`)
end

function Rest.DeleteOwnReaction(self: Rest, channelId: Types.Snowflake, messageId: Types.Snowflake, emoji: string)
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(messageId) == "string", "Expected messageId to be a string")
    assert(type(emoji) == "string", "Expected emoji to be a string")

    local encodedEmoji = net.urlEncode(emoji)

    self:_request("DELETE", `/channels/{channelId}/messages/{messageId}/reactions/{encodedEmoji}/@me`)
end

function Rest.DeleteUserReaction(
    self: Rest,
    channelId: Types.Snowflake,
    messageId: Types.Snowflake,
    emoji: string,
    userId: Types.Snowflake
)
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(messageId) == "string", "Expected messageId to be a string")
    assert(type(emoji) == "string", "Expected emoji to be a string")
    assert(type(userId) == "string", "Expected userId to be a string")

    local encodedEmoji = net.urlEncode(emoji)

    self:_request("DELETE", `/channels/{channelId}/messages/{messageId}/reactions/{encodedEmoji}/{userId}`)
end

function Rest.DeleteAllReactions(self: Rest, channelId: Types.Snowflake, messageId: Types.Snowflake)
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(messageId) == "string", "Expected messageId to be a string")

    self:_request("DELETE", `/channels/{channelId}/messages/{messageId}/reactions`)
end

function Rest.DeleteAllReactionsForEmoji(
    self: Rest,
    channelId: Types.Snowflake,
    messageId: Types.Snowflake,
    emoji: string
)
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(messageId) == "string", "Expected messageId to be a string")
    assert(type(emoji) == "string", "Expected emoji to be a string")

    local encodedEmoji = net.urlEncode(emoji)

    self:_request("DELETE", `/channels/{channelId}/messages/{messageId}/reactions/{encodedEmoji}`)
end

-- Pin endpoints
function Rest.PinMessage(self: Rest, channelId: Types.Snowflake, messageId: Types.Snowflake, reason: string?)
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(messageId) == "string", "Expected messageId to be a string")

    self:_request("PUT", `/channels/{channelId}/pins/{messageId}`, nil, reason)
end

function Rest.UnpinMessage(self: Rest, channelId: Types.Snowflake, messageId: Types.Snowflake, reason: string?)
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(messageId) == "string", "Expected messageId to be a string")

    self:_request("DELETE", `/channels/{channelId}/pins/{messageId}`, nil, reason)
end

function Rest.GetPinnedMessages(self: Rest, channelId: Types.Snowflake): { Types.APIMessage }
    assert(type(channelId) == "string", "Expected channelId to be a string")

    return self:_request("GET", `/channels/{channelId}/pins`)
end

-- Thread endpoints
function Rest.StartThreadFromMessage(
    self: Rest,
    channelId: Types.Snowflake,
    messageId: Types.Snowflake,
    name: string,
    options: { auto_archive_duration: number?, rate_limit_per_user: number? }?
): Types.APIChannel
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(messageId) == "string", "Expected messageId to be a string")
    assert(type(name) == "string", "Expected name to be a string")

    local data: { [string]: any } = { name = name }
    if options then
        if options.auto_archive_duration then
            data.auto_archive_duration = options.auto_archive_duration
        end
        if options.rate_limit_per_user then
            data.rate_limit_per_user = options.rate_limit_per_user
        end
    end

    return self:_request("POST", `/channels/{channelId}/messages/{messageId}/threads`, data)
end

function Rest.StartThreadWithoutMessage(
    self: Rest,
    channelId: Types.Snowflake,
    name: string,
    options: {
        auto_archive_duration: number?,
        invitable: boolean?,
        rate_limit_per_user: number?,
        type: number?,
    }?
): Types.APIChannel
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(type(name) == "string", "Expected name to be a string")

    local data: { [string]: any } = { name = name }
    if options then
        if options.auto_archive_duration then
            data.auto_archive_duration = options.auto_archive_duration
        end
        if options.invitable ~= nil then
            data.invitable = options.invitable
        end
        if options.rate_limit_per_user then
            data.rate_limit_per_user = options.rate_limit_per_user
        end
        if options.type then
            data.type = options.type
        end
    end

    return self:_request("POST", `/channels/{channelId}/threads`, data)
end

-- Guild endpoints
function Rest.GetGuild(self: Rest, guildId: Types.Snowflake, withCounts: boolean?): Types.APIGuild
    assert(type(guildId) == "string", "Expected guildId to be a string")

    local query = withCounts and "?with_counts=true" or ""

    return self:_request("GET", `/guilds/{guildId}{query}`)
end

function Rest.GetGuildChannels(self: Rest, guildId: Types.Snowflake): { Types.APIChannel }
    assert(type(guildId) == "string", "Expected guildId to be a string")

    return self:_request("GET", `/guilds/{guildId}/channels`)
end

function Rest.CreateGuildChannel(
    self: Rest,
    guildId: Types.Snowflake,
    data: { [string]: any },
    reason: string?
): Types.APIChannel
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(data) == "table", "Expected data to be a table")

    return self:_request("POST", `/guilds/{guildId}/channels`, data, reason)
end

function Rest.GetGuildMember(self: Rest, guildId: Types.Snowflake, userId: Types.Snowflake): Types.APIMember
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(userId) == "string", "Expected userId to be a string")

    return self:_request("GET", `/guilds/{guildId}/members/{userId}`)
end

function Rest.GetGuildMembers(
    self: Rest,
    guildId: Types.Snowflake,
    options: { after: string?, limit: number? }?
): { Types.APIMember }
    assert(type(guildId) == "string", "Expected guildId to be a string")

    local query = ""
    if options then
        local params = {}
        if options.after then
            table.insert(params, `after={options.after}`)
        end
        if options.limit then
            table.insert(params, `limit={options.limit}`)
        end
        if #params > 0 then
            query = "?" .. table.concat(params, "&")
        end
    end

    return self:_request("GET", `/guilds/{guildId}/members{query}`)
end

function Rest.ModifyGuildMember(
    self: Rest,
    guildId: Types.Snowflake,
    userId: Types.Snowflake,
    data: { [string]: any },
    reason: string?
): Types.APIMember
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(userId) == "string", "Expected userId to be a string")
    assert(type(data) == "table", "Expected data to be a table")

    return self:_request("PATCH", `/guilds/{guildId}/members/{userId}`, data, reason)
end

function Rest.AddGuildMemberRole(
    self: Rest,
    guildId: Types.Snowflake,
    userId: Types.Snowflake,
    roleId: Types.Snowflake,
    reason: string?
)
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(userId) == "string", "Expected userId to be a string")
    assert(type(roleId) == "string", "Expected roleId to be a string")

    self:_request("PUT", `/guilds/{guildId}/members/{userId}/roles/{roleId}`, nil, reason)
end

function Rest.RemoveGuildMemberRole(
    self: Rest,
    guildId: Types.Snowflake,
    userId: Types.Snowflake,
    roleId: Types.Snowflake,
    reason: string?
)
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(userId) == "string", "Expected userId to be a string")
    assert(type(roleId) == "string", "Expected roleId to be a string")

    self:_request("DELETE", `/guilds/{guildId}/members/{userId}/roles/{roleId}`, nil, reason)
end

function Rest.RemoveGuildMember(self: Rest, guildId: Types.Snowflake, userId: Types.Snowflake, reason: string?)
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(userId) == "string", "Expected userId to be a string")

    self:_request("DELETE", `/guilds/{guildId}/members/{userId}`, nil, reason)
end

function Rest.GetGuildBans(self: Rest, guildId: Types.Snowflake): { { reason: string?, user: Types.APIUser } }
    assert(type(guildId) == "string", "Expected guildId to be a string")

    return self:_request("GET", `/guilds/{guildId}/bans`)
end

function Rest.GetGuildBan(
    self: Rest,
    guildId: Types.Snowflake,
    userId: Types.Snowflake
): { reason: string?, user: Types.APIUser }
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(userId) == "string", "Expected userId to be a string")

    return self:_request("GET", `/guilds/{guildId}/bans/{userId}`)
end

function Rest.CreateGuildBan(
    self: Rest,
    guildId: Types.Snowflake,
    userId: Types.Snowflake,
    options: { delete_message_seconds: number? }?,
    reason: string?
)
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(userId) == "string", "Expected userId to be a string")

    self:_request("PUT", `/guilds/{guildId}/bans/{userId}`, options, reason)
end

function Rest.RemoveGuildBan(self: Rest, guildId: Types.Snowflake, userId: Types.Snowflake, reason: string?)
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(userId) == "string", "Expected userId to be a string")

    self:_request("DELETE", `/guilds/{guildId}/bans/{userId}`, nil, reason)
end

function Rest.GetGuildRoles(self: Rest, guildId: Types.Snowflake): { Types.APIRole }
    assert(type(guildId) == "string", "Expected guildId to be a string")

    return self:_request("GET", `/guilds/{guildId}/roles`)
end

function Rest.CreateGuildRole(
    self: Rest,
    guildId: Types.Snowflake,
    data: { [string]: any }?,
    reason: string?
): Types.APIRole
    assert(type(guildId) == "string", "Expected guildId to be a string")

    return self:_request("POST", `/guilds/{guildId}/roles`, data or {}, reason)
end

function Rest.ModifyGuildRole(
    self: Rest,
    guildId: Types.Snowflake,
    roleId: Types.Snowflake,
    data: { [string]: any },
    reason: string?
): Types.APIRole
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(roleId) == "string", "Expected roleId to be a string")
    assert(type(data) == "table", "Expected data to be a table")

    return self:_request("PATCH", `/guilds/{guildId}/roles/{roleId}`, data, reason)
end

function Rest.DeleteGuildRole(self: Rest, guildId: Types.Snowflake, roleId: Types.Snowflake, reason: string?)
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(roleId) == "string", "Expected roleId to be a string")

    self:_request("DELETE", `/guilds/{guildId}/roles/{roleId}`, nil, reason)
end

-- User endpoints
function Rest.GetCurrentUser(self: Rest): Types.APIUser
    return self:_request("GET", "/users/@me")
end

function Rest.GetUser(self: Rest, userId: Types.Snowflake): Types.APIUser
    assert(type(userId) == "string", "Expected userId to be a string")

    return self:_request("GET", `/users/{userId}`)
end

function Rest.ModifyCurrentUser(self: Rest, data: { avatar: string?, username: string? }): Types.APIUser
    assert(type(data) == "table", "Expected data to be a table")

    return self:_request("PATCH", "/users/@me", data)
end

function Rest.GetCurrentUserGuilds(self: Rest): { Types.APIGuild }
    return self:_request("GET", "/users/@me/guilds")
end

function Rest.LeaveGuild(self: Rest, guildId: Types.Snowflake)
    assert(type(guildId) == "string", "Expected guildId to be a string")

    self:_request("DELETE", `/users/@me/guilds/{guildId}`)
end

function Rest.CreateDM(self: Rest, recipientId: Types.Snowflake): Types.APIChannel
    assert(type(recipientId) == "string", "Expected recipientId to be a string")

    return self:_request("POST", "/users/@me/channels", { recipient_id = recipientId })
end

-- Application command endpoints
function Rest.GetGlobalApplicationCommands(self: Rest, applicationId: Types.Snowflake): { Types.APIApplicationCommand }
    assert(type(applicationId) == "string", "Expected applicationId to be a string")

    return self:_request("GET", `/applications/{applicationId}/commands`)
end

function Rest.CreateGlobalApplicationCommand(
    self: Rest,
    applicationId: Types.Snowflake,
    data: { [string]: any }
): Types.APIApplicationCommand
    assert(type(applicationId) == "string", "Expected applicationId to be a string")
    assert(type(data) == "table", "Expected data to be a table")

    return self:_request("POST", `/applications/{applicationId}/commands`, data)
end

function Rest.BulkOverwriteGlobalApplicationCommands(
    self: Rest,
    applicationId: Types.Snowflake,
    commands: { { [string]: any } }
): { Types.APIApplicationCommand }
    assert(type(applicationId) == "string", "Expected applicationId to be a string")
    assert(type(commands) == "table", "Expected commands to be a table")

    return self:_request("PUT", `/applications/{applicationId}/commands`, commands)
end

function Rest.DeleteGlobalApplicationCommand(self: Rest, applicationId: Types.Snowflake, commandId: Types.Snowflake)
    assert(type(applicationId) == "string", "Expected applicationId to be a string")
    assert(type(commandId) == "string", "Expected commandId to be a string")

    self:_request("DELETE", `/applications/{applicationId}/commands/{commandId}`)
end

function Rest.GetGuildApplicationCommands(
    self: Rest,
    applicationId: Types.Snowflake,
    guildId: Types.Snowflake
): { Types.APIApplicationCommand }
    assert(type(applicationId) == "string", "Expected applicationId to be a string")
    assert(type(guildId) == "string", "Expected guildId to be a string")

    return self:_request("GET", `/applications/{applicationId}/guilds/{guildId}/commands`)
end

function Rest.CreateGuildApplicationCommand(
    self: Rest,
    applicationId: Types.Snowflake,
    guildId: Types.Snowflake,
    data: { [string]: any }
): Types.APIApplicationCommand
    assert(type(applicationId) == "string", "Expected applicationId to be a string")
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(data) == "table", "Expected data to be a table")

    return self:_request("POST", `/applications/{applicationId}/guilds/{guildId}/commands`, data)
end

function Rest.BulkOverwriteGuildApplicationCommands(
    self: Rest,
    applicationId: Types.Snowflake,
    guildId: Types.Snowflake,
    commands: { { [string]: any } }
): { Types.APIApplicationCommand }
    assert(type(applicationId) == "string", "Expected applicationId to be a string")
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(commands) == "table", "Expected commands to be a table")

    return self:_request("PUT", `/applications/{applicationId}/guilds/{guildId}/commands`, commands)
end

function Rest.DeleteGuildApplicationCommand(
    self: Rest,
    applicationId: Types.Snowflake,
    guildId: Types.Snowflake,
    commandId: Types.Snowflake
)
    assert(type(applicationId) == "string", "Expected applicationId to be a string")
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(commandId) == "string", "Expected commandId to be a string")

    self:_request("DELETE", `/applications/{applicationId}/guilds/{guildId}/commands/{commandId}`)
end

-- Interaction response endpoints
function Rest.CreateInteractionResponse(
    self: Rest,
    interactionId: Types.Snowflake,
    interactionToken: string,
    data: { [string]: any }
)
    assert(type(interactionId) == "string", "Expected interactionId to be a string")
    assert(type(interactionToken) == "string", "Expected interactionToken to be a string")
    assert(type(data) == "table", "Expected data to be a table")

    -- Interaction responses use a different base URL (no /api/v10)
    local url = `https://discord.com/api/v{API_VERSION}/interactions/{interactionId}/{interactionToken}/callback`

    local response = net.request({
        body = serde.encode("json", data),
        headers = {
            ["Content-Type"] = "application/json",
            ["User-Agent"] = "DiscordLuau (https://github.com/horsenuggets/discord-luau, 0.0.0)",
        },
        method = "POST",
        url = url,
    })

    if not response.ok then
        error(`Discord API error {response.statusCode}: {response.body}`)
    end
end

function Rest.EditOriginalInteractionResponse(
    self: Rest,
    applicationId: Types.Snowflake,
    interactionToken: string,
    data: { [string]: any }
): Types.APIMessage
    assert(type(applicationId) == "string", "Expected applicationId to be a string")
    assert(type(interactionToken) == "string", "Expected interactionToken to be a string")
    assert(type(data) == "table", "Expected data to be a table")

    return self:_request("PATCH", `/webhooks/{applicationId}/{interactionToken}/messages/@original`, data)
end

function Rest.DeleteOriginalInteractionResponse(self: Rest, applicationId: Types.Snowflake, interactionToken: string)
    assert(type(applicationId) == "string", "Expected applicationId to be a string")
    assert(type(interactionToken) == "string", "Expected interactionToken to be a string")

    self:_request("DELETE", `/webhooks/{applicationId}/{interactionToken}/messages/@original`)
end

function Rest.CreateFollowupMessage(
    self: Rest,
    applicationId: Types.Snowflake,
    interactionToken: string,
    data: Types.MessageSendOptions
): Types.APIMessage
    assert(type(applicationId) == "string", "Expected applicationId to be a string")
    assert(type(interactionToken) == "string", "Expected interactionToken to be a string")
    assert(type(data) == "table", "Expected data to be a table")

    return self:_request("POST", `/webhooks/{applicationId}/{interactionToken}`, data)
end

-- Gateway endpoints
function Rest.GetGateway(self: Rest): { url: string }
    return self:_request("GET", "/gateway")
end

function Rest.GetGatewayBot(self: Rest): { session_start_limit: { [string]: number }, shards: number, url: string }
    return self:_request("GET", "/gateway/bot")
end

return Rest
