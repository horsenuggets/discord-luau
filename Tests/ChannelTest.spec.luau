--[[

ChannelTest

Tests for the Channel structure class.

--]]

const Channel = require("@discordluau/Structures/Channel")
const MockClient = require("./Helpers/MockClient")
const MockData = require("./Helpers/MockData")
const TestUtils = require("./Helpers/TestUtils")

return function()
    local client

    beforeAll(function()
        client = MockClient.newWithData()
    end)

    describe("Channel.new", function()
        it("should create a channel from API data", function()
            const channel = Channel.new(client, MockData.TextChannel)
            expect(channel.Id).to.equal(MockData.Snowflakes.ChannelId)
            expect(channel.Name).to.equal("general")
        end)

        it("should validate client parameter", function()
            expect(function()
                Channel.new(nil :: any, MockData.TextChannel)
            end).to.throw()
        end)

        it("should validate data parameter", function()
            expect(function()
                Channel.new(client, nil :: any)
            end).to.throw()
        end)

        it("should accept optional guild parameter", function()
            const guild = { Id = MockData.Snowflakes.GuildId }
            const channel = Channel.new(client, MockData.TextChannel, guild)
            expect(channel.Guild).to.equal(guild)
        end)
    end)

    describe("Channel properties", function()
        it("should parse text channel properties", function()
            const channel = Channel.new(client, MockData.TextChannel)

            expect(channel.Id).to.equal(MockData.TextChannel.id)
            expect(channel.Type).to.equal(0)
            expect(channel.GuildId).to.equal(MockData.TextChannel.guild_id)
            expect(channel.Position).to.equal(MockData.TextChannel.position)
            expect(channel.Name).to.equal(MockData.TextChannel.name)
            expect(channel.Topic).to.equal(MockData.TextChannel.topic)
            expect(channel.Nsfw).to.equal(false)
            expect(channel.RateLimitPerUser).to.equal(MockData.TextChannel.rate_limit_per_user)
        end)

        it("should parse voice channel properties", function()
            const channel = Channel.new(client, MockData.VoiceChannel)

            expect(channel.Type).to.equal(2)
            expect(channel.Bitrate).to.equal(MockData.VoiceChannel.bitrate)
            expect(channel.UserLimit).to.equal(MockData.VoiceChannel.user_limit)
            expect(channel.RtcRegion).to.equal(MockData.VoiceChannel.rtc_region)
        end)

        it("should parse DM channel properties", function()
            const channel = Channel.new(client, MockData.DMChannel)

            expect(channel.Type).to.equal(1)
            expect(channel.GuildId).to.equal(nil)
            expect(channel.Recipients).to.be.a("table")
        end)
    end)

    describe("IsText", function()
        it("should return true for text channels", function()
            const channel = Channel.new(client, MockData.TextChannel)
            expect(channel:IsText()).to.equal(true)
        end)

        it("should return true for DM channels", function()
            const channel = Channel.new(client, MockData.DMChannel)
            expect(channel:IsText()).to.equal(true)
        end)

        it("should return false for voice channels", function()
            const channel = Channel.new(client, MockData.VoiceChannel)
            expect(channel:IsText()).to.equal(false)
        end)

        it("should return true for announcement channels (type 5)", function()
            const channelData = table.clone(MockData.TextChannel)
            channelData.type = 5
            const channel = Channel.new(client, channelData)
            expect(channel:IsText()).to.equal(true)
        end)

        it("should return true for thread channels", function()
            const threadTypes = { 10, 11, 12 }
            for _, threadType in threadTypes do
                const channelData = table.clone(MockData.TextChannel)
                channelData.type = threadType
                const channel = Channel.new(client, channelData)
                expect(channel:IsText()).to.equal(true)
            end
        end)
    end)

    describe("IsVoice", function()
        it("should return true for voice channels", function()
            const channel = Channel.new(client, MockData.VoiceChannel)
            expect(channel:IsVoice()).to.equal(true)
        end)

        it("should return true for stage channels (type 13)", function()
            const channelData = table.clone(MockData.VoiceChannel)
            channelData.type = 13
            const channel = Channel.new(client, channelData)
            expect(channel:IsVoice()).to.equal(true)
        end)

        it("should return false for text channels", function()
            const channel = Channel.new(client, MockData.TextChannel)
            expect(channel:IsVoice()).to.equal(false)
        end)
    end)

    describe("IsCategory", function()
        it("should return true for category channels", function()
            const channelData = table.clone(MockData.TextChannel)
            channelData.type = 4
            const channel = Channel.new(client, channelData)
            expect(channel:IsCategory()).to.equal(true)
        end)

        it("should return false for text channels", function()
            const channel = Channel.new(client, MockData.TextChannel)
            expect(channel:IsCategory()).to.equal(false)
        end)
    end)

    describe("IsThread", function()
        it("should return true for announcement threads (type 10)", function()
            const channelData = table.clone(MockData.TextChannel)
            channelData.type = 10
            const channel = Channel.new(client, channelData)
            expect(channel:IsThread()).to.equal(true)
        end)

        it("should return true for public threads (type 11)", function()
            const channelData = table.clone(MockData.TextChannel)
            channelData.type = 11
            const channel = Channel.new(client, channelData)
            expect(channel:IsThread()).to.equal(true)
        end)

        it("should return true for private threads (type 12)", function()
            const channelData = table.clone(MockData.TextChannel)
            channelData.type = 12
            const channel = Channel.new(client, channelData)
            expect(channel:IsThread()).to.equal(true)
        end)

        it("should return false for text channels", function()
            const channel = Channel.new(client, MockData.TextChannel)
            expect(channel:IsThread()).to.equal(false)
        end)
    end)

    describe("IsForum", function()
        it("should return true for forum channels", function()
            const channelData = table.clone(MockData.TextChannel)
            channelData.type = 15
            const channel = Channel.new(client, channelData)
            expect(channel:IsForum()).to.equal(true)
        end)

        it("should return false for text channels", function()
            const channel = Channel.new(client, MockData.TextChannel)
            expect(channel:IsForum()).to.equal(false)
        end)
    end)

    describe("IsMedia", function()
        it("should return true for media channels", function()
            const channelData = table.clone(MockData.TextChannel)
            channelData.type = 16
            const channel = Channel.new(client, channelData)
            expect(channel:IsMedia()).to.equal(true)
        end)

        it("should return false for text channels", function()
            const channel = Channel.new(client, MockData.TextChannel)
            expect(channel:IsMedia()).to.equal(false)
        end)
    end)

    describe("IsDM", function()
        it("should return true for DM channels", function()
            const channel = Channel.new(client, MockData.DMChannel)
            expect(channel:IsDM()).to.equal(true)
        end)

        it("should return true for group DM channels (type 3)", function()
            const channelData = table.clone(MockData.DMChannel)
            channelData.type = 3
            const channel = Channel.new(client, channelData)
            expect(channel:IsDM()).to.equal(true)
        end)

        it("should return false for text channels", function()
            const channel = Channel.new(client, MockData.TextChannel)
            expect(channel:IsDM()).to.equal(false)
        end)
    end)

    describe("IsGuildBased", function()
        it("should return true for guild channels", function()
            const channel = Channel.new(client, MockData.TextChannel)
            expect(channel:IsGuildBased()).to.equal(true)
        end)

        it("should return false for DM channels", function()
            const channel = Channel.new(client, MockData.DMChannel)
            expect(channel:IsGuildBased()).to.equal(false)
        end)
    end)

    describe("Send", function()
        it("should send a message with string content", function()
            const channel = Channel.new(client, MockData.TextChannel)
            const message = channel:Send("Hello, world!")

            expect(message).to.be.ok()
            const calls = client.Rest:getCalls()
            expect(#calls > 0).to.equal(true)

            const lastCall = calls[#calls]
            expect(lastCall.method).to.equal("POST")
            expect(lastCall.body.content).to.equal("Hello, world!")
        end)

        it("should send a message with options table", function()
            const channel = Channel.new(client, MockData.TextChannel)
            channel:Send({ content = "Test message", tts = true })

            const calls = client.Rest:getCalls()
            const lastCall = calls[#calls]
            expect(lastCall.body.content).to.equal("Test message")
            expect(lastCall.body.tts).to.equal(true)
        end)

        it("should throw error for non-text channels", function()
            const channel = Channel.new(client, MockData.VoiceChannel)
            expect(function()
                channel:Send("Hello")
            end).to.throw()
        end)
    end)

    describe("GetIconUrl", function()
        it("should return nil if no icon", function()
            const channel = Channel.new(client, MockData.TextChannel)
            expect(channel:GetIconUrl()).to.equal(nil)
        end)

        it("should return icon URL if icon exists", function()
            const channelData = table.clone(MockData.DMChannel)
            channelData.icon = "channel_icon_hash"
            const channel = Channel.new(client, channelData)

            const url = channel:GetIconUrl()
            expect(url).to.be.a("string")
            expect(TestUtils.contains(url, "cdn.discordapp.com/channel-icons")).to.equal(true)
        end)
    end)

    describe("GetUrl", function()
        it("should return guild channel URL", function()
            const channel = Channel.new(client, MockData.TextChannel)
            const url = channel:GetUrl()

            expect(url).to.equal(
                `https://discord.com/channels/{MockData.TextChannel.guild_id}/{MockData.TextChannel.id}`
            )
        end)

        it("should return DM channel URL", function()
            const channel = Channel.new(client, MockData.DMChannel)
            const url = channel:GetUrl()

            expect(url).to.equal(`https://discord.com/channels/@me/{MockData.DMChannel.id}`)
        end)
    end)

    describe("ToString", function()
        it("should return channel mention format", function()
            const channel = Channel.new(client, MockData.TextChannel)
            expect(channel:ToString()).to.equal(`<#{MockData.TextChannel.id}>`)
        end)
    end)

    describe("__tostring", function()
        it("should return Channel(id) format", function()
            const channel = Channel.new(client, MockData.TextChannel)
            expect(tostring(channel)).to.equal(`Channel({MockData.TextChannel.id})`)
        end)
    end)
end
