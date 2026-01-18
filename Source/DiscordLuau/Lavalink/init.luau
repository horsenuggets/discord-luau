--[[

Lavalink

Main manager for Lavalink audio functionality. Handles node management, player creation,
and coordination between Discord voice events and Lavalink servers.

Usage:
    local client = Client.new(token)
    local lavalink = Lavalink.new(client)

    lavalink:AddNode({
        name = "main",
        host = "localhost",
        port = 2333,
        password = "lifeisroblox",
    })

    local player = lavalink:GetPlayer(guildId)
    player:Connect(channelId)

    local result = lavalink:Search("never gonna give you up")
    if result.loadType == "search" then
        player:Play(result.data[1])
    end

--]]

local Signal = require("@discordluau/Utils/Signal")

local LavalinkNode = require("@self/LavalinkNode")
local Player = require("@self/Player")
local Track = require("@self/Track")
local Types = require("@self/Types")

local Lavalink = {}
Lavalink.__index = Lavalink

export type Lavalink = typeof(setmetatable(
    {} :: {
        Client: any, -- DiscordLuau Client (avoid circular reference)
        Nodes: { [string]: LavalinkNode.LavalinkNode },
        Players: { [string]: Player.Player },

        OnNodeReady: Signal.Signal<LavalinkNode.LavalinkNode>,
        OnNodeDisconnect: Signal.Signal<LavalinkNode.LavalinkNode, number?, string?>,
        OnTrackStart: Signal.Signal<Player.Player, Track.Track>,
        OnTrackEnd: Signal.Signal<Player.Player, Track.Track, string>,
        OnTrackException: Signal.Signal<
            Player.Player,
            Track.Track,
            { message: string?, severity: string, cause: string }
        >,
        OnTrackStuck: Signal.Signal<Player.Player, Track.Track, number>,

        _voiceStates: { [string]: { sessionId: string?, channelId: string? } },
        _voiceServers: { [string]: { token: string, endpoint: string } },
    },
    Lavalink
))

function Lavalink.new(client: any): Lavalink
    assert(type(client) == "table", "Expected client to be a table")

    local self = setmetatable({}, Lavalink)

    self.Client = client
    self.Nodes = {}
    self.Players = {}

    -- Signals for global events
    self.OnNodeReady = Signal.new()
    self.OnNodeDisconnect = Signal.new()
    self.OnTrackStart = Signal.new()
    self.OnTrackEnd = Signal.new()
    self.OnTrackException = Signal.new()
    self.OnTrackStuck = Signal.new()

    -- Voice state tracking for connecting to Lavalink
    self._voiceStates = {}
    self._voiceServers = {}

    -- Listen to client voice events
    self:_setupClientListeners()

    return self
end

function Lavalink._setupClientListeners(self: Lavalink)
    -- Listen for voice state updates
    self.Client:On("voiceStateUpdate", function(oldState: any, newState: any)
        if not newState then
            return
        end

        -- Only care about our own voice states
        if newState.UserId ~= self.Client.User.Id then
            return
        end

        local guildId = newState.GuildId
        if not guildId then
            return
        end

        self._voiceStates[guildId] = {
            sessionId = newState.SessionId,
            channelId = newState.ChannelId,
        }

        self:_tryConnectPlayer(guildId)
    end)

    -- Listen for voice server updates
    self.Client:On("voiceServerUpdate", function(data: any)
        local guildId = data.guild_id
        if not guildId then
            return
        end

        self._voiceServers[guildId] = {
            token = data.token,
            endpoint = data.endpoint,
        }

        self:_tryConnectPlayer(guildId)
    end)
end

function Lavalink._tryConnectPlayer(self: Lavalink, guildId: string)
    local voiceState = self._voiceStates[guildId]
    local voiceServer = self._voiceServers[guildId]

    if not voiceState or not voiceServer then
        return
    end

    if not voiceState.sessionId or not voiceServer.token or not voiceServer.endpoint then
        return
    end

    local player = self.Players[guildId]
    if not player then
        return
    end

    player:_setVoiceState({
        token = voiceServer.token,
        endpoint = voiceServer.endpoint,
        sessionId = voiceState.sessionId,
    })
