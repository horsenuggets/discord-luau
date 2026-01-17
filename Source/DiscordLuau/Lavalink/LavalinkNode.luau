--[[

LavalinkNode

WebSocket connection to a Lavalink server. Handles connection, events,
session management, and reconnection.

--]]

local net = require("@lune/net")
local serde = require("@lune/serde")
local task = require("@lune/task")

local Signal = require("@discordluau/Utils/Signal")

local LavalinkRest = require("@self/LavalinkRest")
local Types = require("@self/Types")

local LavalinkNode = {}
LavalinkNode.__index = LavalinkNode

export type LavalinkNode = typeof(setmetatable(
    {} :: {
        Name: string,
        Host: string,
        Port: number,
        Password: string,
        Secure: boolean,
        SessionId: string?,
        Connected: boolean,
        Resumed: boolean,
        Stats: Types.StatsEvent?,
        Rest: LavalinkRest.LavalinkRest,

        OnReady: Signal.Signal<string, boolean>,
        OnPlayerUpdate: Signal.Signal<string, Types.PlayerState>,
        OnTrackStart: Signal.Signal<string, Types.LavalinkTrack>,
        OnTrackEnd: Signal.Signal<string, Types.LavalinkTrack, string>,
        OnTrackException: Signal.Signal<string, Types.LavalinkTrack, { message: string?, severity: string, cause: string }>,
        OnTrackStuck: Signal.Signal<string, Types.LavalinkTrack, number>,
        OnWebSocketClosed: Signal.Signal<string, number, string, boolean>,
        OnStatsUpdate: Signal.Signal<Types.StatsEvent>,
        OnDisconnect: Signal.Signal<number?, string?>,

        _socket: net.WebSocket?,
        _clientId: string,
        _resumeKey: string?,
        _resumeTimeout: number,
        _reconnectAttempts: number,
        _maxReconnectAttempts: number,
        _reconnectDelay: number,
        _shouldReconnect: boolean,
    },
    LavalinkNode
))

function LavalinkNode.new(options: Types.NodeOptions, clientId: string): LavalinkNode
    assert(type(options) == "table", "Expected options to be a table")
    assert(type(options.name) == "string", "Expected options.name to be a string")
    assert(type(options.host) == "string", "Expected options.host to be a string")
    assert(type(options.port) == "number", "Expected options.port to be a number")
    assert(type(options.password) == "string", "Expected options.password to be a string")
    assert(type(clientId) == "string", "Expected clientId to be a string")

    local self = setmetatable({}, LavalinkNode)

    self.Name = options.name
    self.Host = options.host
    self.Port = options.port
    self.Password = options.password
    self.Secure = options.secure or false
    self.SessionId = nil
    self.Connected = false
    self.Resumed = false
    self.Stats = nil

    self.Rest = LavalinkRest.new(options.host, options.port, options.password, options.secure)

    -- Signals for events
    self.OnReady = Signal.new()
    self.OnPlayerUpdate = Signal.new()
    self.OnTrackStart = Signal.new()
    self.OnTrackEnd = Signal.new()
    self.OnTrackException = Signal.new()
    self.OnTrackStuck = Signal.new()
    self.OnWebSocketClosed = Signal.new()
    self.OnStatsUpdate = Signal.new()
    self.OnDisconnect = Signal.new()

    self._socket = nil
    self._clientId = clientId
    self._resumeKey = options.resumeKey
    self._resumeTimeout = options.resumeTimeout or 60
    self._reconnectAttempts = 0
    self._maxReconnectAttempts = 5
    self._reconnectDelay = 5
    self._shouldReconnect = true

    return self
end

function LavalinkNode.Connect(self: LavalinkNode): boolean
    if self.Connected then
        return true
    end

    local protocol = if self.Secure then "wss" else "ws"
    local url = `{protocol}://{self.Host}:{self.Port}/v4/websocket`

    local headers: { [string]: string } = {
        ["Authorization"] = self.Password,
        ["User-Id"] = self._clientId,
        ["Client-Name"] = "DiscordLuau/1.0.0",
    }

    if self._resumeKey and self.SessionId then
        headers["Session-Id"] = self.SessionId
    end

    local success, socket = pcall(net.socket, url, {
        headers = headers,
    })

    if not success then
        self:_handleReconnect()
        return false
    end

    self._socket = socket
    self.Connected = true
    self._reconnectAttempts = 0

    -- Start listening for messages
    task.spawn(function()
        self:_listen()
    end)

    return true
end

function LavalinkNode.Disconnect(self: LavalinkNode)
    self._shouldReconnect = false
    self.Connected = false

    if self._socket then
        pcall(function()
            self._socket:close()
        end)
        self._socket = nil
    end
end

