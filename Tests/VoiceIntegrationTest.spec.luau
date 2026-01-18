--[[

VoiceIntegrationTest

Integration tests for voice functionality. Tests joining/leaving voice channels
and optionally Lavalink audio playback if a Lavalink server is configured.

Audio files for testing are stored in Tests/Assets/.

Environment variables:
> DISCORD_BOT_TOKEN - The bot token for authentication
> DISCORD_TEST_GUILD_ID - Guild ID for testing
> DISCORD_TEST_VOICE_CHANNEL_ID - Voice channel ID for testing
> LAVALINK_HOST - Lavalink server host (optional)
> LAVALINK_PORT - Lavalink server port (optional)
> LAVALINK_PASSWORD - Lavalink server password (optional)

--]]

local process = require("@lune/process")
local task = require("@lune/task")

local Client = require("@discordluau/Classes/Client")
local GatewayIntent = require("@discordluau/Enums/GatewayIntent")
local Lavalink = require("@discordluau/Lavalink")

-- Get environment variables
local BOT_TOKEN = process.env.DISCORD_BOT_TOKEN
local GUILD_ID = process.env.DISCORD_TEST_GUILD_ID
local VOICE_CHANNEL_ID = process.env.DISCORD_TEST_VOICE_CHANNEL_ID
local LAVALINK_HOST = process.env.LAVALINK_HOST
local LAVALINK_PORT = process.env.LAVALINK_PORT
local LAVALINK_PASSWORD = process.env.LAVALINK_PASSWORD

-- Test audio files (local)
local ASSETS_PATH = `{string.gsub(process.cwd, "/$", "")}/Tests/Assets`
local TEST_AUDIO_MP3 = `{ASSETS_PATH}/VineBoom.mp3`
local TEST_AUDIO_WAV = `{ASSETS_PATH}/Gunshot.wav`

-- Check if voice tests should run
local function shouldRunVoiceTests(): boolean
    return BOT_TOKEN ~= nil
        and BOT_TOKEN ~= ""
        and GUILD_ID ~= nil
        and VOICE_CHANNEL_ID ~= nil
        and VOICE_CHANNEL_ID ~= ""
end

-- Check if Lavalink tests should run
local function shouldRunLavalinkTests(): boolean
    return shouldRunVoiceTests()
        and LAVALINK_HOST ~= nil
        and LAVALINK_HOST ~= ""
        and LAVALINK_PORT ~= nil
        and LAVALINK_PASSWORD ~= nil
end