end

--[[
    Adds a Lavalink node.

    @param options - Node configuration options
    @return The created node
]]
function Lavalink.AddNode(self: Lavalink, options: Types.NodeOptions): LavalinkNode.LavalinkNode
    assert(type(options) == "table", "Expected options to be a table")
    assert(type(options.name) == "string", "Expected options.name to be a string")

    local clientId = self.Client.User and self.Client.User.Id or "0"
    local node = LavalinkNode.new(options, clientId)

    -- Set up node event listeners
    node.OnReady:Connect(function(sessionId: string, resumed: boolean)
        self.OnNodeReady:Fire(node)
    end)

    node.OnDisconnect:Connect(function(code: number?, reason: string?)
        self.OnNodeDisconnect:Fire(node, code, reason)
    end)

    node.OnPlayerUpdate:Connect(function(guildId: string, state: Types.PlayerState)
        local player = self.Players[guildId]
        if player then
            player:_updateState(state)
        end
    end)

    node.OnTrackStart:Connect(function(guildId: string, track: Types.LavalinkTrack)
        local player = self.Players[guildId]
        if player then
            player:_onTrackStart(track)
            self.OnTrackStart:Fire(player, player.CurrentTrack :: Track.Track)
        end
    end)

    node.OnTrackEnd:Connect(function(guildId: string, track: Types.LavalinkTrack, reason: string)
        local player = self.Players[guildId]
        if player then
            player:_onTrackEnd(track, reason)
            self.OnTrackEnd:Fire(player, Track.new(track), reason)
        end
    end)

    node.OnTrackException:Connect(function(guildId: string, track: Types.LavalinkTrack, exception: any)
        local player = self.Players[guildId]
        if player then
            player:_onTrackException(track, exception)
            self.OnTrackException:Fire(player, Track.new(track), exception)
        end
    end)

    node.OnTrackStuck:Connect(function(guildId: string, track: Types.LavalinkTrack, thresholdMs: number)
        local player = self.Players[guildId]
        if player then
            player:_onTrackStuck(track, thresholdMs)
            self.OnTrackStuck:Fire(player, Track.new(track), thresholdMs)
        end
    end)

    self.Nodes[options.name] = node

    -- Connect to the node
    node:Connect()

    return node
end

--[[
    Removes a Lavalink node.

    @param name - The name of the node to remove
]]
function Lavalink.RemoveNode(self: Lavalink, name: string)
    assert(type(name) == "string", "Expected name to be a string")

    local node = self.Nodes[name]
    if node then
        node:Disconnect()
        self.Nodes[name] = nil
    end
end

--[[
    Gets the best available node based on load.

    @return The best node or nil if none available
]]
function Lavalink.GetBestNode(self: Lavalink): LavalinkNode.LavalinkNode?
    local bestNode: LavalinkNode.LavalinkNode? = nil
    local bestPenalty = math.huge

    for _, node in self.Nodes do
        if node:IsReady() then
            local penalty = node:GetPenalty()
            if penalty < bestPenalty then
                bestPenalty = penalty
                bestNode = node
            end
        end
    end

    return bestNode
end

--[[
    Gets a node by name.

    @param name - The node name
    @return The node or nil
]]
function Lavalink.GetNode(self: Lavalink, name: string): LavalinkNode.LavalinkNode?
    return self.Nodes[name]
end

--[[
    Gets or creates a player for a guild.

    @param guildId - The guild ID
    @return The player for the guild
]]
function Lavalink.GetPlayer(self: Lavalink, guildId: string): Player.Player?
    assert(type(guildId) == "string", "Expected guildId to be a string")

    local player = self.Players[guildId]
    if player then
        return player
    end

    return self:CreatePlayer(guildId)
