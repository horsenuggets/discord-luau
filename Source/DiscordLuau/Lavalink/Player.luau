--[[

Player

Per-guild audio player for Lavalink. Handles playback control, voice connection,
and track management for a single guild.

--]]

local Signal = require("../Utils/Signal")

local Track = require("./Track")
local Types = require("./Types")

local Player = {}
Player.__index = Player

export type PlayerOptions = {
    volume: number?,
    selfDeaf: boolean?,
    selfMute: boolean?,
}

export type PlayOptions = {
    startTime: number?,
    endTime: number?,
    volume: number?,
    paused: boolean?,
    noReplace: boolean?,
}

export type Player = typeof(setmetatable(
    {} :: {
        GuildId: string,
        ChannelId: string?,
        Connected: boolean,
        Playing: boolean,
        Paused: boolean,
        Volume: number,
        Position: number,
        Ping: number,
        CurrentTrack: Track.Track?,

        OnTrackStart: Signal.Signal<Track.Track>,
        OnTrackEnd: Signal.Signal<Track.Track, string>,
        OnTrackException: Signal.Signal<Track.Track, { message: string?, severity: string, cause: string }>,
        OnTrackStuck: Signal.Signal<Track.Track, number>,

        _node: any, -- LavalinkNode (circular reference)
        _manager: any, -- Lavalink manager (circular reference)
        _voiceState: Types.VoiceState?,
        _selfDeaf: boolean,
        _selfMute: boolean,
    },
    Player
))

function Player.new(guildId: string, node: any, manager: any): Player
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(node) == "table", "Expected node to be a table")
    assert(type(manager) == "table", "Expected manager to be a table")

    local self = setmetatable({}, Player)

    self.GuildId = guildId
    self.ChannelId = nil
    self.Connected = false
    self.Playing = false
    self.Paused = false
    self.Volume = 100
    self.Position = 0
    self.Ping = 0
    self.CurrentTrack = nil

    -- Signals for track events
    self.OnTrackStart = Signal.new()
    self.OnTrackEnd = Signal.new()
    self.OnTrackException = Signal.new()
    self.OnTrackStuck = Signal.new()

    self._node = node
    self._manager = manager
    self._voiceState = nil
    self._selfDeaf = true
    self._selfMute = false

    return self
end

--[[
    Connects the player to a voice channel.

    @param channelId - The voice channel ID to connect to
    @param options - Connection options (selfDeaf, selfMute)
]]
function Player.Connect(self: Player, channelId: string, options: PlayerOptions?)
    assert(type(channelId) == "string", "Expected channelId to be a string")

    self.ChannelId = channelId

    if options then
        if options.selfDeaf ~= nil then
            self._selfDeaf = options.selfDeaf
        end
        if options.selfMute ~= nil then
            self._selfMute = options.selfMute
        end
        if options.volume ~= nil then
            self.Volume = options.volume
        end
    end

    -- Send voice state update through the Discord gateway
    self._manager:_sendVoiceUpdate(self.GuildId, channelId, self._selfDeaf, self._selfMute)
end

--[[
    Disconnects the player from the voice channel.
]]
function Player.Disconnect(self: Player)
    self.ChannelId = nil
    self.Connected = false
    self._voiceState = nil

    -- Send voice state update to leave channel
    self._manager:_sendVoiceUpdate(self.GuildId, nil, false, false)

    -- Destroy the Lavalink player
    self._node.Rest:DestroyPlayer(self.GuildId)
end

--[[
    Plays a track.

    @param track - The track to play (Track object or encoded string)
    @param options - Play options (startTime, endTime, volume, paused, noReplace)
]]
function Player.Play(self: Player, track: Track.Track | string, options: PlayOptions?)
    local encoded: string
    if type(track) == "string" then
        encoded = track
    else
        encoded = track.Encoded
    end

    local updateData: Types.PlayerUpdateData = {
        track = { encoded = encoded },
    }

    if options then
        if options.startTime then
            updateData.position = options.startTime
        end
        if options.endTime then
            updateData.endTime = options.endTime
        end
        if options.volume then
            updateData.volume = options.volume
        end
        if options.paused ~= nil then
            updateData.paused = options.paused
        end
    end

    local noReplace = options and options.noReplace or false

    self._node.Rest:UpdatePlayer(self.GuildId, updateData, noReplace)
    self.Playing = true
    self.Paused = false
end

--[[
    Stops playback and clears the current track.
]]
function Player.Stop(self: Player)
    -- In Lavalink v4, sending track with encoded = json null stops playback
    -- We use a special marker that LavalinkRest will handle
    self._node.Rest:UpdatePlayer(self.GuildId, {
        track = { encoded = nil :: any },
    })

    self.Playing = false
    self.CurrentTrack = nil
