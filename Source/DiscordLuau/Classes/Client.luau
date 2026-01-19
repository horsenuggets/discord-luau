--[[

Client

The main Discord client class. Handles connection to Discord, event management, and provides
access to guilds, channels, users, and other Discord resources.

--]]

local task = require("@lune/task")

local Channel = require("../Structures/Channel")
local Gateway = require("../Gateway")
local GatewayIntent = require("../Enums/GatewayIntent")
local Guild = require("../Structures/Guild")
local Interaction = require("../Structures/Interaction")
local Member = require("../Structures/Member")
local Message = require("../Structures/Message")
local Rest = require("../Rest")
local Types = require("../Structures/Types")
local User = require("../Structures/User")
local VoiceState = require("../Structures/VoiceState")

--[=[
    @class Client
    @tag class

    The main Discord client class that handles connection to Discord, event management,
    and provides access to guilds, channels, users, and other Discord resources.

    ```lua
    local Discord = require("@packages/Discord")

    local client = Discord.Client.new({
        intents = {
            Discord.Intents.Guilds,
            Discord.Intents.GuildMessages,
            Discord.Intents.MessageContent,
        },
    })

    client:On("ready", function()
        print("Logged in as " .. client.User:GetTag())
    end)

    client:Login(process.env.DISCORD_BOT_TOKEN)
    ```
]=]
local Client = {}
Client.__index = Client

export type Client = typeof(setmetatable(
    {} :: {
        Application: { flags: number, id: Types.Snowflake }?,
        Channels: { [Types.Snowflake]: Channel.Channel },
        Gateway: Gateway.Gateway?,
        Guilds: { [Types.Snowflake]: Guild.Guild },
        ReadyAt: number?,
        Rest: Rest.Rest?,
        User: User.User?,
        Users: { [Types.Snowflake]: User.User },
        _createMessage: ((data: Types.APIMessage, channel: Channel.Channel?) -> Message.Message)?,
        _eventHandlers: { [string]: { (any) -> () } },
        _intents: number,
        _token: string?,
    },
    Client
))

--[=[
    Creates a new Discord client instance.

    @param options ClientOptions? -- Optional configuration including intents
    @return Client -- The new client instance
]=]
function Client.new(options: Types.ClientOptions?): Client
    local self = setmetatable({}, Client)

    self.Channels = {}
    self.Guilds = {}
    self.Users = {}
    self._eventHandlers = {}

    -- Message factory to avoid cyclic dependency between Channel and Message
    self._createMessage = function(data: Types.APIMessage, channel: Channel.Channel?): Message.Message
        return Message.new(self, data)
    end

    -- Parse intents
    if options and options.intents then
        if type(options.intents) == "number" then
            self._intents = options.intents
        elseif type(options.intents) == "table" then
            local intents = 0
            for _, intent in options.intents do
                intents = bit32.bor(intents, intent)
            end
            self._intents = intents
        else
            error("Invalid intents format")
        end
    else
        -- Default intents
        self._intents = bit32.bor(GatewayIntent.Guilds, GatewayIntent.GuildMessages)
    end

    return self
end

function Client._setupGatewayHandlers(self: Client)
    if not self.Gateway then
        return
    end

    -- Handle ready event
    self.Gateway.OnReady:Connect(function(data: Types.GatewayReadyData)
        local user = User.new(self, data.user)
        self.User = user
        self.Application = data.application
        self.ReadyAt = os.time()

        -- Cache bot user
        self.Users[user.Id] = user

        -- Mark guilds as unavailable until we receive GUILD_CREATE
        for _, guildData in data.guilds do
            self.Guilds[guildData.id] = Guild.new(
                self,
                {
                    id = guildData.id,
                    unavailable = true,
                } :: any
            )
        end

        self:_emit("ready", self)
    end)

    -- Handle dispatch events
    self.Gateway.OnDispatch:Connect(function(eventName: string, data: any)
        self:_handleDispatchEvent(eventName, data)
    end)
end

