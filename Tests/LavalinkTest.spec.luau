--[[

LavalinkTest

Tests for the Lavalink module including Track class and type handling.

--]]

local Track = require("@discordluau/Lavalink/Track")
local MockData = require("./Helpers/MockData")

return function()
    describe("Track.new", function()
        it("should create a track from Lavalink data", function()
            local track = Track.new(MockData.LavalinkTrack)
            expect(track.Title).to.equal("Rick Astley - Never Gonna Give You Up")
            expect(track.Author).to.equal("RickAstleyVEVO")
            expect(track.Identifier).to.equal("dQw4w9WgXcQ")
        end)

        it("should validate data parameter", function()
            expect(function()
                Track.new(nil :: any)
            end).to.throw()
        end)

        it("should validate encoded string", function()
            expect(function()
                Track.new({ info = {} } :: any)
            end).to.throw()
        end)

        it("should validate info table", function()
            expect(function()
                Track.new({ encoded = "test" } :: any)
            end).to.throw()
        end)
    end)

    describe("Track properties", function()
        it("should parse all standard properties", function()
            local track = Track.new(MockData.LavalinkTrack)

            expect(track.Encoded).to.equal(MockData.LavalinkTrack.encoded)
            expect(track.Identifier).to.equal(MockData.LavalinkTrack.info.identifier)
            expect(track.IsSeekable).to.equal(MockData.LavalinkTrack.info.isSeekable)
            expect(track.Author).to.equal(MockData.LavalinkTrack.info.author)
            expect(track.Length).to.equal(MockData.LavalinkTrack.info.length)
            expect(track.IsStream).to.equal(MockData.LavalinkTrack.info.isStream)
            expect(track.Position).to.equal(MockData.LavalinkTrack.info.position)
            expect(track.Title).to.equal(MockData.LavalinkTrack.info.title)
            expect(track.Uri).to.equal(MockData.LavalinkTrack.info.uri)
            expect(track.ArtworkUrl).to.equal(MockData.LavalinkTrack.info.artworkUrl)
            expect(track.SourceName).to.equal(MockData.LavalinkTrack.info.sourceName)
        end)

        it("should store original data", function()
            local track = Track.new(MockData.LavalinkTrack)
            expect(track._data).to.equal(MockData.LavalinkTrack)
        end)
    end)

    describe("GetDurationFormatted", function()
        it("should format duration in minutes and seconds", function()
            local track = Track.new(MockData.LavalinkTrack)
            -- 212000ms = 3 minutes 32 seconds
            expect(track:GetDurationFormatted()).to.equal("3:32")
        end)

        it("should format duration with hours when needed", function()
            local longTrackData = table.clone(MockData.LavalinkTrack)
            longTrackData.info = table.clone(MockData.LavalinkTrack.info)
            longTrackData.info.length = 3661000 -- 1 hour, 1 minute, 1 second
            local track = Track.new(longTrackData)
            expect(track:GetDurationFormatted()).to.equal("1:01:01")
        end)

        it("should return LIVE for streams", function()
            local streamData = table.clone(MockData.LavalinkTrack)
            streamData.info = table.clone(MockData.LavalinkTrack.info)
            streamData.info.isStream = true
            local track = Track.new(streamData)
            expect(track:GetDurationFormatted()).to.equal("LIVE")
        end)

        it("should pad seconds with leading zero", function()
            local shortTrackData = table.clone(MockData.LavalinkTrack)
            shortTrackData.info = table.clone(MockData.LavalinkTrack.info)
            shortTrackData.info.length = 65000 -- 1 minute 5 seconds
            local track = Track.new(shortTrackData)
            expect(track:GetDurationFormatted()).to.equal("1:05")
        end)

        it("should handle zero duration", function()
            local zeroTrackData = table.clone(MockData.LavalinkTrack)
            zeroTrackData.info = table.clone(MockData.LavalinkTrack.info)
            zeroTrackData.info.length = 0
            local track = Track.new(zeroTrackData)
            expect(track:GetDurationFormatted()).to.equal("0:00")
        end)
    end)

    describe("GetDisplayString", function()
        it("should return formatted display string", function()
            local track = Track.new(MockData.LavalinkTrack)
            local expected = "Rick Astley - Never Gonna Give You Up by RickAstleyVEVO [3:32]"
            expect(track:GetDisplayString()).to.equal(expected)
        end)

        it("should include LIVE for streams", function()
            local streamData = table.clone(MockData.LavalinkTrack)
            streamData.info = table.clone(MockData.LavalinkTrack.info)
            streamData.info.isStream = true
            streamData.info.title = "Live Stream"
            streamData.info.author = "Streamer"
            local track = Track.new(streamData)
            expect(track:GetDisplayString()).to.equal("Live Stream by Streamer [LIVE]")
        end)
    end)

    describe("__tostring", function()
        it("should return Track(identifier) format", function()
            local track = Track.new(MockData.LavalinkTrack)
            expect(tostring(track)).to.equal("Track(dQw4w9WgXcQ)")
        end)
    end)

    describe("LoadResult types", function()
        it("should handle track load result", function()
            local result = MockData.LavalinkLoadResultTrack
            expect(result.loadType).to.equal("track")
            expect(result.data.encoded).to.be.ok()
            expect(result.data.info.title).to.be.ok()
        end)

        it("should handle search load result", function()
            local result = MockData.LavalinkLoadResultSearch
            expect(result.loadType).to.equal("search")
            expect(#result.data).to.equal(1)
            expect(result.data[1].encoded).to.be.ok()
        end)

        it("should handle empty load result", function()
            local result = MockData.LavalinkLoadResultEmpty
            expect(result.loadType).to.equal("empty")
            expect(#result.data).to.equal(0)
        end)

        it("should handle error load result", function()
            local result = MockData.LavalinkLoadResultError
            expect(result.loadType).to.equal("error")
            expect(result.data.message).to.equal("Track not found")
            expect(result.data.severity).to.equal("common")
        end)
    end)
end
