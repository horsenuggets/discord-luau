--[[

MockClient

Provides a mock Discord client for testing without making real API calls. Includes a mock
REST API and mock Gateway that can be configured to return specific responses.

--]]

local MockData = require("./MockData")

local MockClient = {}

-- Create a minimal mock client that doesn't require real connections
function MockClient.new()
    local client = {
        -- Core properties
        User = nil,
        Application = nil,
        Guilds = {},
        Channels = {},
        Users = {},
        ReadyAt = nil,

        -- Internal properties
        _eventHandlers = {},
        _intents = 0,
        _token = "mock_token",
        _createMessage = nil,

        -- Mock REST API
        Rest = MockClient.createMockRest(),

        -- Mock Gateway
        Gateway = nil,
    }

    -- Set up message factory
    client._createMessage = function(data, _channel)
        return { _data = data, Id = data.id, Content = data.content }
    end

    return client
end

-- Create a mock client with pre-populated data
function MockClient.newWithData()
    local client = MockClient.new()

    -- Populate with mock data
    client.User = MockClient.createMockUser(MockData.BotUser)
    client.Application = MockData.Application
    client.ReadyAt = os.time()

    -- Add mock guild
    local guild = MockClient.createMockGuild(MockData.Guild)
    client.Guilds[MockData.Snowflakes.GuildId] = guild

    -- Add mock channel
    local channel = MockClient.createMockChannel(MockData.TextChannel, client)
    client.Channels[MockData.Snowflakes.ChannelId] = channel
    guild.Channels[MockData.Snowflakes.ChannelId] = channel

    -- Add mock users
    client.Users[MockData.Snowflakes.BotUserId] = client.User
    client.Users[MockData.Snowflakes.UserId] = MockClient.createMockUser(MockData.User)

    -- Add helper methods
    function client:GetGuild(guildId)
        assert(type(guildId) == "string", "Expected guildId to be a string")
        return self.Guilds[guildId]
    end

    function client:GetChannel(channelId)
        assert(type(channelId) == "string", "Expected channelId to be a string")
        return self.Channels[channelId]
    end

    function client:GetUser(userId)
        assert(type(userId) == "string", "Expected userId to be a string")
        return self.Users[userId]
    end

    function client:IsReady()
        return self.ReadyAt ~= nil
    end

    function client:GetUptime()
        if self.ReadyAt then
            return os.time() - self.ReadyAt
        end
        return nil
    end

    function client:On(eventName, handler)
        assert(type(eventName) == "string", "Expected eventName to be a string")
        assert(type(handler) == "function", "Expected handler to be a function")
        if not self._eventHandlers[eventName] then
            self._eventHandlers[eventName] = {}
        end
        table.insert(self._eventHandlers[eventName], handler)
        return function()
            for i, h in self._eventHandlers[eventName] do
                if h == handler then
                    table.remove(self._eventHandlers[eventName], i)
                    break
                end
            end
        end
    end

    function client:Destroy()
        self.User = nil
        self.Rest = nil
        self.ReadyAt = nil
        table.clear(self.Guilds)
        table.clear(self.Channels)
        table.clear(self.Users)
        table.clear(self._eventHandlers)
    end

    -- Set up metatable for __tostring
    setmetatable(client, {
        __tostring = function(self)
            if self.User then
                return `Client({self.User:GetTag()})`
            end
            return "Client(not logged in)"
        end,
    })

    return client
end

