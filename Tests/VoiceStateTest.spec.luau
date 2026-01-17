--[[

VoiceStateTest

Tests for the VoiceState structure class.

--]]

local Guild = require("@discordluau/Structures/Guild")
local VoiceState = require("@discordluau/Structures/VoiceState")
local MockClient = require("./Helpers/MockClient")
local MockData = require("./Helpers/MockData")

return function()
    local client
    local guild

    beforeAll(function()
        client = MockClient.new()
        guild = Guild.new(client, MockData.Guild)
    end)

    describe("VoiceState.new", function()
        it("should create a voice state from API data", function()
            local voiceState = VoiceState.new(client, MockData.VoiceState, guild)
            expect(voiceState.UserId).to.equal(MockData.Snowflakes.UserId)
            expect(voiceState.GuildId).to.equal(MockData.Snowflakes.GuildId)
            expect(voiceState.SessionId).to.equal("mock_voice_session_id_12345")
        end)

        it("should validate client parameter", function()
            expect(function()
                VoiceState.new(nil :: any, MockData.VoiceState, guild)
            end).to.throw()
        end)

        it("should validate data parameter", function()
            expect(function()
                VoiceState.new(client, nil :: any, guild)
            end).to.throw()
        end)

        it("should work without guild parameter", function()
            local voiceState = VoiceState.new(client, MockData.VoiceState, nil)
            expect(voiceState.Guild).to.equal(nil)
            expect(voiceState.GuildId).to.equal(MockData.Snowflakes.GuildId)
        end)
    end)

    describe("VoiceState properties", function()
        it("should parse all standard properties", function()
            local voiceState = VoiceState.new(client, MockData.VoiceState, guild)

            expect(voiceState.ChannelId).to.equal(MockData.VoiceState.channel_id)
            expect(voiceState.UserId).to.equal(MockData.VoiceState.user_id)
            expect(voiceState.SessionId).to.equal(MockData.VoiceState.session_id)
            expect(voiceState.Deaf).to.equal(false)
            expect(voiceState.Mute).to.equal(false)
            expect(voiceState.SelfDeaf).to.equal(false)
            expect(voiceState.SelfMute).to.equal(false)
            expect(voiceState.SelfStream).to.equal(false)
            expect(voiceState.SelfVideo).to.equal(false)
            expect(voiceState.Suppress).to.equal(false)
        end)

        it("should parse muted state correctly", function()
            local voiceState = VoiceState.new(client, MockData.VoiceStateMuted, guild)

            expect(voiceState.Deaf).to.equal(true)
            expect(voiceState.Mute).to.equal(true)
            expect(voiceState.SelfMute).to.equal(true)
        end)

        it("should store guild reference", function()
            local voiceState = VoiceState.new(client, MockData.VoiceState, guild)
            expect(voiceState.Guild).to.equal(guild)
            expect(voiceState.GuildId).to.equal(guild.Id)
        end)
    end)

    describe("IsConnected", function()
        it("should return true when connected to a channel", function()
            local voiceState = VoiceState.new(client, MockData.VoiceState, guild)
            expect(voiceState:IsConnected()).to.equal(true)
        end)

        it("should return false when disconnected", function()
            local voiceState = VoiceState.new(client, MockData.VoiceStateDisconnected, guild)
            expect(voiceState:IsConnected()).to.equal(false)
        end)
    end)

    describe("IsMuted", function()
        it("should return false when not muted", function()
            local voiceState = VoiceState.new(client, MockData.VoiceState, guild)
            expect(voiceState:IsMuted()).to.equal(false)
        end)

        it("should return true when server muted", function()
            local mutedData = table.clone(MockData.VoiceState)
            mutedData.mute = true
            local voiceState = VoiceState.new(client, mutedData, guild)
            expect(voiceState:IsMuted()).to.equal(true)
        end)

        it("should return true when self muted", function()
            local selfMutedData = table.clone(MockData.VoiceState)
            selfMutedData.self_mute = true
            local voiceState = VoiceState.new(client, selfMutedData, guild)
            expect(voiceState:IsMuted()).to.equal(true)
        end)

        it("should return true when both server and self muted", function()
            local voiceState = VoiceState.new(client, MockData.VoiceStateMuted, guild)
            expect(voiceState:IsMuted()).to.equal(true)
        end)
    end)

    describe("IsDeafened", function()
        it("should return false when not deafened", function()
            local voiceState = VoiceState.new(client, MockData.VoiceState, guild)
            expect(voiceState:IsDeafened()).to.equal(false)
        end)

        it("should return true when server deafened", function()
            local deafenedData = table.clone(MockData.VoiceState)
            deafenedData.deaf = true
            local voiceState = VoiceState.new(client, deafenedData, guild)
            expect(voiceState:IsDeafened()).to.equal(true)
        end)

        it("should return true when self deafened", function()
            local selfDeafenedData = table.clone(MockData.VoiceState)
            selfDeafenedData.self_deaf = true
            local voiceState = VoiceState.new(client, selfDeafenedData, guild)
            expect(voiceState:IsDeafened()).to.equal(true)
        end)
    end)

    describe("IsStreaming", function()
        it("should return false when not streaming", function()
            local voiceState = VoiceState.new(client, MockData.VoiceState, guild)
            expect(voiceState:IsStreaming()).to.equal(false)
        end)

        it("should return true when streaming", function()
            local streamingData = table.clone(MockData.VoiceState)
            streamingData.self_stream = true
            local voiceState = VoiceState.new(client, streamingData, guild)
            expect(voiceState:IsStreaming()).to.equal(true)
        end)
    end)

    describe("IsSuppressed", function()
        it("should return false when not suppressed", function()
            local voiceState = VoiceState.new(client, MockData.VoiceState, guild)
            expect(voiceState:IsSuppressed()).to.equal(false)
        end)

        it("should return true when suppressed", function()
            local suppressedData = table.clone(MockData.VoiceState)
            suppressedData.suppress = true
            local voiceState = VoiceState.new(client, suppressedData, guild)
            expect(voiceState:IsSuppressed()).to.equal(true)
        end)
    end)

    describe("GetChannel", function()
        it("should return nil when not connected", function()
            local voiceState = VoiceState.new(client, MockData.VoiceStateDisconnected, guild)
            expect(voiceState:GetChannel()).to.equal(nil)
        end)

        -- Channel lookup requires guild cache, tested in integration tests
    end)

    describe("GetGuild", function()
        it("should return guild when set", function()
            local voiceState = VoiceState.new(client, MockData.VoiceState, guild)
            expect(voiceState:GetGuild()).to.equal(guild)
        end)

        it("should return nil when guild not set and not in cache", function()
            local voiceState = VoiceState.new(client, MockData.VoiceState, nil)
            expect(voiceState:GetGuild()).to.equal(nil)
        end)
    end)

    describe("__tostring", function()
        it("should return VoiceState(userId in channelId) format when connected", function()
            local voiceState = VoiceState.new(client, MockData.VoiceState, guild)
            local str = tostring(voiceState)
            expect(str).to.equal(`VoiceState({MockData.VoiceState.user_id} in {MockData.VoiceState.channel_id})`)
        end)

        it("should return VoiceState(userId in none) when disconnected", function()
            local voiceState = VoiceState.new(client, MockData.VoiceStateDisconnected, guild)
            local str = tostring(voiceState)
            expect(str).to.equal(`VoiceState({MockData.VoiceState.user_id} in none)`)
        end)
    end)
end