function Client._handleDispatchEvent(self: Client, eventName: string, data: any)
    -- Handle specific events for caching
    if eventName == "GUILD_CREATE" then
        local guild = Guild.new(self, data)
        self.Guilds[guild.Id] = guild

        -- Cache channels
        for _, channel in guild.Channels do
            self.Channels[channel.Id] = channel
        end

        -- Cache users from members
        for _, member in guild.Members do
            if member.User then
                self.Users[member.User.Id] = member.User
            end
        end

        self:_emit("guildCreate", guild)
    elseif eventName == "GUILD_UPDATE" then
        local guild = self.Guilds[data.id]
        if guild then
            guild:_patch(data)
            self:_emit("guildUpdate", guild)
        end
    elseif eventName == "GUILD_DELETE" then
        local guild = self.Guilds[data.id]
        if guild then
            -- Remove cached channels
            for channelId in guild.Channels do
                self.Channels[channelId] = nil
            end

            if data.unavailable then
                guild.Unavailable = true
                self:_emit("guildUnavailable", guild)
            else
                self.Guilds[data.id] = nil
                self:_emit("guildDelete", guild)
            end
        end
    elseif eventName == "CHANNEL_CREATE" then
        local guild = data.guild_id and self.Guilds[data.guild_id]
        local channel = Channel.new(self, data, guild)
        self.Channels[channel.Id] = channel

        if guild then
            guild.Channels[channel.Id] = channel
        end

        self:_emit("channelCreate", channel)
    elseif eventName == "CHANNEL_UPDATE" then
        local channel = self.Channels[data.id]
        if channel then
            channel:_patch(data)
            self:_emit("channelUpdate", channel)
        else
            local guild = data.guild_id and self.Guilds[data.guild_id]
            channel = Channel.new(self, data, guild)
            self.Channels[channel.Id] = channel
            self:_emit("channelUpdate", channel)
        end
    elseif eventName == "CHANNEL_DELETE" then
        local channel = self.Channels[data.id]
        if channel then
            self.Channels[data.id] = nil

            if channel.Guild then
                channel.Guild.Channels[data.id] = nil
            end

            self:_emit("channelDelete", channel)
        end
    elseif eventName == "MESSAGE_CREATE" then
        local message = Message.new(self, data)

        -- Set guild reference
        if data.guild_id then
            message.GuildId = data.guild_id
            message.Guild = self.Guilds[data.guild_id]
        end

        -- Set channel reference
        message.Channel = self.Channels[data.channel_id]

        -- Set member with guild context
        if data.member and message.Guild then
            message.Member = Member.new(self, message.Guild, data.member)
            if message.Member.User then
                message.Guild.Members[message.Member.User.Id] = message.Member
            end
        end

        -- Cache author
        self.Users[message.Author.Id] = message.Author

        self:_emit("messageCreate", message)
    elseif eventName == "MESSAGE_UPDATE" then
        -- MESSAGE_UPDATE may be partial, so we need to handle it carefully
        local message = Message.new(self, data)

        if data.guild_id then
            message.GuildId = data.guild_id
            message.Guild = self.Guilds[data.guild_id]
        end

        message.Channel = self.Channels[data.channel_id]

        self:_emit("messageUpdate", message)
    elseif eventName == "MESSAGE_DELETE" then
        self:_emit("messageDelete", {
            channelId = data.channel_id,
            guildId = data.guild_id,
            id = data.id,
        })
    elseif eventName == "MESSAGE_DELETE_BULK" then
        self:_emit("messageDeleteBulk", {
            channelId = data.channel_id,
            guildId = data.guild_id,
            ids = data.ids,
        })
    elseif eventName == "MESSAGE_REACTION_ADD" then
        self:_emit("messageReactionAdd", {
            channelId = data.channel_id,
            emoji = data.emoji,
            guildId = data.guild_id,
            member = data.member,
            messageId = data.message_id,
            userId = data.user_id,
        })
    elseif eventName == "MESSAGE_REACTION_REMOVE" then
        self:_emit("messageReactionRemove", {
            channelId = data.channel_id,
            emoji = data.emoji,
            guildId = data.guild_id,
            messageId = data.message_id,
            userId = data.user_id,
        })
    elseif eventName == "MESSAGE_REACTION_REMOVE_ALL" then
        self:_emit("messageReactionRemoveAll", {
            channelId = data.channel_id,
            guildId = data.guild_id,
            messageId = data.message_id,
        })
    elseif eventName == "MESSAGE_REACTION_REMOVE_EMOJI" then
        self:_emit("messageReactionRemoveEmoji", {
            channelId = data.channel_id,
            emoji = data.emoji,
            guildId = data.guild_id,
            messageId = data.message_id,
        })
    elseif eventName == "GUILD_MEMBER_ADD" then
        local guild = self.Guilds[data.guild_id]
        if guild then
            local member = Member.new(self, guild, data)
            if member.User then
                guild.Members[member.User.Id] = member
                self.Users[member.User.Id] = member.User
            end
            self:_emit("guildMemberAdd", member)
        end
    elseif eventName == "GUILD_MEMBER_UPDATE" then
        local guild = self.Guilds[data.guild_id]
        if guild and data.user then
            local member = guild.Members[data.user.id]
            if member then
                member:_patch(data)
            else
                member = Member.new(self, guild, data)
                if member.User then
                    guild.Members[member.User.Id] = member
                end
            end
            self:_emit("guildMemberUpdate", member)
        end
    elseif eventName == "GUILD_MEMBER_REMOVE" then
        local guild = self.Guilds[data.guild_id]
        if guild and data.user then
            local member = guild.Members[data.user.id]
            guild.Members[data.user.id] = nil
            self:_emit("guildMemberRemove", {
                guild = guild,
                member = member,
                user = User.new(self, data.user),
            })
        end
    elseif eventName == "INTERACTION_CREATE" then
        local interaction = Interaction.new(self, data)
        self:_emit("interactionCreate", interaction)
    elseif eventName == "TYPING_START" then
        self:_emit("typingStart", {
            channelId = data.channel_id,
            guildId = data.guild_id,
            member = data.member,
            timestamp = data.timestamp,
            userId = data.user_id,
        })
    elseif eventName == "VOICE_STATE_UPDATE" then
        local guild = data.guild_id and self.Guilds[data.guild_id]
        local oldState = nil
        local newState = nil

        if guild then
            -- Get old state before updating
            local oldData = guild.VoiceStates[data.user_id]
            if oldData then
                oldState = VoiceState.new(self, oldData, guild)
            end

            -- Update or remove voice state
            if data.channel_id then
                -- User joined or moved to a channel
                guild.VoiceStates[data.user_id] = data
                newState = VoiceState.new(self, data, guild)
            else
                -- User left voice
                guild.VoiceStates[data.user_id] = nil
                newState = VoiceState.new(self, data, guild)
            end
        else
            -- No guild context (shouldn't happen for guild voice)
            newState = VoiceState.new(self, data, nil)
        end

        self:_emit("voiceStateUpdate", oldState, newState)
    elseif eventName == "VOICE_SERVER_UPDATE" then
        -- Emitted when voice server info is received (needed for Lavalink)
        self:_emit("voiceServerUpdate", data)
    elseif eventName == "PRESENCE_UPDATE" then
        self:_emit("presenceUpdate", data)
    else
        -- Emit raw event for unhandled events
        self:_emit("raw", {
            d = data,
            t = eventName,
        })
    end
end

function Client._emit(self: Client, eventName: string, ...: any)
    local handlers = self._eventHandlers[eventName]
    if handlers then
        for _, handler in handlers do
            task.spawn(handler, ...)
        end
    end
end

--[=[
    Registers an event handler for the specified event.

    @param eventName string -- The name of the event to listen for
    @param handler function -- The callback function to execute when the event fires
    @return function -- A function that disconnects the event handler when called
]=]
function Client.On(self: Client, eventName: string, handler: (any) -> ()): () -> ()
    assert(type(eventName) == "string", "Expected eventName to be a string")
    assert(type(handler) == "function", "Expected handler to be a function")

    if not self._eventHandlers[eventName] then
        self._eventHandlers[eventName] = {}
    end

    table.insert(self._eventHandlers[eventName], handler)

    -- Return disconnect function
    return function()
        local handlers = self._eventHandlers[eventName]
        if handlers then
            for i, h in handlers do
                if h == handler then
                    table.remove(handlers, i)
                    break
                end
            end
        end
    end
end

--[=[
    Registers a one-time event handler that automatically disconnects after firing once.

    @param eventName string -- The name of the event to listen for
    @param handler function -- The callback function to execute when the event fires
    @return function -- A function that disconnects the event handler when called
]=]
function Client.Once(self: Client, eventName: string, handler: (any) -> ()): () -> ()
    assert(type(eventName) == "string", "Expected eventName to be a string")
    assert(type(handler) == "function", "Expected handler to be a function")

    local disconnect: (() -> ())?

    disconnect = self:On(eventName, function(...)
        if disconnect then
            disconnect()
        end
        handler(...)
    end)

    return disconnect :: () -> ()
end

--[=[
    Logs in to Discord with the provided bot token.

    @param token string -- The bot token from Discord Developer Portal
]=]
function Client.Login(self: Client, token: string)
    assert(type(token) == "string", "Expected token to be a string")

    self._token = token
    self.Rest = Rest.new(self, token)

    local gateway = Gateway.new(self, token, self._intents)
    self.Gateway = gateway

    self:_setupGatewayHandlers()
    gateway:Connect()
end

--[=[
    Disconnects from Discord and cleans up all resources.
]=]
function Client.Destroy(self: Client)
    if self.Gateway then
        self.Gateway:Disconnect()
        self.Gateway = nil
    end

    self.Rest = nil
    self._token = nil
    self.User = nil
    self.Application = nil
    self.ReadyAt = nil

    table.clear(self.Guilds)
    table.clear(self.Channels)
    table.clear(self.Users)
    table.clear(self._eventHandlers)
end

--[=[
    Gets a cached guild by ID.

    @param guildId string -- The guild's snowflake ID
    @return Guild? -- The guild if cached, nil otherwise
]=]
function Client.GetGuild(self: Client, guildId: Types.Snowflake): Guild.Guild?
    assert(type(guildId) == "string", "Expected guildId to be a string")

    return self.Guilds[guildId]
end

--[=[
    Gets a cached channel by ID.

    @param channelId string -- The channel's snowflake ID
    @return Channel? -- The channel if cached, nil otherwise
]=]
function Client.GetChannel(self: Client, channelId: Types.Snowflake): Channel.Channel?
    assert(type(channelId) == "string", "Expected channelId to be a string")

    return self.Channels[channelId]
end

--[=[
    Gets a cached user by ID.

    @param userId string -- The user's snowflake ID
    @return User? -- The user if cached, nil otherwise
]=]
function Client.GetUser(self: Client, userId: Types.Snowflake): User.User?
    assert(type(userId) == "string", "Expected userId to be a string")

    return self.Users[userId]
end

--[=[
    Fetches a guild from the Discord API and caches it.

    @param guildId string -- The guild's snowflake ID
    @return Guild -- The fetched guild
]=]
function Client.FetchGuild(self: Client, guildId: Types.Snowflake): Guild.Guild
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(self.Rest, "Client is not logged in")

    local data = self.Rest:GetGuild(guildId, true)
    local guild = Guild.new(self, data)
    self.Guilds[guild.Id] = guild

    return guild
end

function Client.FetchChannel(self: Client, channelId: Types.Snowflake): Channel.Channel
    assert(type(channelId) == "string", "Expected channelId to be a string")
    assert(self.Rest, "Client is not logged in")

    local data = self.Rest:GetChannel(channelId)
    local guild = data.guild_id and self.Guilds[data.guild_id]
    local channel = Channel.new(self, data, guild)
    self.Channels[channel.Id] = channel

    return channel
end

function Client.FetchUser(self: Client, userId: Types.Snowflake): User.User
    assert(type(userId) == "string", "Expected userId to be a string")
    assert(self.Rest, "Client is not logged in")

    local data = self.Rest:GetUser(userId)
    local user = User.new(self, data)
    self.Users[user.Id] = user

    return user
end

function Client.CreateDM(self: Client, userId: Types.Snowflake): Channel.Channel
    assert(type(userId) == "string", "Expected userId to be a string")
    assert(self.Rest, "Client is not logged in")

    local data = self.Rest:CreateDM(userId)
    local channel = Channel.new(self, data)
    self.Channels[channel.Id] = channel

    return channel
end

function Client.SetPresence(self: Client, presence: Types.GatewayPresenceUpdateData)
    assert(type(presence) == "table", "Expected presence to be a table")
    assert(self.Gateway, "Client is not logged in")

    self.Gateway:UpdatePresence(presence)
end

function Client.IsReady(self: Client): boolean
    return self.ReadyAt ~= nil
end

function Client.GetUptime(self: Client): number?
    if not self.ReadyAt then
        return nil
    end

    return os.time() - self.ReadyAt
end

-- Slash command management methods
function Client.RegisterGlobalCommand(
    self: Client,
    command: { [string]: any } | { ToJSON: (any) -> { [string]: any } }
): Types.APIApplicationCommand
    assert(self.Rest, "Client is not logged in")
    assert(self.Application, "Application not available yet, wait for ready event")

    local data = if type(command.ToJSON) == "function" then command:ToJSON() else command
    return self.Rest:CreateGlobalApplicationCommand(self.Application.id, data)
end

function Client.RegisterGuildCommand(
    self: Client,
    guildId: Types.Snowflake,
    command: { [string]: any } | { ToJSON: (any) -> { [string]: any } }
): Types.APIApplicationCommand
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(self.Rest, "Client is not logged in")
    assert(self.Application, "Application not available yet, wait for ready event")

    local data = if type(command.ToJSON) == "function" then command:ToJSON() else command
    return self.Rest:CreateGuildApplicationCommand(self.Application.id, guildId, data)
end

--[=[
    Bulk overwrites all global slash commands for the application.

    @param commands {SlashCommandBuilder} -- Array of slash command builders or command data
    @return {APIApplicationCommand} -- The registered commands
]=]
function Client.SetGlobalCommands(
    self: Client,
    commands: { { [string]: any } | { ToJSON: (any) -> { [string]: any } } }
): { Types.APIApplicationCommand }
    assert(type(commands) == "table", "Expected commands to be a table")
    assert(self.Rest, "Client is not logged in")
    assert(self.Application, "Application not available yet, wait for ready event")

    local data = {}
    for _, command in commands do
        if type(command.ToJSON) == "function" then
            table.insert(data, command:ToJSON())
        else
            table.insert(data, command)
        end
    end

    return self.Rest:BulkOverwriteGlobalApplicationCommands(self.Application.id, data)
end

function Client.SetGuildCommands(
    self: Client,
    guildId: Types.Snowflake,
    commands: { { [string]: any } | { ToJSON: (any) -> { [string]: any } } }
): { Types.APIApplicationCommand }
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(commands) == "table", "Expected commands to be a table")
    assert(self.Rest, "Client is not logged in")
    assert(self.Application, "Application not available yet, wait for ready event")

    local data = {}
    for _, command in commands do
        if type(command.ToJSON) == "function" then
            table.insert(data, command:ToJSON())
        else
            table.insert(data, command)
        end
    end

    return self.Rest:BulkOverwriteGuildApplicationCommands(self.Application.id, guildId, data)
