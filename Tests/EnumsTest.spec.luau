--[[

EnumsTest

Tests for Discord enumeration values.

--]]

local ChannelType = require("@discordluau/Enums/ChannelType")
local GatewayCloseCode = require("@discordluau/Enums/GatewayCloseCode")
local GatewayIntent = require("@discordluau/Enums/GatewayIntent")
local GatewayOpcode = require("@discordluau/Enums/GatewayOpcode")
local MessageType = require("@discordluau/Enums/MessageType")
local Permission = require("@discordluau/Enums/Permission")

return function()
    describe("ChannelType", function()
        it("should have correct values", function()
            expect(ChannelType.GuildText).to.equal(0)
            expect(ChannelType.DM).to.equal(1)
            expect(ChannelType.GuildVoice).to.equal(2)
            expect(ChannelType.GroupDM).to.equal(3)
            expect(ChannelType.GuildCategory).to.equal(4)
            expect(ChannelType.GuildAnnouncement).to.equal(5)
        end)

        it("should be frozen", function()
            expect(function()
                ChannelType.NewValue = 999
            end).to.throw()
        end)
    end)

    describe("GatewayOpcode", function()
        it("should have correct values", function()
            expect(GatewayOpcode.Dispatch).to.equal(0)
            expect(GatewayOpcode.Heartbeat).to.equal(1)
            expect(GatewayOpcode.Identify).to.equal(2)
            expect(GatewayOpcode.Hello).to.equal(10)
            expect(GatewayOpcode.HeartbeatAck).to.equal(11)
        end)
    end)

    describe("GatewayCloseCode", function()
        it("should have correct values", function()
            expect(GatewayCloseCode.UnknownError).to.equal(4000)
            expect(GatewayCloseCode.AuthenticationFailed).to.equal(4004)
            expect(GatewayCloseCode.DisallowedIntents).to.equal(4014)
        end)
    end)

    describe("GatewayIntent", function()
        it("should have correct bit values", function()
            expect(GatewayIntent.Guilds).to.equal(1)
            expect(GatewayIntent.GuildMembers).to.equal(2)
            expect(GatewayIntent.GuildMessages).to.equal(512)
            expect(GatewayIntent.MessageContent).to.equal(32768)
        end)

        it("should be combinable with bit32", function()
            local combined = bit32.bor(GatewayIntent.Guilds, GatewayIntent.GuildMessages)
            expect(combined).to.equal(513)
        end)
    end)

    describe("MessageType", function()
        it("should have correct values", function()
            expect(MessageType.Default).to.equal(0)
            expect(MessageType.Reply).to.equal(19)
            expect(MessageType.ChatInputCommand).to.equal(20)
        end)
    end)

    describe("Permission", function()
        it("should have correct bit values", function()
            expect(Permission.CreateInstantInvite).to.equal(1)
            expect(Permission.KickMembers).to.equal(2)
            expect(Permission.BanMembers).to.equal(4)
            expect(Permission.Administrator).to.equal(8)
        end)

        it("should be combinable with bit32", function()
            local combined = bit32.bor(Permission.SendMessages, Permission.ViewChannel)
            expect(bit32.band(combined, Permission.SendMessages)).to.equal(Permission.SendMessages)
            expect(bit32.band(combined, Permission.ViewChannel)).to.equal(Permission.ViewChannel)
        end)
    end)
end
