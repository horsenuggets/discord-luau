--[[

Track

Represents an audio track from Lavalink with metadata like title, author, duration, etc.

--]]

local Types = require("./Types")

local Track = {}
Track.__index = Track

export type Track = typeof(setmetatable(
    {} :: {
        ArtworkUrl: string?,
        Author: string,
        Encoded: string,
        Identifier: string,
        IsSeekable: boolean,
        IsStream: boolean,
        Isrc: string?,
        Length: number,
        Position: number,
        SourceName: string,
        Title: string,
        Uri: string?,
        _data: Types.LavalinkTrack,
    },
    Track
))

function Track.new(data: Types.LavalinkTrack): Track
    assert(type(data) == "table", "Expected data to be a table")
    assert(type(data.encoded) == "string", "Expected data.encoded to be a string")
    assert(type(data.info) == "table", "Expected data.info to be a table")

    local self = setmetatable({}, Track)

    self._data = data
    self.Encoded = data.encoded
    self.ArtworkUrl = data.info.artworkUrl
    self.Author = data.info.author
    self.Identifier = data.info.identifier
    self.IsSeekable = data.info.isSeekable
    self.IsStream = data.info.isStream
    self.Isrc = data.info.isrc
    self.Length = data.info.length
    self.Position = data.info.position
    self.SourceName = data.info.sourceName
    self.Title = data.info.title
    self.Uri = data.info.uri

    return self
end

function Track.GetDurationFormatted(self: Track): string
    if self.IsStream then
        return "LIVE"
    end

    local totalSeconds = math.floor(self.Length / 1000)
    local hours = math.floor(totalSeconds / 3600)
    local minutes = math.floor((totalSeconds % 3600) / 60)
    local seconds = totalSeconds % 60

    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, seconds)
    else
        return string.format("%d:%02d", minutes, seconds)
    end
end

function Track.GetDisplayString(self: Track): string
    return `{self.Title} by {self.Author} [{self:GetDurationFormatted()}]`
end

function Track.__tostring(self: Track): string
    return `Track({self.Identifier})`
end

return Track
