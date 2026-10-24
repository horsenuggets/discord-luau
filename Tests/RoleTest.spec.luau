--[[

RoleTest

Tests for the Role structure class.

--]]

const Guild = require("@discordluau/Structures/Guild")
const MockClient = require("./Helpers/MockClient")
const MockData = require("./Helpers/MockData")
const Role = require("@discordluau/Structures/Role")
const TestUtils = require("./Helpers/TestUtils")

return function()
    local client
    local guild

    beforeAll(function()
        client = MockClient.new()
        guild = Guild.new(client, MockData.Guild)
    end)

    describe("Role.new", function()
        it("should create a role from API data", function()
            const role = Role.new(client, guild, MockData.Role)
            expect(role.Id).to.equal(MockData.Snowflakes.RoleId)
            expect(role.Name).to.equal("Moderator")
        end)

        it("should validate client parameter", function()
            expect(function()
                Role.new(nil :: any, guild, MockData.Role)
            end).to.throw()
        end)

        it("should validate guild parameter", function()
            expect(function()
                Role.new(client, nil :: any, MockData.Role)
            end).to.throw()
        end)

        it("should validate data parameter", function()
            expect(function()
                Role.new(client, guild, nil :: any)
            end).to.throw()
        end)
    end)

    describe("Role properties", function()
        it("should parse all standard properties", function()
            const role = Role.new(client, guild, MockData.Role)

            expect(role.Id).to.equal(MockData.Role.id)
            expect(role.Name).to.equal(MockData.Role.name)
            expect(role.Color).to.equal(MockData.Role.color)
            expect(role.Hoist).to.equal(MockData.Role.hoist)
            expect(role.Position).to.equal(MockData.Role.position)
            expect(role.Permissions).to.equal(MockData.Role.permissions)
            expect(role.Managed).to.equal(MockData.Role.managed)
            expect(role.Mentionable).to.equal(MockData.Role.mentionable)
        end)

        it("should store guild reference", function()
            const role = Role.new(client, guild, MockData.Role)
            expect(role.Guild).to.equal(guild)
            expect(role.GuildId).to.equal(guild.Id)
        end)

        it("should parse @everyone role", function()
            const role = Role.new(client, guild, MockData.EveryoneRole)
            expect(role.Name).to.equal("@everyone")
            expect(role.Position).to.equal(0)
        end)

        it("should parse optional icon and emoji", function()
            const roleData = table.clone(MockData.Role)
            roleData.icon = "role_icon_hash"
            roleData.unicode_emoji = "🎮"
            const role = Role.new(client, guild, roleData)

            expect(role.Icon).to.equal("role_icon_hash")
            expect(role.UnicodeEmoji).to.equal("🎮")
        end)
    end)

    describe("GetIconUrl", function()
        it("should return nil if no icon", function()
            const role = Role.new(client, guild, MockData.Role)
            expect(role:GetIconUrl()).to.equal(nil)
        end)

        it("should return icon URL if icon exists", function()
            const roleData = table.clone(MockData.Role)
            roleData.icon = "role_icon_hash"
            const role = Role.new(client, guild, roleData)

            const url = role:GetIconUrl()
            expect(url).to.be.a("string")
            expect(TestUtils.contains(url, "cdn.discordapp.com/role-icons")).to.equal(true)
            expect(TestUtils.contains(url, role.Id)).to.equal(true)
        end)

        it("should respect custom format and size", function()
            const roleData = table.clone(MockData.Role)
            roleData.icon = "role_icon_hash"
            const role = Role.new(client, guild, roleData)

            const url = role:GetIconUrl({ format = "png", size = 128 })
            expect(TestUtils.contains(url, ".png")).to.equal(true)
            expect(TestUtils.contains(url, "size=128")).to.equal(true)
        end)
    end)

    describe("GetHexColor", function()
        it("should return hex color string", function()
            const role = Role.new(client, guild, MockData.Role)
            expect(role:GetHexColor()).to.equal("#3498DB")
        end)

        it("should return black for zero color", function()
            const roleData = table.clone(MockData.Role)
            roleData.color = 0
            const role = Role.new(client, guild, roleData)

            expect(role:GetHexColor()).to.equal("#000000")
        end)

        it("should pad hex color to 6 digits", function()
            const roleData = table.clone(MockData.Role)
            roleData.color = 0x000FFF
            const role = Role.new(client, guild, roleData)

            expect(role:GetHexColor()).to.equal("#000FFF")
        end)
    end)

    describe("HasPermission", function()
        it("should return true if has specific permission", function()
            const roleData = table.clone(MockData.Role)
            roleData.permissions = "8" -- Administrator
            const role = Role.new(client, guild, roleData)

            expect(role:HasPermission(0x8)).to.equal(true)
        end)

        it("should return true for any permission if administrator", function()
            const roleData = table.clone(MockData.Role)
            roleData.permissions = "8" -- Administrator
            const role = Role.new(client, guild, roleData)

            expect(role:HasPermission(0x10)).to.equal(true) -- ManageChannels
        end)

        it("should return false if missing permission", function()
            const roleData = table.clone(MockData.Role)
            roleData.permissions = "0"
            const role = Role.new(client, guild, roleData)

            expect(role:HasPermission(0x8)).to.equal(false)
        end)

        it("should handle large permission values", function()
            const roleData = table.clone(MockData.Role)
            roleData.permissions = "1099511627775"
            const role = Role.new(client, guild, roleData)

            expect(role:HasPermission(0x8)).to.equal(true)
        end)
    end)

    describe("IsEveryone", function()
        it("should return true for @everyone role", function()
            const role = Role.new(client, guild, MockData.EveryoneRole)
            expect(role:IsEveryone()).to.equal(true)
        end)

        it("should return false for regular roles", function()
            const role = Role.new(client, guild, MockData.Role)
            expect(role:IsEveryone()).to.equal(false)
        end)
    end)

    describe("IsBotRole", function()
        it("should return false for regular roles", function()
            const role = Role.new(client, guild, MockData.Role)
            expect(role:IsBotRole()).to.equal(false)
        end)

        it("should return true for bot managed roles", function()
            const roleData = table.clone(MockData.Role)
            roleData.tags = { bot_id = "123456789" }
            const role = Role.new(client, guild, roleData)

            expect(role:IsBotRole()).to.equal(true)
        end)
    end)

    describe("IsBoosterRole", function()
        it("should return false for regular roles", function()
            const role = Role.new(client, guild, MockData.Role)
            expect(role:IsBoosterRole()).to.equal(false)
        end)

        it("should return true for booster roles", function()
            const roleData = table.clone(MockData.Role)
            roleData.tags = { premium_subscriber = true }
            const role = Role.new(client, guild, roleData)

            expect(role:IsBoosterRole()).to.equal(true)
        end)
    end)

    describe("ComparePositionTo", function()
        it("should return 1 if higher position", function()
            const roleData1 = table.clone(MockData.Role)
            roleData1.position = 10
            const roleData2 = table.clone(MockData.Role)
            roleData2.position = 5

            const role1 = Role.new(client, guild, roleData1)
            const role2 = Role.new(client, guild, roleData2)

            expect(role1:ComparePositionTo(role2)).to.equal(1)
        end)

        it("should return -1 if lower position", function()
            const roleData1 = table.clone(MockData.Role)
            roleData1.position = 5
            const roleData2 = table.clone(MockData.Role)
            roleData2.position = 10

            const role1 = Role.new(client, guild, roleData1)
            const role2 = Role.new(client, guild, roleData2)

            expect(role1:ComparePositionTo(role2)).to.equal(-1)
        end)

        it("should compare by ID if same position", function()
            const roleData1 = table.clone(MockData.Role)
            roleData1.position = 5
            roleData1.id = "100"
            const roleData2 = table.clone(MockData.Role)
            roleData2.position = 5
            roleData2.id = "200"

            const role1 = Role.new(client, guild, roleData1)
            const role2 = Role.new(client, guild, roleData2)

            -- Lower ID = created first = higher priority = returns 1
            expect(role1:ComparePositionTo(role2)).to.equal(1)
        end)

        it("should return 0 for same role", function()
            const role = Role.new(client, guild, MockData.Role)
            expect(role:ComparePositionTo(role)).to.equal(0)
        end)
    end)

    describe("ToString", function()
        it("should return role mention format", function()
            const role = Role.new(client, guild, MockData.Role)
            expect(role:ToString()).to.equal(`<@&{MockData.Role.id}>`)
        end)
    end)

    describe("__tostring", function()
        it("should return Role(id) format", function()
            const role = Role.new(client, guild, MockData.Role)
            expect(tostring(role)).to.equal(`Role({MockData.Role.id})`)
        end)
    end)
end
