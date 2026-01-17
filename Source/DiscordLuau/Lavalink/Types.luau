--[[

Types

Type definitions for Lavalink API structures and responses.

--]]

local DiscordTypes = require("@discordluau/Structures/Types")

export type TrackInfo = {
    identifier: string,
    isSeekable: boolean,
    author: string,
    length: number,
    isStream: boolean,
    position: number,
    title: string,
    uri: string?,
    artworkUrl: string?,
    isrc: string?,
    sourceName: string,
}

export type LavalinkTrack = {
    encoded: string,
    info: TrackInfo,
    pluginInfo: { [string]: any },
    userData: { [string]: any }?,
}

export type PlaylistInfo = {
    name: string,
    selectedTrack: number,
}

export type LoadResultTrack = {
    loadType: "track",
    data: LavalinkTrack,
}

export type LoadResultPlaylist = {
    loadType: "playlist",
    data: {
        info: PlaylistInfo,
        pluginInfo: { [string]: any },
        tracks: { LavalinkTrack },
    },
}

export type LoadResultSearch = {
    loadType: "search",
    data: { LavalinkTrack },
}

export type LoadResultEmpty = {
    loadType: "empty",
    data: {},
}

export type LoadResultError = {
    loadType: "error",
    data: {
        message: string?,
        severity: string,
        cause: string,
    },
}

export type LoadResult = LoadResultTrack | LoadResultPlaylist | LoadResultSearch | LoadResultEmpty | LoadResultError

export type PlayerState = {
    time: number,
    position: number,
    connected: boolean,
    ping: number,
}

export type VoiceState = {
    token: string,
    endpoint: string,
    sessionId: string,
}

export type Filters = {
    volume: number?,
    equalizer: { { band: number, gain: number } }?,
    karaoke: { level: number?, monoLevel: number?, filterBand: number?, filterWidth: number? }?,
    timescale: { speed: number?, pitch: number?, rate: number? }?,
    tremolo: { frequency: number?, depth: number? }?,
    vibrato: { frequency: number?, depth: number? }?,
    rotation: { rotationHz: number? }?,
    distortion: { sinOffset: number?, sinScale: number?, cosOffset: number?, cosScale: number?, tanOffset: number?, tanScale: number?, offset: number?, scale: number? }?,
    channelMix: { leftToLeft: number?, leftToRight: number?, rightToLeft: number?, rightToRight: number? }?,
    lowPass: { smoothing: number? }?,
}

export type LavalinkPlayer = {
    guildId: string,
    track: LavalinkTrack?,
    volume: number,
    paused: boolean,
    state: PlayerState,
    voice: VoiceState,
    filters: Filters,
}

export type PlayerUpdateData = {
    track: { encoded: string?, identifier: string? }?,
    position: number?,
    endTime: number?,
    volume: number?,
    paused: boolean?,
    filters: Filters?,
    voice: VoiceState?,
}

-- WebSocket events
export type ReadyEvent = {
    op: "ready",
    resumed: boolean,
    sessionId: string,
}

export type PlayerUpdateEvent = {
    op: "playerUpdate",
    guildId: string,
    state: PlayerState,
}

export type StatsEvent = {
    op: "stats",
    players: number,
    playingPlayers: number,
    uptime: number,
    memory: {
        free: number,
        used: number,
        allocated: number,
        reservable: number,
    },
    cpu: {
        cores: number,
        systemLoad: number,
        lavalinkLoad: number,
    },
    frameStats: {
        sent: number,
        nulled: number,
        deficit: number,
    }?,
}

export type TrackStartEvent = {
    op: "event",
    type: "TrackStartEvent",
    guildId: string,
    track: LavalinkTrack,
}

export type TrackEndEvent = {
    op: "event",
    type: "TrackEndEvent",
    guildId: string,
    track: LavalinkTrack,
    reason: "finished" | "loadFailed" | "stopped" | "replaced" | "cleanup",
}

export type TrackExceptionEvent = {
    op: "event",
    type: "TrackExceptionEvent",
    guildId: string,
    track: LavalinkTrack,
    exception: {
        message: string?,
        severity: string,
        cause: string,
    },
}

export type TrackStuckEvent = {
    op: "event",
    type: "TrackStuckEvent",
    guildId: string,
    track: LavalinkTrack,
    thresholdMs: number,
}

export type WebSocketClosedEvent = {
    op: "event",
    type: "WebSocketClosedEvent",
    guildId: string,
    code: number,
    reason: string,
    byRemote: boolean,
}

export type LavalinkEvent = TrackStartEvent | TrackEndEvent | TrackExceptionEvent | TrackStuckEvent | WebSocketClosedEvent

export type NodeOptions = {
    name: string,
    host: string,
    port: number,
    password: string,
    secure: boolean?,
    resumeKey: string?,
    resumeTimeout: number?,
}

export type LavalinkInfo = {
    version: {
        semver: string,
        major: number,
        minor: number,
        patch: number,
        preRelease: string?,
        build: string?,
    },
    buildTime: number,
    git: {
        branch: string,
        commit: string,
        commitTime: number,
    },
    jvm: string,
    lavaplayer: string,
    sourceManagers: { string },
    filters: { string },
    plugins: { { name: string, version: string } },
}

return nil