-- Create a mock REST API
function MockClient.createMockRest()
    local rest = {
        _responses = {},
        _calls = {},
    }

    -- Configure a mock response for an endpoint
    function rest:setResponse(method, endpoint, response)
        local key = `{method}:{endpoint}`
        self._responses[key] = response
    end

    -- Get recorded calls
    function rest:getCalls()
        return self._calls
    end

    -- Clear recorded calls
    function rest:clearCalls()
        self._calls = {}
    end

    -- Mock request method
    function rest:_request(method, endpoint, body, _reason)
        local key = `{method}:{endpoint}`
        table.insert(self._calls, { method = method, endpoint = endpoint, body = body })

        if self._responses[key] then
            return self._responses[key]
        end

        -- Default responses for common endpoints
        if string.match(endpoint, "^/channels/%d+/messages$") and method == "POST" then
            return MockData.Message
        elseif string.match(endpoint, "^/channels/%d+$") and method == "GET" then
            return MockData.TextChannel
        elseif string.match(endpoint, "^/guilds/%d+$") and method == "GET" then
            return MockData.Guild
        elseif string.match(endpoint, "^/users/%d+$") and method == "GET" then
            return MockData.User
        elseif string.match(endpoint, "^/users/@me$") and method == "GET" then
            return MockData.BotUser
        end

        return nil
    end

    -- Mock specific REST methods
    function rest:CreateMessage(channelId, body)
        return self:_request("POST", `/channels/{channelId}/messages`, body)
    end

    function rest:EditMessage(channelId, messageId, body)
        local response = MockData.Message
        if body.content then
            response = table.clone(MockData.Message)
            response.content = body.content
            response.edited_timestamp = "2024-01-15T12:05:00.000Z"
        end
        self:_request("PATCH", `/channels/{channelId}/messages/{messageId}`, body)
        return response
    end

    function rest:DeleteMessage(channelId, messageId)
        self:_request("DELETE", `/channels/{channelId}/messages/{messageId}`)
    end

    function rest:CreateReaction(channelId, messageId, emoji)
        self:_request("PUT", `/channels/{channelId}/messages/{messageId}/reactions/{emoji}/@me`)
    end

    function rest:DeleteOwnReaction(channelId, messageId, emoji)
        self:_request("DELETE", `/channels/{channelId}/messages/{messageId}/reactions/{emoji}/@me`)
    end

    function rest:DeleteUserReaction(channelId, messageId, emoji, userId)
        self:_request("DELETE", `/channels/{channelId}/messages/{messageId}/reactions/{emoji}/{userId}`)
    end

    function rest:GetChannel(channelId)
        return self:_request("GET", `/channels/{channelId}`)
    end

    function rest:GetGuild(guildId)
        return self:_request("GET", `/guilds/{guildId}`)
    end

    function rest:GetUser(userId)
        return self:_request("GET", `/users/{userId}`)
    end

    function rest:GetCurrentUser()
        return self:_request("GET", "/users/@me")
    end

    function rest:CreateInteractionResponse(interactionId, interactionToken, body)
        self:_request("POST", `/interactions/{interactionId}/{interactionToken}/callback`, body)
    end

    function rest:EditOriginalInteractionResponse(applicationId, interactionToken, body)
        self:_request("PATCH", `/webhooks/{applicationId}/{interactionToken}/messages/@original`, body)
    end

    function rest:DeleteOriginalInteractionResponse(applicationId, interactionToken)
        self:_request("DELETE", `/webhooks/{applicationId}/{interactionToken}/messages/@original`)
    end

    function rest:CreateFollowupMessage(applicationId, interactionToken, body)
        self:_request("POST", `/webhooks/{applicationId}/{interactionToken}`, body)
    end

    function rest:GetGlobalApplicationCommands(applicationId)
        return self:_request("GET", `/applications/{applicationId}/commands`) or {}
    end

    function rest:BulkOverwriteGlobalApplicationCommands(applicationId, commands)
        self:_request("PUT", `/applications/{applicationId}/commands`, commands)
        -- Return commands with IDs
        local result = {}
        for i, cmd in commands do
            local cmdWithId = table.clone(cmd)
            cmdWithId.id = tostring(100000000000000000 + i)
            table.insert(result, cmdWithId)
        end
        return result
    end

    function rest:PinMessage(channelId, messageId)
        self:_request("PUT", `/channels/{channelId}/pins/{messageId}`)
    end

    function rest:UnpinMessage(channelId, messageId)
        self:_request("DELETE", `/channels/{channelId}/pins/{messageId}`)
    end

    return rest
end