function LavalinkNode._listen(self: LavalinkNode)
    if not self._socket then
        return
    end

    while self.Connected do
        local success, message = pcall(function()
            return self._socket:next()
        end)

        if not success then
            self.Connected = false
            self.OnDisconnect:Fire(nil, tostring(message))
            self:_handleReconnect()
            break
        end

        if message == nil then
            -- Connection closed
            self.Connected = false
            self.OnDisconnect:Fire(nil, "Connection closed")
            self:_handleReconnect()
            break
        end

        if message.type == "text" then
            self:_handleMessage(message.data)
        elseif message.type == "close" then
            self.Connected = false
            self.OnDisconnect:Fire(message.code, message.reason)
            self:_handleReconnect()
            break
        end
    end
end

function LavalinkNode._handleMessage(self: LavalinkNode, data: string)
    local success, payload = pcall(serde.decode, "json", data)

    if not success then
        return
    end

    local op = payload.op

    if op == "ready" then
        self:_handleReady(payload :: Types.ReadyEvent)
    elseif op == "playerUpdate" then
        self:_handlePlayerUpdate(payload :: Types.PlayerUpdateEvent)
    elseif op == "stats" then
        self:_handleStats(payload :: Types.StatsEvent)
    elseif op == "event" then
        self:_handleEvent(payload)
    end
end

function LavalinkNode._handleReady(self: LavalinkNode, data: Types.ReadyEvent)
    self.SessionId = data.sessionId
    self.Resumed = data.resumed
    self.Rest:SetSessionId(data.sessionId)

    -- Configure session resuming if enabled
    if self._resumeKey then
        self.Rest:UpdateSession(true, self._resumeTimeout)
    end

    self.OnReady:Fire(data.sessionId, data.resumed)
end

function LavalinkNode._handlePlayerUpdate(self: LavalinkNode, data: Types.PlayerUpdateEvent)
    self.OnPlayerUpdate:Fire(data.guildId, data.state)
end

function LavalinkNode._handleStats(self: LavalinkNode, data: Types.StatsEvent)
    self.Stats = data
    self.OnStatsUpdate:Fire(data)
end

function LavalinkNode._handleEvent(self: LavalinkNode, data: Types.LavalinkEvent)
    local eventType = data.type

    if eventType == "TrackStartEvent" then
        local event = data :: Types.TrackStartEvent
        self.OnTrackStart:Fire(event.guildId, event.track)
    elseif eventType == "TrackEndEvent" then
        local event = data :: Types.TrackEndEvent
        self.OnTrackEnd:Fire(event.guildId, event.track, event.reason)
    elseif eventType == "TrackExceptionEvent" then
        local event = data :: Types.TrackExceptionEvent
        self.OnTrackException:Fire(event.guildId, event.track, event.exception)
    elseif eventType == "TrackStuckEvent" then
        local event = data :: Types.TrackStuckEvent
        self.OnTrackStuck:Fire(event.guildId, event.track, event.thresholdMs)
    elseif eventType == "WebSocketClosedEvent" then
        local event = data :: Types.WebSocketClosedEvent
        self.OnWebSocketClosed:Fire(event.guildId, event.code, event.reason, event.byRemote)
    end
end

function LavalinkNode._handleReconnect(self: LavalinkNode)
    if not self._shouldReconnect then
        return
    end

    if self._reconnectAttempts >= self._maxReconnectAttempts then
        return
    end

    self._reconnectAttempts += 1
    local delay = self._reconnectDelay * self._reconnectAttempts

    task.delay(delay, function()
        if self._shouldReconnect and not self.Connected then
            self:Connect()
        end
    end)
end

function LavalinkNode.IsReady(self: LavalinkNode): boolean
    return self.Connected and self.SessionId ~= nil
end

function LavalinkNode.GetPenalty(self: LavalinkNode): number
    -- Calculate node penalty for load balancing
    -- Lower is better
    if not self.Connected or not self.Stats then
        return math.huge
    end

    local stats = self.Stats
    local penalty = 0

    -- CPU penalty
    penalty += stats.cpu.systemLoad * 100
    penalty += stats.cpu.lavalinkLoad * 100

    -- Player penalty
    penalty += stats.playingPlayers * 10

    -- Memory penalty
    local memoryUsage = stats.memory.used / stats.memory.allocated
    penalty += memoryUsage * 50

    -- Frame stats penalty (if available)
    if stats.frameStats then
        local nullFrames = stats.frameStats.nulled
        local deficitFrames = stats.frameStats.deficit
        penalty += nullFrames * 5
        penalty += deficitFrames * 2
    end

    return penalty
end

function LavalinkNode.__tostring(self: LavalinkNode): string
    local status = if self.Connected then "connected" else "disconnected"
    return `LavalinkNode({self.Name}, {status})`
end

return LavalinkNode
