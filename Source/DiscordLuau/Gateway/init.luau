--[[

Gateway

Discord Gateway WebSocket client for real-time events. Handles connection lifecycle,
heartbeating, identify/resume, and event dispatch.

--]]

local net = require("@lune/net")
local serde = require("@lune/serde")
local task = require("@lune/task")

local GatewayCloseCode = require("../Enums/GatewayCloseCode")
local GatewayOpcode = require("../Enums/GatewayOpcode")
local Signal = require("../Utils/Signal")
local Types = require("../Structures/Types")

local GATEWAY_VERSION = 10
local DEFAULT_GATEWAY_URL = `wss://gateway.discord.gg/?v={GATEWAY_VERSION}&encoding=json`
local RECONNECT_DELAY = 1
local MAX_RECONNECT_ATTEMPTS = 5

local Gateway = {}
Gateway.__index = Gateway

export type Gateway = typeof(setmetatable(
    {} :: {
        _client: Types.Client,
        _gatewayUrl: string,
        _heartbeatAck: boolean,
        _heartbeatInterval: number?,
        _heartbeatProcess: thread?,
        _intents: number,
        _mainProcess: thread?,
        _reconnectAttempts: number,
        _resumeGatewayUrl: string?,
        _sequenceNumber: number?,
        _sessionId: string?,
        _token: string,
        _webSocket: net.WebSocket?,
        OnDispatch: Signal.Signal<string, any>,
        OnReady: Signal.Signal<Types.GatewayReadyData>,
    },
    Gateway
))

function Gateway.new(client: Types.Client, token: string, intents: number): Gateway
    assert(type(client) == "table", "Expected client to be a table")
    assert(type(token) == "string", "Expected token to be a string")
    assert(type(intents) == "number", "Expected intents to be a number")

    local self = setmetatable({}, Gateway)

    self._client = client
    self._gatewayUrl = DEFAULT_GATEWAY_URL
    self._heartbeatAck = true
    self._intents = intents
    self._reconnectAttempts = 0
    self._token = token

    self.OnDispatch = Signal.new()
    self.OnReady = Signal.new()

    return self
end

function Gateway._sendPayload(self: Gateway, opcode: number, data: any)
    if not self._webSocket then
        return
    end

    local payload = serde.encode("json", {
        d = data,
        op = opcode,
    })

    self._webSocket:send(payload)
end

function Gateway._identify(self: Gateway)
    local identifyData: Types.GatewayIdentifyData = {
        intents = self._intents,
        properties = {
            browser = "discord-luau",
            device = "discord-luau",
            os = "luau",
        },
        token = self._token,
    }

    self:_sendPayload(GatewayOpcode.Identify, identifyData)
end

function Gateway._resume(self: Gateway)
    if not self._sessionId or not self._sequenceNumber then
        self:_identify()
        return
    end

    local resumeData: Types.GatewayResumeData = {
        seq = self._sequenceNumber,
        session_id = self._sessionId,
        token = self._token,
    }

    self:_sendPayload(GatewayOpcode.Resume, resumeData)
end

function Gateway._startHeartbeat(self: Gateway, interval: number)
    self._heartbeatInterval = interval

    -- Cancel existing heartbeat process
    if self._heartbeatProcess then
        pcall(task.cancel, self._heartbeatProcess)
    end

    self._heartbeatProcess = task.spawn(function()
        -- First heartbeat has jitter
        local jitter = math.random()
        task.wait(interval / 1000 * jitter)

        while true do
            if not self._heartbeatAck then
                -- Zombied connection, reconnect
                warn("Gateway connection zombied, reconnecting.")
                self:_disconnect(4000)
                return
            end

            self._heartbeatAck = false
            self:_sendPayload(GatewayOpcode.Heartbeat, self._sequenceNumber)

            task.wait(interval / 1000)
        end
    end)
end

function Gateway._handlePayload(self: Gateway, payload: Types.GatewayPayload)
    -- Update sequence number
    if payload.s then
        self._sequenceNumber = payload.s
    end

    local opcode = payload.op
    local data = payload.d
    local eventName = payload.t

    if opcode == GatewayOpcode.Dispatch then
        -- Dispatch event
        if eventName == "READY" then
            local readyData = data :: Types.GatewayReadyData
            self._sessionId = readyData.session_id
            self._resumeGatewayUrl = readyData.resume_gateway_url
            self._reconnectAttempts = 0

            self.OnReady:Fire(readyData)
        end

        if eventName then
            self.OnDispatch:Fire(eventName, data)
        end
    elseif opcode == GatewayOpcode.Heartbeat then
        -- Gateway requested heartbeat
        self:_sendPayload(GatewayOpcode.Heartbeat, self._sequenceNumber)
    elseif opcode == GatewayOpcode.Reconnect then
        -- Gateway requested reconnect
        self:_disconnect(4000)
    elseif opcode == GatewayOpcode.InvalidSession then
        -- Invalid session
        local canResume = data == true
        if canResume then
            -- Wait 1-5 seconds then resume
            task.wait(math.random() * 4 + 1)
            self:_resume()
        else
            -- Cannot resume, start fresh
            self._sessionId = nil
            self._sequenceNumber = nil
            task.wait(math.random() * 4 + 1)
            self:_identify()
        end
    elseif opcode == GatewayOpcode.Hello then
        -- Hello event
        local helloData = data :: Types.GatewayHelloData
        self:_startHeartbeat(helloData.heartbeat_interval)

        -- Identify or resume
        if self._sessionId then
            self:_resume()
        else
            self:_identify()
        end
    elseif opcode == GatewayOpcode.HeartbeatAck then
        -- Heartbeat acknowledged
        self._heartbeatAck = true
    end