end

--[[
    Creates a new player for a guild.

    @param guildId - The guild ID
    @return The created player or nil if no nodes available
]]
function Lavalink.CreatePlayer(self: Lavalink, guildId: string): Player.Player?
    assert(type(guildId) == "string", "Expected guildId to be a string")

    local node = self:GetBestNode()
    if not node then
        return nil
    end

    local player = Player.new(guildId, node, self)
    self.Players[guildId] = player

    return player
end

--[[
    Destroys a player for a guild.

    @param guildId - The guild ID
]]
function Lavalink.DestroyPlayer(self: Lavalink, guildId: string)
    assert(type(guildId) == "string", "Expected guildId to be a string")

    local player = self.Players[guildId]
    if player then
        player:Disconnect()
        self.Players[guildId] = nil
    end

    self._voiceStates[guildId] = nil
    self._voiceServers[guildId] = nil
end

--[[
    Searches for tracks.

    @param query - The search query
    @param source - The source to search (ytsearch, scsearch, etc.)
    @return Load result with tracks
]]
function Lavalink.Search(self: Lavalink, query: string, source: string?): Types.LoadResult
    assert(type(query) == "string", "Expected query to be a string")

    local node = self:GetBestNode()
    if not node then
        return {
            loadType = "error",
            data = {
                message = "No available nodes",
                severity = "common",
                cause = "No Lavalink nodes are connected",
            },
        }
    end

    return node.Rest:Search(query, source)
end

--[[
    Loads tracks from an identifier (URL or search query).

    @param identifier - The track identifier
    @return Load result with tracks
]]
function Lavalink.LoadTracks(self: Lavalink, identifier: string): Types.LoadResult
    assert(type(identifier) == "string", "Expected identifier to be a string")

    local node = self:GetBestNode()
    if not node then
        return {
            loadType = "error",
            data = {
                message = "No available nodes",
                severity = "common",
                cause = "No Lavalink nodes are connected",
            },
        }
    end

    return node.Rest:LoadTracks(identifier)
end

--[[
    Loads a local audio file.

    @param filePath - The absolute path to the audio file
    @return Load result with track
]]
function Lavalink.LoadFile(self: Lavalink, filePath: string): Types.LoadResult
    assert(type(filePath) == "string", "Expected filePath to be a string")

    -- Ensure absolute path and normalize
    local absolutePath = filePath
    if not string.match(absolutePath, "^/") then
        -- Relative path - this won't work for Lavalink, warn the user
        return {
            loadType = "error",
            data = {
                message = "File path must be absolute",
                severity = "common",
                cause = "Lavalink requires absolute file paths",
            },
        }
    end

    return self:LoadTracks(absolutePath)
end

--[[
    Sends a voice state update to Discord gateway.

    @param guildId - The guild ID
    @param channelId - The channel ID (nil to disconnect)
    @param selfDeaf - Whether to self deafen
    @param selfMute - Whether to self mute
]]
function Lavalink._sendVoiceUpdate(
    self: Lavalink,
    guildId: string,
    channelId: string?,
    selfDeaf: boolean,
    selfMute: boolean
)
    -- Use the client's gateway to send voice state update
    if self.Client.Gateway and self.Client.Gateway.UpdateVoiceState then
        self.Client.Gateway:UpdateVoiceState(guildId, channelId, selfMute, selfDeaf)
    end
end

function Lavalink.__tostring(self: Lavalink): string
    local nodeCount = 0
    for _ in self.Nodes do
        nodeCount += 1
    end

    local playerCount = 0
    for _ in self.Players do
        playerCount += 1
    end

    return `Lavalink(nodes={nodeCount}, players={playerCount})`
end

-- Export types and classes
Lavalink.LavalinkNode = LavalinkNode
Lavalink.Player = Player
Lavalink.Track = Track
Lavalink.Types = Types

return Lavalink