end

function Client.GetGlobalCommands(self: Client): { Types.APIApplicationCommand }
    assert(self.Rest, "Client is not logged in")
    assert(self.Application, "Application not available yet, wait for ready event")

    return self.Rest:GetGlobalApplicationCommands(self.Application.id)
end

function Client.GetGuildCommands(self: Client, guildId: Types.Snowflake): { Types.APIApplicationCommand }
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(self.Rest, "Client is not logged in")
    assert(self.Application, "Application not available yet, wait for ready event")

    return self.Rest:GetGuildApplicationCommands(self.Application.id, guildId)
end

function Client.DeleteGlobalCommand(self: Client, commandId: Types.Snowflake)
    assert(type(commandId) == "string", "Expected commandId to be a string")
    assert(self.Rest, "Client is not logged in")
    assert(self.Application, "Application not available yet, wait for ready event")

    self.Rest:DeleteGlobalApplicationCommand(self.Application.id, commandId)
end

function Client.DeleteGuildCommand(self: Client, guildId: Types.Snowflake, commandId: Types.Snowflake)
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(commandId) == "string", "Expected commandId to be a string")
    assert(self.Rest, "Client is not logged in")
    assert(self.Application, "Application not available yet, wait for ready event")

    self.Rest:DeleteGuildApplicationCommand(self.Application.id, guildId, commandId)
end

function Client.__tostring(self: Client): string
    if self.User then
        return `Client({self.User:GetTag()})`
    end
    return "Client(not logged in)"
end

return Client