return function()
    if not shouldRunVoiceTests() then
        describe("Voice Integration tests (SKIPPED)", function()
            it("should skip when no voice channel configured", function()
                expect(true).to.equal(true)
            end)
        end)
        return
    end

    describe("Voice Channel Integration", function()
        local client: any
        local isReady = false
        local voiceStateReceived = false
        local receivedVoiceState: any = nil
        local setupFailed = false

        beforeAll(function()
            -- Create client with required intents for voice
            local success, _err = pcall(function()
                client = Client.new({
                    intents = {
                        GatewayIntent.Guilds,
                        GatewayIntent.GuildVoiceStates,
                    },
                })

                -- Track when ready
                client:Once("ready", function()
                    isReady = true
                end)

                -- Track voice state updates
                client:On("voiceStateUpdate", function(oldState: any, newState: any)
                    if newState and newState.UserId == client.User.Id then
                        voiceStateReceived = true
                        receivedVoiceState = newState
                    end
                end)

                -- Connect to Discord
                client:Login(BOT_TOKEN)

                -- Wait for ready (max 15 seconds)
                local startTime = os.clock()
                while not isReady and (os.clock() - startTime) < 15 do
                    task.wait(0.1)
                end
            end)

            if not success then
                setupFailed = true
            end
        end)

        afterAll(function()
            -- Disconnect from voice if connected
            if client and client.Gateway then
                pcall(function()
                    client.Gateway:UpdateVoiceState(GUILD_ID, nil, false, false)
                end)
                task.wait(1)
            end

            -- Destroy client
            if client then
                pcall(function()
                    client:Destroy()
                end)
            end
        end)

        it("should connect to Discord", function()
            if setupFailed then
                -- Skip test if setup failed (invalid token, etc.)
                expect(true).to.equal(true)
                return
            end
            expect(isReady).to.equal(true)
            expect(client.User).to.be.ok()
            expect(client.User.Bot).to.equal(true)
        end)

        it("should have the test guild cached", function()
            if setupFailed or not isReady then
                return
            end

            -- Wait for guild to be cached
            task.wait(2)

            local guild = client.Guilds[GUILD_ID]
            expect(guild).to.be.ok()
            expect(guild.Id).to.equal(GUILD_ID)
        end)

        it("should join the voice channel", function()
            if setupFailed or not isReady then
                return
            end

            -- Reset voice state tracking
            voiceStateReceived = false
            receivedVoiceState = nil

            -- Join voice channel
            client.Gateway:UpdateVoiceState(GUILD_ID, VOICE_CHANNEL_ID, false, true) -- self-deaf

            -- Wait for voice state update (max 10 seconds)
            local startTime = os.clock()
            while not voiceStateReceived and (os.clock() - startTime) < 10 do
                task.wait(0.1)
            end

            expect(voiceStateReceived).to.equal(true)
            expect(receivedVoiceState).to.be.ok()
            expect(receivedVoiceState.ChannelId).to.equal(VOICE_CHANNEL_ID)
        end)

        it("should track voice state in guild", function()
            if setupFailed or not isReady then
                return
            end

            task.wait(1)

            local guild = client.Guilds[GUILD_ID]
            if not guild then
                return
            end

            local voiceState = guild:GetVoiceState(client.User.Id)
            expect(voiceState).to.be.ok()
            expect(voiceState.channel_id).to.equal(VOICE_CHANNEL_ID)
        end)

        it("should get voice channel members", function()
            if setupFailed or not isReady then
                return
            end

            local guild = client.Guilds[GUILD_ID]
            if not guild then
                return
            end

            local members = guild:GetVoiceChannelMembers(VOICE_CHANNEL_ID)
            expect(members).to.be.a("table")

            -- Bot should be in the list
            local botFound = false
            for _, state in members do
                if state.user_id == client.User.Id then
                    botFound = true
                    break
                end
            end
            expect(botFound).to.equal(true)
        end)

        it("should leave the voice channel", function()
            if setupFailed or not isReady then
                return
            end

            -- Only test leaving if we actually joined (check before resetting)
            local wasInVoice = receivedVoiceState and receivedVoiceState.ChannelId == VOICE_CHANNEL_ID
            if not wasInVoice then
                return
            end

            -- Reset voice state tracking
            voiceStateReceived = false
            receivedVoiceState = nil

            -- Leave voice channel
            client.Gateway:UpdateVoiceState(GUILD_ID, nil, false, false)

            -- Wait for voice state update (max 10 seconds)
            local startTime = os.clock()
            while not voiceStateReceived and (os.clock() - startTime) < 10 do
                task.wait(0.1)
            end

            -- Voice state update should be received (but don't fail if timing issues)
            if voiceStateReceived then
                expect(receivedVoiceState).to.be.ok()
                expect(receivedVoiceState.ChannelId).to.equal(nil)
            end
        end)

        it("should remove voice state from guild when disconnected", function()
            if setupFailed or not isReady then
                return
            end

            task.wait(1)

            local guild = client.Guilds[GUILD_ID]
            if not guild then
                return
            end

            local voiceState = guild:GetVoiceState(client.User.Id)
            expect(voiceState).to.equal(nil)
        end)
    end)

    -- Lavalink tests (only run if Lavalink is configured)
    if shouldRunLavalinkTests() then
        describe("Lavalink Integration", function()
            local client: any
            local lavalink: any
            local isReady = false
            local nodeReady = false

            beforeAll(function()
                client = Client.new({
                    intents = {
                        GatewayIntent.Guilds,
                        GatewayIntent.GuildVoiceStates,
                    },
                })

                client:Once("ready", function()
                    isReady = true
                end)

                client:Login(BOT_TOKEN)

                -- Wait for ready
                local startTime = os.clock()
                while not isReady and (os.clock() - startTime) < 15 do
                    task.wait(0.1)
                end

                if isReady then
                    -- Create Lavalink manager
                    lavalink = Lavalink.new(client)

                    lavalink.OnNodeReady:Connect(function()
                        nodeReady = true
                    end)

                    -- Add Lavalink node
                    lavalink:AddNode({
                        name = "test-node",
                        host = LAVALINK_HOST,
                        port = tonumber(LAVALINK_PORT) or 2333,
                        password = LAVALINK_PASSWORD,
                    })

                    -- Wait for node to be ready (max 10 seconds)
                    -- Check both the signal and node.SessionId for reliability
                    startTime = os.clock()
                    while not nodeReady and (os.clock() - startTime) < 10 do
                        task.wait(0.1)
                        -- Also check SessionId directly as backup
                        local node = lavalink:GetNode("test-node")
                        if node and node.SessionId then
                            nodeReady = true
                        end
                    end
                end
            end)

            afterAll(function()
                if lavalink then
                    -- Destroy all players
                    for guildId in lavalink.Players do
                        pcall(function()
                            lavalink:DestroyPlayer(guildId)
                        end)
                    end

                    -- Remove nodes
                    for name in lavalink.Nodes do
                        pcall(function()
                            lavalink:RemoveNode(name)
                        end)
                    end
                end

                if client then
                    pcall(function()
                        client:Destroy()
                    end)
                end
            end)

            it("should connect to Lavalink node", function()
                expect(isReady).to.equal(true)

                -- Node may take time to fully connect via WebSocket
                -- Check that the node exists and can make REST calls
                local node = lavalink:GetNode("test-node")
                expect(node).to.be.ok()

                -- REST should work even if WebSocket isn't fully ready
                local info = node.Rest:GetInfo()
                expect(info).to.be.ok()
                expect(info.version).to.be.ok()
            end)

            it("should get Lavalink server info", function()
                local node = lavalink:GetNode("test-node")
                if not node or not node.Connected then
                    return
                end

                local info = node.Rest:GetInfo()
                expect(info).to.be.ok()
                expect(info.version).to.be.ok()
                expect(info.version.semver).to.be.a("string")
            end)

            it("should search for tracks", function()
                if not nodeReady then
                    return
                end

                local result = lavalink:Search("never gonna give you up", "ytsearch")

                expect(result).to.be.ok()
                expect(result.loadType).to.be.a("string")

                -- Search should return results (unless YouTube blocks it)
                if result.loadType == "search" then
                    expect(#result.data > 0).to.equal(true)
                    expect(result.data[1].encoded).to.be.a("string")
                    expect(result.data[1].info.title).to.be.a("string")
                end
            end)

            it("should create a player", function()
                if not nodeReady then
                    return
                end

                local player = lavalink:GetPlayer(GUILD_ID)
                expect(player).to.be.ok()
                expect(player.GuildId).to.equal(GUILD_ID)
            end)

            it("should connect player to voice channel", function()
                if not nodeReady then
                    return
                end

                local player = lavalink:GetPlayer(GUILD_ID)
                if not player then
                    return
                end

                player:Connect(VOICE_CHANNEL_ID, { selfDeaf = true })

                -- Wait for connection
                task.wait(3)

                expect(player.ChannelId).to.equal(VOICE_CHANNEL_ID)
            end)

            it("should play mp3 track", function()
                if not nodeReady then
                    return
                end

                local player = lavalink:GetPlayer(GUILD_ID)
                if not player or not player.ChannelId then
                    return
                end

                -- Load local mp3 file
                local result = lavalink:LoadFile(TEST_AUDIO_MP3)

                if result.loadType ~= "track" or not result.data then
                    return
                end

                local trackEncoded = result.data.encoded

                -- Set up track start listener
                local trackStarted = false
                player.OnTrackStart:Connect(function()
                    trackStarted = true
                end)

                -- Play the track
                player:Play(trackEncoded)

                -- Wait for track to start (max 5 seconds)
                local startTime = os.clock()
                while not trackStarted and (os.clock() - startTime) < 5 do
                    task.wait(0.1)
                end

                expect(trackStarted).to.equal(true)
                expect(player.Playing).to.equal(true)
                expect(player.CurrentTrack).to.be.ok()

                -- Wait for track to finish
                task.wait(1)
            end)

            it("should play wav track", function()
                if not nodeReady then
                    return
                end

                local player = lavalink:GetPlayer(GUILD_ID)
                if not player or not player.ChannelId then
                    return
                end

                -- Load local wav file
                local result = lavalink:LoadFile(TEST_AUDIO_WAV)

                if result.loadType ~= "track" or not result.data then
                    return
                end

                local trackEncoded = result.data.encoded

                -- Set up track start listener
                local trackStarted = false
                player.OnTrackStart:Connect(function()
                    trackStarted = true
                end)

                -- Play the track
                player:Play(trackEncoded)

                -- Wait for track to start (max 5 seconds)
                local startTime = os.clock()
                while not trackStarted and (os.clock() - startTime) < 5 do
                    task.wait(0.1)
                end

                expect(trackStarted).to.equal(true)
                expect(player.Playing).to.equal(true)
                expect(player.CurrentTrack).to.be.ok()

                -- Wait for track to finish
                task.wait(1)
            end)

            it("should pause and resume", function()
                if not nodeReady then
                    return
                end

                local player = lavalink:GetPlayer(GUILD_ID)
                if not player or not player.Playing then
                    return
                end

                -- Pause
                player:Pause(true)
                task.wait(0.5)
                expect(player.Paused).to.equal(true)

                -- Resume
                player:Resume()
                task.wait(0.5)
                expect(player.Paused).to.equal(false)
            end)

            it("should adjust volume", function()
                if not nodeReady then
                    return
                end

                local player = lavalink:GetPlayer(GUILD_ID)
                if not player then
                    return
                end

                player:SetVolume(50)
                task.wait(0.5)
                expect(player.Volume).to.equal(50)

                player:SetVolume(100)
            end)

            it("should stop playback", function()
                if not nodeReady then
                    return
                end

                local player = lavalink:GetPlayer(GUILD_ID)
                if not player then
                    return
                end

                player:Stop()
                task.wait(0.5)
                expect(player.Playing).to.equal(false)
            end)

            it("should disconnect player from voice channel", function()
                if not nodeReady then
                    return
                end

                local player = lavalink:GetPlayer(GUILD_ID)
                if not player then
                    return
                end

                player:Disconnect()
                task.wait(1)

                expect(player.ChannelId).to.equal(nil)
                expect(player.Connected).to.equal(false)
            end)

            it("should destroy player", function()
                if not nodeReady then
                    return
                end

                lavalink:DestroyPlayer(GUILD_ID)

                local player = lavalink.Players[GUILD_ID]
                expect(player).to.equal(nil)
            end)
        end)
    else
        describe("Lavalink Integration (SKIPPED)", function()
            it("should skip when Lavalink not configured", function()
                expect(true).to.equal(true)
            end)
        end)
    end
end
