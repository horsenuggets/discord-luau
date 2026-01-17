--[[

MemberTest

Tests for the Member structure class.

--]]

local Guild = require("@discordluau/Structures/Guild")
local Member = require("@discordluau/Structures/Member")
local MockClient = require("./Helpers/MockClient")
local MockData = require("./Helpers/MockData")
local TestUtils = require("./Helpers/TestUtils")

return function()
    local client
    local guild

    beforeAll(function()
        client = MockClient.new()
        guild = Guild.new(client, MockData.Guild)
    end)

    describe("Member.new", function()
        it("should create a member from API data", function()
            local member = Member.new(client, guild, MockData.Member)
            expect(member.Nick).to.equal("TestNick")
            expect(member.GuildId).to.equal(MockData.Snowflakes.GuildId)
        end)

        it("should validate client parameter", function()
            expect(function()
                Member.new(nil :: any, guild, MockData.Member)
            end).to.throw()
        end)

        it("should validate guild parameter", function()
            expect(function()
                Member.new(client, nil :: any, MockData.Member)
            end).to.throw()
        end)

        it("should validate data parameter", function()
            expect(function()
                Member.new(client, guild, nil :: any)
            end).to.throw()
        end)
    end)

    describe("Member properties", function()
        it("should parse all standard properties", function()
            local member = Member.new(client, guild, MockData.Member)

            expect(member.Nick).to.equal(MockData.Member.nick)
            expect(member.JoinedAt).to.equal(MockData.Member.joined_at)
            expect(member.PremiumSince).to.equal(MockData.Member.premium_since)
            expect(member.Deaf).to.equal(MockData.Member.deaf)
            expect(member.Mute).to.equal(MockData.Member.mute)
            expect(member.Pending).to.equal(MockData.Member.pending)
            expect(member.Permissions).to.equal(MockData.Member.permissions)
        end)

        it("should parse roles array", function()
            local member = Member.new(client, guild, MockData.Member)
            expect(member.Roles).to.be.a("table")
            expect(#member.Roles).to.equal(1)
            expect(member.Roles[1]).to.equal(MockData.Snowflakes.RoleId)
        end)

        it("should parse user as User object", function()
            local member = Member.new(client, guild, MockData.Member)
            expect(member.User).to.be.ok()
            expect(member.User.Id).to.equal(MockData.User.id)
            expect(member.User.Username).to.equal(MockData.User.username)
        end)

        it("should store guild reference", function()
            local member = Member.new(client, guild, MockData.Member)
            expect(member.Guild).to.equal(guild)
            expect(member.GuildId).to.equal(guild.Id)
        end)

        it("should default optional properties", function()
            local minimalMember = {
                joined_at = "2024-01-01T00:00:00.000Z",
                roles = {},
                deaf = false,
                mute = false,
                flags = 0,
            }
            local member = Member.new(client, guild, minimalMember)

            expect(member.Pending).to.equal(false)
            expect(member.Nick).to.equal(nil)
            expect(member.User).to.equal(nil)
        end)
    end)

    describe("GetDisplayName", function()
        it("should return nickname if set", function()
            local member = Member.new(client, guild, MockData.Member)
            expect(member:GetDisplayName()).to.equal("TestNick")
        end)

        it("should return global name if no nickname but user exists", function()
            local memberData = table.clone(MockData.Member)
            memberData.nick = nil
            local member = Member.new(client, guild, memberData)

            expect(member:GetDisplayName()).to.equal(MockData.User.global_name)
        end)

        it("should return username if no nickname and no global name", function()
            local memberData = table.clone(MockData.Member)
            memberData.nick = nil
            local userData = table.clone(MockData.User)
            userData.global_name = nil
            memberData.user = userData
            local member = Member.new(client, guild, memberData)

            expect(member:GetDisplayName()).to.equal(MockData.User.username)
        end)

        it("should return Unknown if no user", function()
            local memberData = table.clone(MockData.Member)
            memberData.nick = nil
            memberData.user = nil
            local member = Member.new(client, guild, memberData)

            expect(member:GetDisplayName()).to.equal("Unknown")
        end)
    end)

    describe("GetAvatarUrl", function()
        it("should return nil if no guild avatar", function()
            local member = Member.new(client, guild, MockData.Member)
            expect(member:GetAvatarUrl()).to.equal(nil)
        end)

        it("should return guild avatar URL if avatar exists", function()
            local memberData = table.clone(MockData.Member)
            memberData.avatar = "guild_avatar_hash"
            local member = Member.new(client, guild, memberData)

            local url = member:GetAvatarUrl()
            expect(url).to.be.a("string")
            expect(TestUtils.contains(url, "cdn.discordapp.com/guilds")).to.equal(true)
            expect(TestUtils.contains(url, guild.Id)).to.equal(true)
            expect(TestUtils.contains(url, "avatars")).to.equal(true)
        end)

        it("should return animated avatar with gif extension", function()
            local memberData = table.clone(MockData.Member)
            memberData.avatar = "a_animated_guild_avatar"
            local member = Member.new(client, guild, memberData)

            local url = member:GetAvatarUrl()
            expect(TestUtils.contains(url, ".gif")).to.equal(true)
        end)

        it("should respect custom format and size", function()
            local memberData = table.clone(MockData.Member)
            memberData.avatar = "guild_avatar_hash"
            local member = Member.new(client, guild, memberData)

            local url = member:GetAvatarUrl({ format = "png", size = 256 })
            expect(TestUtils.contains(url, ".png")).to.equal(true)
            expect(TestUtils.contains(url, "size=256")).to.equal(true)
        end)
    end)

    describe("GetDisplayAvatarUrl", function()
        it("should return guild avatar if exists", function()
            local memberData = table.clone(MockData.Member)
            memberData.avatar = "guild_avatar_hash"
            local member = Member.new(client, guild, memberData)

            local url = member:GetDisplayAvatarUrl()
            expect(TestUtils.contains(url, "guilds")).to.equal(true)
            expect(TestUtils.contains(url, "guild_avatar_hash")).to.equal(true)
        end)

        it("should return user avatar if no guild avatar", function()
            local member = Member.new(client, guild, MockData.Member)
            local url = member:GetDisplayAvatarUrl()

            expect(TestUtils.contains(url, MockData.User.avatar)).to.equal(true)
        end)

        it("should return default avatar if no avatars", function()
            local memberData = table.clone(MockData.Member)
            memberData.avatar = nil
            local userData = table.clone(MockData.User)
            userData.avatar = nil
            memberData.user = userData
            local member = Member.new(client, guild, memberData)

            local url = member:GetDisplayAvatarUrl()
            expect(TestUtils.contains(url, "embed/avatars")).to.equal(true)
        end)

        it("should return fallback avatar if no user", function()
            local memberData = table.clone(MockData.Member)
            memberData.avatar = nil
            memberData.user = nil
            local member = Member.new(client, guild, memberData)

            local url = member:GetDisplayAvatarUrl()
            expect(url).to.equal("https://cdn.discordapp.com/embed/avatars/0.png")
        end)
    end)

    describe("HasPermission", function()
        it("should return false if no permissions", function()
            local memberData = table.clone(MockData.Member)
            memberData.permissions = nil
            local member = Member.new(client, guild, memberData)

            expect(member:HasPermission(0x8)).to.equal(false)
        end)

        it("should return true if has specific permission", function()
            local memberData = table.clone(MockData.Member)
            memberData.permissions = "8" -- Administrator
            local member = Member.new(client, guild, memberData)

            expect(member:HasPermission(0x8)).to.equal(true)
        end)

        it("should return true for any permission if administrator", function()
            local memberData = table.clone(MockData.Member)
            memberData.permissions = "8" -- Administrator
            local member = Member.new(client, guild, memberData)

            expect(member:HasPermission(0x10)).to.equal(true) -- Should be true for any permission
        end)

        it("should return false if missing permission", function()
            local memberData = table.clone(MockData.Member)
            memberData.permissions = "0"
            local member = Member.new(client, guild, memberData)

            expect(member:HasPermission(0x8)).to.equal(false)
        end)
    end)

    describe("IsTimedOut", function()
        it("should return false if not timed out", function()
            local member = Member.new(client, guild, MockData.Member)
            expect(member:IsTimedOut()).to.equal(false)
        end)

        it("should return true if timed out", function()
            local memberData = table.clone(MockData.Member)
            memberData.communication_disabled_until = "2030-01-01T00:00:00.000Z"
            local member = Member.new(client, guild, memberData)

            expect(member:IsTimedOut()).to.equal(true)
        end)
    end)

    describe("ToString", function()
        it("should return member mention format", function()
            local member = Member.new(client, guild, MockData.Member)
            expect(member:ToString()).to.equal(`<@{MockData.User.id}>`)
        end)

        it("should return <@0> if no user", function()
            local memberData = table.clone(MockData.Member)
            memberData.user = nil
            local member = Member.new(client, guild, memberData)

            expect(member:ToString()).to.equal("<@0>")
        end)
    end)

    describe("__tostring", function()
        it("should return Member(userId in guildId) format", function()
            local member = Member.new(client, guild, MockData.Member)
            expect(tostring(member)).to.equal(`Member({MockData.User.id} in {MockData.Guild.id})`)
        end)

        it("should return unknown if no user", function()
            local memberData = table.clone(MockData.Member)
            memberData.user = nil
            local member = Member.new(client, guild, memberData)

            expect(tostring(member)).to.equal(`Member(unknown in {MockData.Guild.id})`)
        end)
    end)
end
