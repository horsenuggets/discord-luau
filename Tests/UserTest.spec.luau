--[[

UserTest

Tests for the User structure class.

--]]

local MockClient = require("./Helpers/MockClient")
local MockData = require("./Helpers/MockData")
local TestUtils = require("./Helpers/TestUtils")
local User = require("@discordluau/Structures/User")

return function()
    local client

    beforeAll(function()
        client = MockClient.new()
    end)

    describe("User.new", function()
        it("should create a user from API data", function()
            local user = User.new(client, MockData.User)
            expect(user.Id).to.equal(MockData.Snowflakes.UserId)
            expect(user.Username).to.equal("testuser")
        end)

        it("should validate client parameter", function()
            expect(function()
                User.new(nil :: any, MockData.User)
            end).to.throw()
        end)

        it("should validate data parameter", function()
            expect(function()
                User.new(client, nil :: any)
            end).to.throw()
        end)
    end)

    describe("User properties", function()
        it("should parse all standard properties", function()
            local user = User.new(client, MockData.User)

            expect(user.Id).to.equal(MockData.User.id)
            expect(user.Username).to.equal(MockData.User.username)
            expect(user.Discriminator).to.equal(MockData.User.discriminator)
            expect(user.GlobalName).to.equal(MockData.User.global_name)
            expect(user.Avatar).to.equal(MockData.User.avatar)
            expect(user.Bot).to.equal(false)
            expect(user.System).to.equal(false)
            expect(user.PublicFlags).to.equal(MockData.User.public_flags)
            expect(user.AccentColor).to.equal(MockData.User.accent_color)
        end)

        it("should parse bot user properties", function()
            local user = User.new(client, MockData.BotUser)

            expect(user.Bot).to.equal(true)
            expect(user.Discriminator).to.equal("0")
        end)

        it("should default optional properties", function()
            local minimalUser = {
                id = "123",
                username = "test",
                discriminator = "0",
            }
            local user = User.new(client, minimalUser)

            expect(user.Bot).to.equal(false)
            expect(user.System).to.equal(false)
            expect(user.PublicFlags).to.equal(0)
            expect(user.GlobalName).to.equal(nil)
        end)
    end)

    describe("GetTag", function()
        it("should return username for users with discriminator 0", function()
            local user = User.new(client, MockData.BotUser)
            expect(user:GetTag()).to.equal("testbot")
        end)

        it("should return username#discriminator for legacy users", function()
            local user = User.new(client, MockData.User)
            expect(user:GetTag()).to.equal("testuser#1234")
        end)
    end)

    describe("GetDisplayName", function()
        it("should return global name if present", function()
            local user = User.new(client, MockData.User)
            expect(user:GetDisplayName()).to.equal("Test User")
        end)

        it("should return username if no global name", function()
            local user = User.new(client, MockData.BotUser)
            expect(user:GetDisplayName()).to.equal("testbot")
        end)
    end)

    describe("GetAvatarUrl", function()
        it("should return nil if no avatar", function()
            local userData = table.clone(MockData.User)
            userData.avatar = nil
            local user = User.new(client, userData)

            expect(user:GetAvatarUrl()).to.equal(nil)
        end)

        it("should return avatar URL with default options", function()
            local user = User.new(client, MockData.User)
            local url = user:GetAvatarUrl()

            expect(url).to.be.a("string")
            expect(TestUtils.contains(url, "cdn.discordapp.com/avatars")).to.equal(true)
            expect(TestUtils.contains(url, MockData.User.id)).to.equal(true)
            expect(TestUtils.contains(url, "size=128")).to.equal(true)
        end)

        it("should return animated avatar with gif extension", function()
            local userData = table.clone(MockData.User)
            userData.avatar = "a_animated_avatar_hash"
            local user = User.new(client, userData)

            local url = user:GetAvatarUrl()
            expect(TestUtils.contains(url, ".gif")).to.equal(true)
        end)

        it("should respect custom format and size", function()
            -- Note: animated avatars (starting with a_) always use gif regardless of format
            local userData = table.clone(MockData.User)
            userData.avatar = "static_avatar_hash"
            local user = User.new(client, userData)
            local url = user:GetAvatarUrl({ format = "png", size = 512 })

            expect(TestUtils.contains(url, ".png")).to.equal(true)
            expect(TestUtils.contains(url, "size=512")).to.equal(true)
        end)
    end)

    describe("GetDefaultAvatarUrl", function()
        it("should return default avatar URL for new username system", function()
            local user = User.new(client, MockData.BotUser)
            local url = user:GetDefaultAvatarUrl()

            expect(url).to.be.a("string")
            expect(TestUtils.contains(url, "cdn.discordapp.com/embed/avatars")).to.equal(true)
        end)

        it("should return default avatar URL for legacy users", function()
            local user = User.new(client, MockData.User)
            local url = user:GetDefaultAvatarUrl()

            expect(url).to.be.a("string")
            expect(TestUtils.contains(url, "cdn.discordapp.com/embed/avatars")).to.equal(true)
        end)
    end)

    describe("GetDisplayAvatarUrl", function()
        it("should return avatar URL if avatar exists", function()
            local user = User.new(client, MockData.User)
            local url = user:GetDisplayAvatarUrl()

            expect(TestUtils.contains(url, MockData.User.avatar)).to.equal(true)
        end)

        it("should return default avatar if no avatar", function()
            local userData = table.clone(MockData.User)
            userData.avatar = nil
            local user = User.new(client, userData)

            local url = user:GetDisplayAvatarUrl()
            expect(TestUtils.contains(url, "embed/avatars")).to.equal(true)
        end)
    end)

    describe("GetBannerUrl", function()
        it("should return nil if no banner", function()
            local user = User.new(client, MockData.User)
            expect(user:GetBannerUrl()).to.equal(nil)
        end)

        it("should return banner URL if banner exists", function()
            local userData = table.clone(MockData.User)
            userData.banner = "banner_hash"
            local user = User.new(client, userData)

            local url = user:GetBannerUrl()
            expect(url).to.be.a("string")
            expect(TestUtils.contains(url, "cdn.discordapp.com/banners")).to.equal(true)
        end)

        it("should return animated banner with gif extension", function()
            local userData = table.clone(MockData.User)
            userData.banner = "a_animated_banner"
            local user = User.new(client, userData)

            local url = user:GetBannerUrl()
            expect(TestUtils.contains(url, ".gif")).to.equal(true)
        end)
    end)

    describe("ToString", function()
        it("should return mention format", function()
            local user = User.new(client, MockData.User)
            expect(user:ToString()).to.equal(`<@{MockData.User.id}>`)
        end)
    end)

    describe("__tostring", function()
        it("should return User(id) format", function()
            local user = User.new(client, MockData.User)
            expect(tostring(user)).to.equal(`User({MockData.User.id})`)
        end)
    end)

    describe("_patch", function()
        it("should update user data", function()
            local user = User.new(client, MockData.User)
            local newData = table.clone(MockData.User)
            newData.username = "updated_username"
            newData.global_name = "Updated Name"

            user:_patch(newData)

            expect(user.Username).to.equal("updated_username")
            expect(user.GlobalName).to.equal("Updated Name")
        end)
    end)
end
