--[[

LavalinkRest

REST API client for Lavalink server. Handles track loading, player management,
and server info requests.

--]]

local net = require("@lune/net")
local serde = require("@lune/serde")

local Types = require("./Types")

local LavalinkRest = {}
LavalinkRest.__index = LavalinkRest

export type LavalinkRest = typeof(setmetatable(
    {} :: {
        _baseUrl: string,
        _password: string,
        _sessionId: string?,
    },
    LavalinkRest
))

function LavalinkRest.new(host: string, port: number, password: string, secure: boolean?): LavalinkRest
    assert(type(host) == "string", "Expected host to be a string")
    assert(type(port) == "number", "Expected port to be a number")
    assert(type(password) == "string", "Expected password to be a string")

    local self = setmetatable({}, LavalinkRest)

    local protocol = if secure then "https" else "http"
    self._baseUrl = `{protocol}://{host}:{port}`
    self._password = password
    self._sessionId = nil

    return self
end

function LavalinkRest.SetSessionId(self: LavalinkRest, sessionId: string)
    self._sessionId = sessionId
end

function LavalinkRest._request(
    self: LavalinkRest,
    method: "GET" | "POST" | "PATCH" | "DELETE",
    path: string,
    body: { [string]: any }?
): { success: boolean, data: any?, error: string? }
    local url = `{self._baseUrl}{path}`

    local headers: { [string]: string } = {
        ["Authorization"] = self._password,
        ["Content-Type"] = "application/json",
    }

    local requestOptions: net.FetchParams = {
        url = url,
        method = method,
        headers = headers,
    }

    if body then
        requestOptions.body = serde.encode("json", body)
    end

    local success, response = pcall(net.request, requestOptions)

    if not success then
        return { success = false, error = tostring(response) }
    end

    if not response.ok then
        local errorMessage = `HTTP {response.statusCode}`
        if response.body and #response.body > 0 then
            local decodeSuccess, errorData = pcall(function()
                return serde.decode("json" :: "json", response.body)
            end)
            if decodeSuccess and type(errorData) == "table" and errorData.message then
                errorMessage = `{errorMessage}: {errorData.message}`
            else
                errorMessage = `{errorMessage}: {response.body}`
            end
        end
        return { success = false, error = errorMessage }
    end

    if response.body and #response.body > 0 then
        local decodeSuccess, data = pcall(function()
            return serde.decode("json" :: "json", response.body)
        end)
        if decodeSuccess then
            return { success = true, data = data }
        else
            return { success = false, error = "Failed to decode response JSON" }
        end
    end

    return { success = true, data = nil }
end

--[[
    Loads tracks from Lavalink.

    @param identifier - The track identifier (URL, search query, etc.)
    @return LoadResult with track data or error
]]
function LavalinkRest.LoadTracks(self: LavalinkRest, identifier: string): Types.LoadResult
    assert(type(identifier) == "string", "Expected identifier to be a string")

    local encodedIdentifier = net.urlEncode(identifier)
    local result = self:_request("GET", `/v4/loadtracks?identifier={encodedIdentifier}`)

    if not result.success then
        return {
            loadType = "error",
            data = {
                message = result.error,
                severity = "common",
                cause = "REST request failed",
            },
        }
    end

    return result.data :: Types.LoadResult
end

--[[
    Decodes a track from its encoded string.

    @param encoded - The encoded track string
    @return Track info or nil on error
]]
function LavalinkRest.DecodeTrack(self: LavalinkRest, encoded: string): Types.TrackInfo?
    assert(type(encoded) == "string", "Expected encoded to be a string")

    local encodedTrack = net.urlEncode(encoded)
    local result = self:_request("GET", `/v4/decodetrack?encodedTrack={encodedTrack}`)

    if not result.success then
        return nil
    end

    return result.data :: Types.TrackInfo
end

--[[
    Decodes multiple tracks from their encoded strings.

    @param encodedTracks - Array of encoded track strings
    @return Array of track data
]]
function LavalinkRest.DecodeTracks(self: LavalinkRest, encodedTracks: { string }): { Types.LavalinkTrack }
    assert(type(encodedTracks) == "table", "Expected encodedTracks to be a table")

    local result = self:_request("POST", "/v4/decodetracks", encodedTracks :: any)

    if not result.success then
        return {}
    end

    return result.data :: { Types.LavalinkTrack }
end

