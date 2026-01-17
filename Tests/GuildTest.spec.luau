--[[

GuildTest

Tests for the Guild structure class.

--]]

local Guild = require("@discordluau/Structures/Guild")
local MockClient = require("./Helpers/MockClient")
local MockData = require("./Helpers/MockData")
local TestUtils = require("./Helpers/TestUtils")

return function()
    local client

    beforeAll(function()
        client = MockClient.new()
    end)

    describe("Guild.new", function()
        it("should create a guild from API data", function()
            local guild = Guild.new(client, MockData.Guild)
            expect(guild.Id).to.equal(MockData.Snowflakes.GuildId)
            expect(guild.Name).to.equal("Test Server")
        end)

        it("should validate client parameter", function()
            expect(function()
                Guild.new(nil :: any, MockData.Guild)
            end).to.throw()
        end)

        it("should validate data parameter", function()
            expect(function()
                Guild.new(client, nil :: any)
            end).to.throw()
        end)

        it("should initialize empty collections", function()
            local guild = Guild.new(client, MockData.Guild)
            expect(guild.Channels).to.be.a("table")
            expect(guild.Members).to.be.a("table")
            expect(guild.Roles).to.be.a("table")
        end)
    end)

    describe("Guild properties", function()
        it("should parse all standard properties", function()
            local guild = Guild.new(client, MockData.Guild)

            expect(guild.Id).to.equal(MockData.Guild.id)
            expect(guild.Name).to.equal(MockData.Guild.name)
            expect(guild.Icon).to.equal(MockData.Guild.icon)
            expect(guild.OwnerId).to.equal(MockData.Guild.owner_id)
            expect(guild.AfkTimeout).to.equal(MockData.Guild.afk_timeout)
            expect(guild.VerificationLevel).to.equal(MockData.Guild.verification_level)
            expect(guild.PremiumTier).to.equal(MockData.Guild.premium_tier)
            expect(guild.PreferredLocale).to.equal(MockData.Guild.preferred_locale)
        end)

        it("should parse features array", function()
            local guild = Guild.new(client, MockData.Guild)
            expect(guild.Features).to.be.a("table")
            expect(#guild.Features).to.equal(2)
        end)

        it("should default optional properties", function()
            local minimalGuild = {
                id = "123",
                name = "Test",
                owner_id = "456",
                afk_timeout = 300,
                verification_level = 0,
                default_message_notifications = 0,
                explicit_content_filter = 0,
                features = {},
                mfa_level = 0,
                system_channel_flags = 0,
                premium_tier = 0,
                preferred_locale = "en-US",
                nsfw_level = 0,
            }
            local guild = Guild.new(client, minimalGuild)

            expect(guild.Unavailable).to.equal(false)
            expect(guild.Large).to.equal(false)
        end)
    end)

    describe("Guild with roles", function()
        it("should parse roles from guild data", function()
            local guildData = table.clone(MockData.GatewayGuildCreate)
            local guild = Guild.new(client, guildData)

            expect(next(guild.Roles)).to.be.ok()
        end)
    end)

    describe("Guild with channels", function()
        it("should parse channels from guild data", function()
            local guildData = table.clone(MockData.GatewayGuildCreate)
            local guild = Guild.new(client, guildData)

            expect(next(guild.Channels)).to.be.ok()
        end)
    end)

    describe("Guild with members", function()
        it("should parse members from guild data", function()
            local guildData = table.clone(MockData.GatewayGuildCreate)
            local guild = Guild.new(client, guildData)

            expect(next(guild.Members)).to.be.ok()
        end)
    end)

    describe("GetIconUrl", function()
        it("should return nil if no icon", function()
            local guildData = table.clone(MockData.Guild)
            guildData.icon = nil
            local guild = Guild.new(client, guildData)

            expect(guild:GetIconUrl()).to.equal(nil)
        end)

        it("should return icon URL with default options", function()
            local guild = Guild.new(client, MockData.Guild)
            local url = guild:GetIconUrl()

            expect(url).to.be.a("string")
            expect(TestUtils.contains(url, "cdn.discordapp.com/icons")).to.equal(true)
            expect(TestUtils.contains(url, MockData.Guild.id)).to.equal(true)
            expect(TestUtils.contains(url, "size=128")).to.equal(true)
        end)

        it("should return animated icon with gif extension", function()
            local guildData = table.clone(MockData.Guild)
            guildData.icon = "a_animated_icon"
            local guild = Guild.new(client, guildData)

            local url = guild:GetIconUrl()
            expect(TestUtils.contains(url, ".gif")).to.equal(true)
        end)

        it("should respect custom format and size", function()
            local guild = Guild.new(client, MockData.Guild)
            local url = guild:GetIconUrl({ format = "png", size = 256 })

            expect(TestUtils.contains(url, ".png")).to.equal(true)
            expect(TestUtils.contains(url, "size=256")).to.equal(true)
        end)
    end)

    describe("GetBannerUrl", function()
        it("should return nil if no banner", function()
            local guild = Guild.new(client, MockData.Guild)
            expect(guild:GetBannerUrl()).to.equal(nil)
        end)

        it("should return banner URL if banner exists", function()
            local guildData = table.clone(MockData.Guild)
            guildData.banner = "banner_hash"
            local guild = Guild.new(client, guildData)

            local url = guild:GetBannerUrl()
            expect(url).to.be.a("string")
            expect(TestUtils.contains(url, "cdn.discordapp.com/banners")).to.equal(true)
        end)
    end)

    describe("GetSplashUrl", function()
        it("should return nil if no splash", function()
            local guild = Guild.new(client, MockData.Guild)
            expect(guild:GetSplashUrl()).to.equal(nil)
        end)

        it("should return splash URL if splash exists", function()
            local guildData = table.clone(MockData.Guild)
            guildData.splash = "splash_hash"
            local guild = Guild.new(client, guildData)

            local url = guild:GetSplashUrl()
            expect(url).to.be.a("string")
            expect(TestUtils.contains(url, "cdn.discordapp.com/splashes")).to.equal(true)
        end)
    end)

    describe("GetDiscoverySplashUrl", function()
        it("should return nil if no discovery splash", function()
            local guild = Guild.new(client, MockData.Guild)
            expect(guild:GetDiscoverySplashUrl()).to.equal(nil)
        end)

        it("should return discovery splash URL if exists", function()
            local guildData = table.clone(MockData.Guild)
            guildData.discovery_splash = "discovery_splash_hash"
            local guild = Guild.new(client, guildData)

            local url = guild:GetDiscoverySplashUrl()
            expect(url).to.be.a("string")
            expect(TestUtils.contains(url, "cdn.discordapp.com/discovery-splashes")).to.equal(true)
        end)
    end)

    describe("GetChannel", function()
        it("should return channel if exists", function()
            local guildData = table.clone(MockData.GatewayGuildCreate)
            local guild = Guild.new(client, guildData)

            local channel = guild:GetChannel(MockData.Snowflakes.ChannelId)
            expect(channel).to.be.ok()
            expect(channel.Id).to.equal(MockData.Snowflakes.ChannelId)
        end)

        it("should return nil if channel does not exist", function()
            local guild = Guild.new(client, MockData.Guild)
            expect(guild:GetChannel("nonexistent")).to.equal(nil)
        end)
    end)

    describe("GetRole", function()
        it("should return role if exists", function()
            local guildData = table.clone(MockData.GatewayGuildCreate)
            local guild = Guild.new(client, guildData)

            local role = guild:GetRole(MockData.Snowflakes.RoleId)
            expect(role).to.be.ok()
            expect(role.Id).to.equal(MockData.Snowflakes.RoleId)
        end)

        it("should return nil if role does not exist", function()
            local guild = Guild.new(client, MockData.Guild)
            expect(guild:GetRole("nonexistent")).to.equal(nil)
        end)
    end)

    describe("GetMember", function()
        it("should return member if exists", function()
            local guildData = table.clone(MockData.GatewayGuildCreate)
            local guild = Guild.new(client, guildData)

            local member = guild:GetMember(MockData.Snowflakes.UserId)
            expect(member).to.be.ok()
        end)

        it("should return nil if member does not exist", function()
            local guild = Guild.new(client, MockData.Guild)
            expect(guild:GetMember("nonexistent")).to.equal(nil)
        end)
    end)

    describe("GetEveryoneRole", function()
        it("should return @everyone role", function()
            local guildData = table.clone(MockData.GatewayGuildCreate)
            local guild = Guild.new(client, guildData)

            local everyoneRole = guild:GetEveryoneRole()
            expect(everyoneRole).to.be.ok()
            expect(everyoneRole.Id).to.equal(guild.Id)
        end)
    end)

    describe("__tostring", function()
        it("should return Guild(id) format", function()
            local guild = Guild.new(client, MockData.Guild)
            expect(tostring(guild)).to.equal(`Guild({MockData.Guild.id})`)
        end)
    end)
end