-- Create a mock user object
function MockClient.createMockUser(data)
    return {
        _data = data,
        Id = data.id,
        Username = data.username,
        Discriminator = data.discriminator,
        GlobalName = data.global_name,
        Avatar = data.avatar,
        Bot = data.bot or false,
        System = data.system or false,
        MfaEnabled = data.mfa_enabled,
        Banner = data.banner,
        AccentColor = data.accent_color,
        Locale = data.locale,
        Verified = data.verified,
        Email = data.email,
        Flags = data.flags,
        PremiumType = data.premium_type,
        PublicFlags = data.public_flags,

        GetTag = function(self)
            if self.Discriminator == "0" then
                return self.Username
            end
            return `{self.Username}#{self.Discriminator}`
        end,

        GetAvatarUrl = function(self, options)
            if not self.Avatar then
                return nil
            end
            local format = options and options.format or "webp"
            local size = options and options.size or 128
            return `https://cdn.discordapp.com/avatars/{self.Id}/{self.Avatar}.{format}?size={size}`
        end,

        GetDisplayAvatarUrl = function(self, options)
            local avatarUrl = self:GetAvatarUrl(options)
            if avatarUrl then
                return avatarUrl
            end
            local index = (tonumber(self.Id) :: number) % 5
            return `https://cdn.discordapp.com/embed/avatars/{index}.png`
        end,

        ToString = function(self)
            return `<@{self.Id}>`
        end,
    }
end

-- Create a mock guild object
function MockClient.createMockGuild(data)
    return {
        _data = data,
        Id = data.id,
        Name = data.name,
        Icon = data.icon,
        OwnerId = data.owner_id,
        Permissions = data.permissions,
        AfkTimeout = data.afk_timeout,
        VerificationLevel = data.verification_level,
        DefaultMessageNotifications = data.default_message_notifications,
        ExplicitContentFilter = data.explicit_content_filter,
        Features = data.features,
        MfaLevel = data.mfa_level,
        SystemChannelId = data.system_channel_id,
        PremiumTier = data.premium_tier,
        PremiumSubscriptionCount = data.premium_subscription_count,
        PreferredLocale = data.preferred_locale,
        NsfwLevel = data.nsfw_level,
        Description = data.description,
        Channels = {},
        Roles = {},
        Members = {},

        GetIconUrl = function(self, options)
            if not self.Icon then
                return nil
            end
            local format = options and options.format or "webp"
            local size = options and options.size or 128
            return `https://cdn.discordapp.com/icons/{self.Id}/{self.Icon}.{format}?size={size}`
        end,
    }
end

-- Create a mock channel object
function MockClient.createMockChannel(data, client)
    local channel = {
        _data = data,
        Client = client,
        Id = data.id,
        Type = data.type,
        GuildId = data.guild_id,
        Position = data.position,
        Name = data.name,
        Topic = data.topic,
        Nsfw = data.nsfw or false,
        LastMessageId = data.last_message_id,
        Bitrate = data.bitrate,
        UserLimit = data.user_limit,
        RateLimitPerUser = data.rate_limit_per_user,
        ParentId = data.parent_id,

        IsText = function(self)
            local textTypes = { [0] = true, [1] = true, [3] = true, [5] = true, [10] = true, [11] = true, [12] = true }
            return textTypes[self.Type] == true
        end,

        IsVoice = function(self)
            return self.Type == 2 or self.Type == 13
        end,

        IsDM = function(self)
            return self.Type == 1 or self.Type == 3
        end,

        Send = function(self, options)
            assert(self:IsText(), "Cannot send messages to non-text channels")
            local body
            if type(options) == "string" then
                body = { content = options }
            else
                body = options
            end
            local messageData = self.Client.Rest:CreateMessage(self.Id, body)
            return MockClient.createMockMessage(messageData, client, self)
        end,

        GetUrl = function(self)
            if self.GuildId then
                return `https://discord.com/channels/{self.GuildId}/{self.Id}`
            else
                return `https://discord.com/channels/@me/{self.Id}`
            end
        end,

        ToString = function(self)
            return `<#{self.Id}>`
        end,
    }
    return channel
end

