--[[

SlashCommandBuilderTest

Tests for the SlashCommandBuilder class.

--]]

local ApplicationCommandOptionType = require("@discordluau/Enums/ApplicationCommandOptionType")
local ApplicationCommandType = require("@discordluau/Enums/ApplicationCommandType")
local SlashCommandBuilder = require("@discordluau/Structures/SlashCommandBuilder")

return function()
    describe("SlashCommandBuilder.new", function()
        it("should create an empty builder", function()
            local builder = SlashCommandBuilder.new()
            expect(builder._data).to.be.ok()
            expect(builder._data.type).to.equal(ApplicationCommandType.ChatInput)
            expect(builder._data.options).to.be.a("table")
        end)
    end)

    describe("SetName", function()
        it("should set the command name", function()
            local builder = SlashCommandBuilder.new():SetName("test")
            expect(builder._data.name).to.equal("test")
        end)

        it("should return self for chaining", function()
            local builder = SlashCommandBuilder.new()
            local result = builder:SetName("test")
            expect(result).to.equal(builder)
        end)

        it("should reject invalid names", function()
            expect(function()
                SlashCommandBuilder.new():SetName("Test")
            end).to.throw()

            expect(function()
                SlashCommandBuilder.new():SetName("has space")
            end).to.throw()
        end)
    end)

    describe("SetDescription", function()
        it("should set the description", function()
            local builder = SlashCommandBuilder.new():SetDescription("A test command")
            expect(builder._data.description).to.equal("A test command")
        end)
    end)

    describe("AddStringOption", function()
        it("should add a string option", function()
            local builder = SlashCommandBuilder.new():AddStringOption("name", "The name")
            expect(#builder._data.options).to.equal(1)
            expect(builder._data.options[1].type).to.equal(ApplicationCommandOptionType.String)
            expect(builder._data.options[1].name).to.equal("name")
            expect(builder._data.options[1].description).to.equal("The name")
        end)

        it("should support required option", function()
            local builder = SlashCommandBuilder.new():AddStringOption("name", "The name", {
                required = true,
            })
            expect(builder._data.options[1].required).to.equal(true)
        end)

        it("should support choices", function()
            local builder = SlashCommandBuilder.new():AddStringOption("color", "Pick a color", {
                choices = {
                    { name = "Red", value = "red" },
                    { name = "Blue", value = "blue" },
                },
            })
            expect(#builder._data.options[1].choices).to.equal(2)
        end)
    end)

    describe("AddIntegerOption", function()
        it("should add an integer option", function()
            local builder = SlashCommandBuilder.new():AddIntegerOption("count", "The count")
            expect(builder._data.options[1].type).to.equal(ApplicationCommandOptionType.Integer)
        end)

        it("should support min and max values", function()
            local builder = SlashCommandBuilder.new():AddIntegerOption("count", "The count", {
                min_value = 1,
                max_value = 100,
            })
            expect(builder._data.options[1].min_value).to.equal(1)
            expect(builder._data.options[1].max_value).to.equal(100)
        end)
    end)

    describe("AddBooleanOption", function()
        it("should add a boolean option", function()
            local builder = SlashCommandBuilder.new():AddBooleanOption("enabled", "Enable feature")
            expect(builder._data.options[1].type).to.equal(ApplicationCommandOptionType.Boolean)
        end)
    end)

    describe("AddUserOption", function()
        it("should add a user option", function()
            local builder = SlashCommandBuilder.new():AddUserOption("user", "Select a user")
            expect(builder._data.options[1].type).to.equal(ApplicationCommandOptionType.User)
        end)
    end)

    describe("AddChannelOption", function()
        it("should add a channel option", function()
            local builder = SlashCommandBuilder.new():AddChannelOption("channel", "Select a channel")
            expect(builder._data.options[1].type).to.equal(ApplicationCommandOptionType.Channel)
        end)
    end)

    describe("AddRoleOption", function()
        it("should add a role option", function()
            local builder = SlashCommandBuilder.new():AddRoleOption("role", "Select a role")
            expect(builder._data.options[1].type).to.equal(ApplicationCommandOptionType.Role)
        end)
    end)

    describe("AddSubCommand", function()
        it("should add a subcommand", function()
            local builder = SlashCommandBuilder.new():AddSubCommand("sub", "A subcommand")
            expect(builder._data.options[1].type).to.equal(ApplicationCommandOptionType.SubCommand)
            expect(builder._data.options[1].name).to.equal("sub")
        end)
    end)

    describe("SetDefaultMemberPermissions", function()
        it("should set permissions from number", function()
            local builder = SlashCommandBuilder.new():SetDefaultMemberPermissions(8)
            expect(builder._data.default_member_permissions).to.equal("8")
        end)

        it("should set permissions from string", function()
            local builder = SlashCommandBuilder.new():SetDefaultMemberPermissions("8")
            expect(builder._data.default_member_permissions).to.equal("8")
        end)
    end)

    describe("SetDMPermission", function()
        it("should set DM permission", function()
            local builder = SlashCommandBuilder.new():SetDMPermission(false)
            expect(builder._data.dm_permission).to.equal(false)
        end)
    end)

    describe("SetNSFW", function()
        it("should set NSFW flag", function()
            local builder = SlashCommandBuilder.new():SetNSFW(true)
            expect(builder._data.nsfw).to.equal(true)
        end)
    end)

    describe("ToJSON", function()
        it("should return complete command data", function()
            local builder = SlashCommandBuilder.new()
                :SetName("ping")
                :SetDescription("Ping pong!")
                :AddStringOption("message", "Optional message")

            local json = builder:ToJSON()

            expect(json.name).to.equal("ping")
            expect(json.description).to.equal("Ping pong!")
            expect(json.type).to.equal(ApplicationCommandType.ChatInput)
            expect(#json.options).to.equal(1)
        end)

        it("should throw if name is missing", function()
            expect(function()
                SlashCommandBuilder.new():SetDescription("Test"):ToJSON()
            end).to.throw()
        end)

        it("should throw if description is missing", function()
            expect(function()
                SlashCommandBuilder.new():SetName("test"):ToJSON()
            end).to.throw()
        end)
    end)

    describe("chaining", function()
        it("should support full method chaining", function()
            local builder = SlashCommandBuilder.new()
                :SetName("moderation")
                :SetDescription("Moderation commands")
                :SetDefaultMemberPermissions(8)
                :SetDMPermission(false)
                :AddSubCommand("ban", "Ban a user", {
                    {
                        type = ApplicationCommandOptionType.User,
                        name = "user",
                        description = "User to ban",
                        required = true,
                    },
                    {
                        type = ApplicationCommandOptionType.String,
                        name = "reason",
                        description = "Reason for ban",
                    },
                })

            local json = builder:ToJSON()
            expect(json.name).to.equal("moderation")
            expect(json.default_member_permissions).to.equal("8")
            expect(json.dm_permission).to.equal(false)
            expect(#json.options).to.equal(1)
        end)
    end)
end