end

--[[
    Pauses or resumes playback.

    @param paused - Whether to pause (true) or resume (false)
]]
function Player.Pause(self: Player, paused: boolean?)
    local shouldPause = if paused ~= nil then paused else not self.Paused

    self._node.Rest:UpdatePlayer(self.GuildId, {
        paused = shouldPause,
    })

    self.Paused = shouldPause
end

--[[
    Resumes playback.
]]
function Player.Resume(self: Player)
    self:Pause(false)
end

--[[
    Seeks to a position in the current track.

    @param position - Position in milliseconds
]]
function Player.Seek(self: Player, position: number)
    assert(type(position) == "number", "Expected position to be a number")

    self._node.Rest:UpdatePlayer(self.GuildId, {
        position = math.max(0, position),
    })

    self.Position = position
end

--[[
    Sets the player volume.

    @param volume - Volume level (0-1000, default range is 0-100)
]]
function Player.SetVolume(self: Player, volume: number)
    assert(type(volume) == "number", "Expected volume to be a number")

    local clampedVolume = math.clamp(volume, 0, 1000)

    self._node.Rest:UpdatePlayer(self.GuildId, {
        volume = clampedVolume,
    })

    self.Volume = clampedVolume
end

--[[
    Sets audio filters on the player.

    @param filters - The filters to apply
]]
function Player.SetFilters(self: Player, filters: Types.Filters)
    assert(type(filters) == "table", "Expected filters to be a table")

    self._node.Rest:UpdatePlayer(self.GuildId, {
        filters = filters,
    })
end

--[[
    Clears all audio filters.
]]
function Player.ClearFilters(self: Player)
    self:SetFilters({})
end

--[[
    Updates the player state from Lavalink.

    @param state - The player state from Lavalink
]]
function Player._updateState(self: Player, state: Types.PlayerState)
    self.Position = state.position
    self.Connected = state.connected
    self.Ping = state.ping
end

--[[
    Called when a track starts playing.

    @param trackData - The track data from Lavalink
]]
function Player._onTrackStart(self: Player, trackData: Types.LavalinkTrack)
    self.CurrentTrack = Track.new(trackData)
    self.Playing = true
    self.Paused = false
    self.OnTrackStart:Fire(self.CurrentTrack)
end

--[[
    Called when a track ends.

    @param trackData - The track data from Lavalink
    @param reason - The reason the track ended
]]
function Player._onTrackEnd(self: Player, trackData: Types.LavalinkTrack, reason: string)
    local track = Track.new(trackData)
    self.Playing = false

    if reason == "finished" or reason == "stopped" then
        self.CurrentTrack = nil
    end

    self.OnTrackEnd:Fire(track, reason)
end

--[[
    Called when a track throws an exception.

    @param trackData - The track data from Lavalink
    @param exception - The exception details
]]
function Player._onTrackException(
    self: Player,
    trackData: Types.LavalinkTrack,
    exception: { message: string?, severity: string, cause: string }
)
    local track = Track.new(trackData)
    self.OnTrackException:Fire(track, exception)
end

--[[
    Called when a track gets stuck.

    @param trackData - The track data from Lavalink
    @param thresholdMs - The threshold in milliseconds
]]
function Player._onTrackStuck(self: Player, trackData: Types.LavalinkTrack, thresholdMs: number)
    local track = Track.new(trackData)
    self.OnTrackStuck:Fire(track, thresholdMs)
end

--[[
    Sets the voice state for Lavalink.

    @param voiceState - The voice state from Discord
]]
function Player._setVoiceState(self: Player, voiceState: Types.VoiceState)
    self._voiceState = voiceState
    self:_sendVoiceUpdate()
end

--[[
    Sends the voice update to Lavalink if we have both token and sessionId.
]]
function Player._sendVoiceUpdate(self: Player)
    if not self._voiceState then
        return
    end

    if not self._voiceState.token or not self._voiceState.endpoint or not self._voiceState.sessionId then
        return
    end

    self._node.Rest:UpdatePlayer(self.GuildId, {
        voice = {
            token = self._voiceState.token,
            endpoint = self._voiceState.endpoint,
            sessionId = self._voiceState.sessionId,
        },
    })

    self.Connected = true
end

function Player.__tostring(self: Player): string
    local status = if self.Playing then "playing" else "idle"
    local channel = self.ChannelId or "none"
    return `Player({self.GuildId}, {status}, channel={channel})`
end

return Player