--[[
    Gets all players for this session.

    @return Array of player states
]]
function LavalinkRest.GetPlayers(self: LavalinkRest): { Types.LavalinkPlayer }
    if not self._sessionId then
        return {}
    end

    local result = self:_request("GET", `/v4/sessions/{self._sessionId}/players`)

    if not result.success then
        return {}
    end

    return result.data :: { Types.LavalinkPlayer }
end

--[[
    Gets a specific player by guild ID.

    @param guildId - The guild ID
    @return Player state or nil
]]
function LavalinkRest.GetPlayer(self: LavalinkRest, guildId: string): Types.LavalinkPlayer?
    assert(type(guildId) == "string", "Expected guildId to be a string")

    if not self._sessionId then
        return nil
    end

    local result = self:_request("GET", `/v4/sessions/{self._sessionId}/players/{guildId}`)

    if not result.success then
        return nil
    end

    return result.data :: Types.LavalinkPlayer
end

--[[
    Updates a player's state (play, pause, seek, volume, filters, etc.)

    @param guildId - The guild ID
    @param data - The update data
    @param noReplace - If true, don't replace the current track
    @return Updated player state or nil
]]
function LavalinkRest.UpdatePlayer(
    self: LavalinkRest,
    guildId: string,
    data: Types.PlayerUpdateData,
    noReplace: boolean?
): Types.LavalinkPlayer?
    assert(type(guildId) == "string", "Expected guildId to be a string")
    assert(type(data) == "table", "Expected data to be a table")

    if not self._sessionId then
        return nil
    end

    local path = `/v4/sessions/{self._sessionId}/players/{guildId}`
    if noReplace then
        path = `{path}?noReplace=true`
    end

    local result = self:_request("PATCH", path, data)

    if not result.success then
        return nil
    end

    return result.data :: Types.LavalinkPlayer
end

--[[
    Destroys a player for a guild.

    @param guildId - The guild ID
    @return true if successful
]]
function LavalinkRest.DestroyPlayer(self: LavalinkRest, guildId: string): boolean
    assert(type(guildId) == "string", "Expected guildId to be a string")

    if not self._sessionId then
        return false
    end

    local result = self:_request("DELETE", `/v4/sessions/{self._sessionId}/players/{guildId}`)

    return result.success
end

--[[
    Updates the session configuration (resuming).

    @param resuming - Whether to enable session resuming
    @param timeout - The timeout in seconds for resuming
    @return true if successful
]]
function LavalinkRest.UpdateSession(self: LavalinkRest, resuming: boolean?, timeout: number?): boolean
    if not self._sessionId then
        return false
    end

    local body: { [string]: any } = {}
    if resuming ~= nil then
        body.resuming = resuming
    end
    if timeout ~= nil then
        body.timeout = timeout
    end

    local result = self:_request("PATCH", `/v4/sessions/{self._sessionId}`, body)

    return result.success
end

--[[
    Gets Lavalink server info.

    @return Server info or nil
]]
function LavalinkRest.GetInfo(self: LavalinkRest): Types.LavalinkInfo?
    local result = self:_request("GET", "/v4/info")

    if not result.success then
        return nil
    end

    return result.data :: Types.LavalinkInfo
end

--[[
    Gets Lavalink server statistics.

    @return Stats or nil
]]
function LavalinkRest.GetStats(self: LavalinkRest): Types.StatsEvent?
    local result = self:_request("GET", "/v4/stats")

    if not result.success then
        return nil
    end

    return result.data :: Types.StatsEvent
end

--[[
    Gets the Lavalink server version.

    @return Version string or nil
]]
function LavalinkRest.GetVersion(self: LavalinkRest): string?
    local result = self:_request("GET", "/version")

    if not result.success then
        return nil
    end

    -- Version endpoint returns plain text
    return tostring(result.data)
end

--[[
    Searches for tracks using a source prefix.

    @param query - The search query
    @param source - The source to search (ytsearch, scsearch, etc.)
    @return LoadResult with search results
]]
function LavalinkRest.Search(self: LavalinkRest, query: string, source: string?): Types.LoadResult
    assert(type(query) == "string", "Expected query to be a string")

    local searchPrefix = source or "ytsearch"
    local identifier = `{searchPrefix}:{query}`

    return self:LoadTracks(identifier)
end

function LavalinkRest.__tostring(self: LavalinkRest): string
    return `LavalinkRest({self._baseUrl})`
end

return LavalinkRest