-- Create a mock message object
function MockClient.createMockMessage(data, client, channel)
    return {
        _data = data,
        Client = client,
        Channel = channel,
        Id = data.id,
        ChannelId = data.channel_id,
        Content = data.content,
        Author = MockClient.createMockUser(data.author),
        Timestamp = data.timestamp,
        EditedTimestamp = data.edited_timestamp,
        Tts = data.tts,
        MentionEveryone = data.mention_everyone,
        Attachments = data.attachments,
        Embeds = data.embeds,
        Pinned = data.pinned,
        Type = data.type,
        Flags = data.flags,
        MessageReference = data.message_reference,
        ReferencedMessage = data.referenced_message,

        Reply = function(self, options)
            local body
            if type(options) == "string" then
                body = { content = options }
            else
                body = options
            end
            body.message_reference = {
                message_id = self.Id,
                channel_id = self.ChannelId,
            }
            return client.Rest:CreateMessage(self.ChannelId, body)
        end,

        Edit = function(self, options)
            local body
            if type(options) == "string" then
                body = { content = options }
            else
                body = options
            end
            return client.Rest:EditMessage(self.ChannelId, self.Id, body)
        end,

        Delete = function(self)
            client.Rest:DeleteMessage(self.ChannelId, self.Id)
        end,

        React = function(self, emoji)
            client.Rest:CreateReaction(self.ChannelId, self.Id, emoji)
        end,

        RemoveReaction = function(self, emoji, userId)
            if userId then
                client.Rest:DeleteUserReaction(self.ChannelId, self.Id, emoji, userId)
            else
                client.Rest:DeleteOwnReaction(self.ChannelId, self.Id, emoji)
            end
        end,

        Pin = function(self)
            client.Rest:PinMessage(self.ChannelId, self.Id)
        end,

        Unpin = function(self)
            client.Rest:UnpinMessage(self.ChannelId, self.Id)
        end,

        GetUrl = function(self)
            if self.GuildId then
                return `https://discord.com/channels/{self.GuildId}/{self.ChannelId}/{self.Id}`
            else
                return `https://discord.com/channels/@me/{self.ChannelId}/{self.Id}`
            end
        end,

        IsFromBot = function(self)
            return self.Author.Bot
        end,

        IsReply = function(self)
            return self.Type == 19 or self.MessageReference ~= nil
        end,

        IsPinned = function(self)
            return self.Pinned
        end,

        HasEmbeds = function(self)
            return #self.Embeds > 0
        end,

        HasAttachments = function(self)
            return #self.Attachments > 0
        end,
    }
end

-- Create a mock member object
function MockClient.createMockMember(data, guild)
    return {
        _data = data,
        Guild = guild,
        GuildId = guild.Id,
        User = data.user and MockClient.createMockUser(data.user) or nil,
        Nick = data.nick,
        Avatar = data.avatar,
        Roles = data.roles,
        JoinedAt = data.joined_at,
        PremiumSince = data.premium_since,
        Deaf = data.deaf,
        Mute = data.mute,
        Flags = data.flags,
        Pending = data.pending,
        Permissions = data.permissions,
        CommunicationDisabledUntil = data.communication_disabled_until,

        GetDisplayName = function(self)
            return self.Nick or (self.User and self.User.GlobalName) or (self.User and self.User.Username) or "Unknown"
        end,

        GetDisplayAvatarUrl = function(self, options)
            if self.Avatar then
                local format = options and options.format or "webp"
                local size = options and options.size or 128
                return `https://cdn.discordapp.com/guilds/{self.GuildId}/users/{self.User.Id}/avatars/{self.Avatar}.{format}?size={size}`
            end
            if self.User then
                return self.User:GetDisplayAvatarUrl(options)
            end
            return nil
        end,

        HasRole = function(self, roleId)
            for _, id in self.Roles do
                if id == roleId then
                    return true
                end
            end
            return false
        end,

        ToString = function(self)
            return `<@{self.User.Id}>`
        end,
    }
end

-- Create a mock role object
function MockClient.createMockRole(data, guild)
    return {
        _data = data,
        Guild = guild,
        Id = data.id,
        Name = data.name,
        Color = data.color,
        Hoist = data.hoist,
        Icon = data.icon,
        UnicodeEmoji = data.unicode_emoji,
        Position = data.position,
        Permissions = data.permissions,
        Managed = data.managed,
        Mentionable = data.mentionable,
        Tags = data.tags,
        Flags = data.flags,

        GetHexColor = function(self)
            return string.format("#%06X", self.Color)
        end,

        ToString = function(self)
            return `<@&{self.Id}>`
        end,

        ComparePositions = function(self, other)
            if self.Position > other.Position then
                return 1
            elseif self.Position < other.Position then
                return -1
            else
                return 0
            end
        end,
    }
end

return MockClient