end

function Gateway._disconnect(self: Gateway, code: number?)
    if self._webSocket then
        pcall(function()
            self._webSocket:close(code or 1000)
        end)
        self._webSocket = nil
    end

    if self._heartbeatProcess then
        pcall(task.cancel, self._heartbeatProcess)
        self._heartbeatProcess = nil
    end
end

function Gateway._shouldReconnect(self: Gateway, closeCode: number?): boolean
    if not closeCode then
        return true
    end

    -- Non-reconnectable close codes
    local noReconnect = {
        [GatewayCloseCode.AuthenticationFailed] = true,
        [GatewayCloseCode.InvalidShard] = true,
        [GatewayCloseCode.ShardingRequired] = true,
        [GatewayCloseCode.InvalidApiVersion] = true,
        [GatewayCloseCode.InvalidIntents] = true,
        [GatewayCloseCode.DisallowedIntents] = true,
    }

    return not noReconnect[closeCode]
end

function Gateway._connect(self: Gateway)
    -- Use resume gateway URL if available, otherwise default
    local gatewayUrl = self._resumeGatewayUrl or self._gatewayUrl

    -- Append query params if not present
    if not gatewayUrl:find("?") then
        gatewayUrl = `{gatewayUrl}?v={GATEWAY_VERSION}&encoding=json`
    end

    local success, result = pcall(function()
        return net.socket(gatewayUrl)
    end)

    if not success then
        warn(`Failed to connect to gateway: {result}`)
        return false
    end

    self._webSocket = result
    self._heartbeatAck = true

    return true
end

function Gateway.Connect(self: Gateway)
    if self._mainProcess then
        return
    end

    self._mainProcess = task.spawn(function()
        while true do
            -- Attempt to connect
            if not self:_connect() then
                self._reconnectAttempts += 1

                if self._reconnectAttempts >= MAX_RECONNECT_ATTEMPTS then
                    error("Failed to connect to Discord gateway after maximum attempts")
                end

                task.wait(RECONNECT_DELAY * self._reconnectAttempts)
                continue
            end

            -- Message loop
            while self._webSocket do
                local message = self._webSocket:next()
                if not message then
                    local closeCode = self._webSocket.closeCode
                    self:_disconnect()

                    if self:_shouldReconnect(closeCode) then
                        self._reconnectAttempts += 1

                        if self._reconnectAttempts >= MAX_RECONNECT_ATTEMPTS then
                            error("Gateway disconnected and failed to reconnect")
                        end

                        task.wait(RECONNECT_DELAY * self._reconnectAttempts)
                        break
                    else
                        error(`Gateway closed with non-reconnectable code {closeCode or "unknown"}`)
                    end
                end

                -- Parse and handle payload
                local success, payload = pcall(function()
                    return serde.decode("json", message)
                end)

                if success and payload then
                    xpcall(function()
                        self:_handlePayload(payload)
                    end, function(err)
                        warn(`Error handling gateway payload: {err}`)
                    end)
                end
            end
        end
    end)
end

function Gateway.Disconnect(self: Gateway)
    if self._mainProcess then
        pcall(task.cancel, self._mainProcess)
        self._mainProcess = nil
    end

    self:_disconnect(1000)

    self._sessionId = nil
    self._sequenceNumber = nil
    self._resumeGatewayUrl = nil
end

function Gateway.UpdatePresence(self: Gateway, presence: Types.GatewayPresenceUpdateData)
    assert(type(presence) == "table", "Expected presence to be a table")

    self:_sendPayload(GatewayOpcode.PresenceUpdate, presence)
end

function Gateway.RequestGuildMembers(
    self: Gateway,
    guildId: Types.Snowflake,
    options: {
        limit: number?,
        presences: boolean?,
        query: string?,
        user_ids: { Types.Snowflake }?,
    }?
)
    assert(type(guildId) == "string", "Expected guildId to be a string")

    local data: { [string]: any } = {
        guild_id = guildId,
    }

    if options then
        if options.query ~= nil then
            data.query = options.query
        end
        if options.limit then
            data.limit = options.limit
        end
        if options.presences ~= nil then
            data.presences = options.presences
        end
        if options.user_ids then
            data.user_ids = options.user_ids
        end
    end

    -- Either query or user_ids must be set
    if not data.query and not data.user_ids then
        data.query = ""
        data.limit = 0
    end

    self:_sendPayload(GatewayOpcode.RequestGuildMembers, data)
end

function Gateway.UpdateVoiceState(
    self: Gateway,
    guildId: Types.Snowflake,
    channelId: Types.Snowflake?,
    options: { self_deaf: boolean?, self_mute: boolean? }?
)
    assert(type(guildId) == "string", "Expected guildId to be a string")

    self:_sendPayload(GatewayOpcode.VoiceStateUpdate, {
        guild_id = guildId,
        channel_id = channelId,
        self_deaf = options and options.self_deaf or false,
        self_mute = options and options.self_mute or false,
    })
end

return Gateway
