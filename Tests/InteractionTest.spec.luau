--[[

InteractionTest

Tests for the Interaction structure class.

--]]

const Interaction = require("@discordluau/Structures/Interaction")
const MockClient = require("./Helpers/MockClient")
const MockData = require("./Helpers/MockData")
const TestUtils = require("./Helpers/TestUtils")

return function()
    local client

    beforeAll(function()
        client = MockClient.newWithData()
    end)

    beforeEach(function()
        client.Rest:clearCalls()
    end)

    describe("Interaction.new", function()
        it("should create an interaction from slash command data", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            expect(interaction.Id).to.equal(MockData.Snowflakes.InteractionId)
            expect(interaction.Type).to.equal(2)
            expect(interaction.CommandName).to.equal("ping")
        end)

        it("should create an interaction from button data", function()
            const interaction = Interaction.new(client, MockData.ButtonInteraction)
            expect(interaction.Type).to.equal(3)
            expect(interaction.CustomId).to.equal("button_confirm")
            expect(interaction.ComponentType).to.equal(2)
        end)
    end)

    describe("Interaction properties", function()
        it("should parse all standard properties", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)

            expect(interaction.Id).to.equal(MockData.SlashCommandInteraction.id)
            expect(interaction.ApplicationId).to.equal(MockData.SlashCommandInteraction.application_id)
            expect(interaction.Type).to.equal(MockData.SlashCommandInteraction.type)
            expect(interaction.GuildId).to.equal(MockData.SlashCommandInteraction.guild_id)
            expect(interaction.ChannelId).to.equal(MockData.SlashCommandInteraction.channel_id)
            expect(interaction.Token).to.equal(MockData.SlashCommandInteraction.token)
            expect(interaction.Version).to.equal(MockData.SlashCommandInteraction.version)
            expect(interaction.Locale).to.equal(MockData.SlashCommandInteraction.locale)
            expect(interaction.GuildLocale).to.equal(MockData.SlashCommandInteraction.guild_locale)
        end)

        it("should parse user from member data", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            expect(interaction.User).to.be.ok()
            expect(interaction.User.Id).to.equal(MockData.User.id)
        end)

        it("should parse command data", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            expect(interaction.CommandName).to.equal("ping")
            expect(interaction.CommandId).to.be.ok()
            expect(interaction.CommandType).to.equal(1)
        end)

        it("should parse options into key-value map", function()
            const interaction = Interaction.new(client, MockData.SlashCommandWithOptionsInteraction)
            expect(interaction.Options).to.be.a("table")
            expect(interaction.Options.message).to.equal("Hello from options!")
            expect(interaction.Options.ephemeral).to.equal(true)
        end)

        it("should parse component data", function()
            const interaction = Interaction.new(client, MockData.ButtonInteraction)
            expect(interaction.CustomId).to.equal("button_confirm")
            expect(interaction.ComponentType).to.equal(2)
        end)

        it("should start with deferred and replied as false", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            expect(interaction._deferred).to.equal(false)
            expect(interaction._replied).to.equal(false)
        end)
    end)

    describe("IsCommand", function()
        it("should return true for slash commands", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            expect(interaction:IsCommand()).to.equal(true)
        end)

        it("should return false for button interactions", function()
            const interaction = Interaction.new(client, MockData.ButtonInteraction)
            expect(interaction:IsCommand()).to.equal(false)
        end)
    end)

    describe("IsButton", function()
        it("should return true for button interactions", function()
            const interaction = Interaction.new(client, MockData.ButtonInteraction)
            expect(interaction:IsButton()).to.equal(true)
        end)

        it("should return false for slash commands", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            expect(interaction:IsButton()).to.equal(false)
        end)
    end)

    describe("IsSelectMenu", function()
        it("should return true for select menu interactions", function()
            const selectMenuData = table.clone(MockData.ButtonInteraction)
            selectMenuData.data = { custom_id = "select_menu", component_type = 3 }
            const interaction = Interaction.new(client, selectMenuData)

            expect(interaction:IsSelectMenu()).to.equal(true)
        end)

        it("should return false for button interactions", function()
            const interaction = Interaction.new(client, MockData.ButtonInteraction)
            expect(interaction:IsSelectMenu()).to.equal(false)
        end)
    end)

    describe("IsAutocomplete", function()
        it("should return true for autocomplete interactions", function()
            const autocompleteData = table.clone(MockData.SlashCommandInteraction)
            autocompleteData.type = 4
            const interaction = Interaction.new(client, autocompleteData)

            expect(interaction:IsAutocomplete()).to.equal(true)
        end)

        it("should return false for slash commands", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            expect(interaction:IsAutocomplete()).to.equal(false)
        end)
    end)

    describe("IsModalSubmit", function()
        it("should return true for modal submit interactions", function()
            const modalData = table.clone(MockData.SlashCommandInteraction)
            modalData.type = 5
            const interaction = Interaction.new(client, modalData)

            expect(interaction:IsModalSubmit()).to.equal(true)
        end)

        it("should return false for slash commands", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            expect(interaction:IsModalSubmit()).to.equal(false)
        end)
    end)

    describe("GetOption", function()
        it("should return option value", function()
            const interaction = Interaction.new(client, MockData.SlashCommandWithOptionsInteraction)
            expect(interaction:GetOption("message")).to.equal("Hello from options!")
        end)

        it("should return nil for missing option", function()
            const interaction = Interaction.new(client, MockData.SlashCommandWithOptionsInteraction)
            expect(interaction:GetOption("nonexistent")).to.equal(nil)
        end)
    end)

    describe("GetSubcommand", function()
        it("should return nil when no subcommand", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            expect(interaction:GetSubcommand()).to.equal(nil)
        end)

        it("should return subcommand name when present", function()
            const interactionData = table.clone(MockData.SlashCommandInteraction)
            interactionData.data = {
                id = "123",
                name = "parent",
                type = 1,
                options = {
                    {
                        name = "subcommand",
                        type = 1,
                        options = {},
                    },
                },
            }
            const interaction = Interaction.new(client, interactionData)

            expect(interaction:GetSubcommand()).to.equal("subcommand")
        end)
    end)

    describe("Reply", function()
        it("should reply with string content", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            interaction:Reply("Hello!")

            const calls = client.Rest:getCalls()
            expect(#calls > 0).to.equal(true)

            const lastCall = calls[#calls]
            expect(TestUtils.contains(lastCall.endpoint, "callback")).to.equal(true)
            expect(lastCall.body.type).to.equal(4)
            expect(lastCall.body.data.content).to.equal("Hello!")
        end)

        it("should reply with options", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            interaction:Reply({ content = "Test", ephemeral = true })

            const calls = client.Rest:getCalls()
            const lastCall = calls[#calls]
            expect(lastCall.body.data.content).to.equal("Test")
            expect(lastCall.body.data.flags).to.equal(64)
        end)

        it("should set _replied to true", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            interaction:Reply("Hello!")

            expect(interaction._replied).to.equal(true)
        end)

        it("should throw if already replied", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            interaction:Reply("First reply")

            expect(function()
                interaction:Reply("Second reply")
            end).to.throw()
        end)
    end)

    describe("DeferReply", function()
        it("should defer the reply", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            interaction:DeferReply()

            const calls = client.Rest:getCalls()
            const lastCall = calls[#calls]
            expect(lastCall.body.type).to.equal(5)
        end)

        it("should support ephemeral defer", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            interaction:DeferReply(true)

            const calls = client.Rest:getCalls()
            const lastCall = calls[#calls]
            expect(lastCall.body.data.flags).to.equal(64)
        end)

        it("should set _deferred and _replied to true", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            interaction:DeferReply()

            expect(interaction._deferred).to.equal(true)
            expect(interaction._replied).to.equal(true)
        end)

        it("should throw if already replied", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            interaction:Reply("Reply")

            expect(function()
                interaction:DeferReply()
            end).to.throw()
        end)

        it("should throw if already deferred", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            interaction:DeferReply()

            expect(function()
                interaction:DeferReply()
            end).to.throw()
        end)
    end)

    describe("EditReply", function()
        it("should edit the reply", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            interaction:Reply("Initial")
            client.Rest:clearCalls()

            interaction:EditReply("Edited")

            const calls = client.Rest:getCalls()
            expect(#calls > 0).to.equal(true)
        end)

        it("should throw if not replied", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)

            expect(function()
                interaction:EditReply("Edit")
            end).to.throw()
        end)
    end)

    describe("DeleteReply", function()
        it("should delete the reply", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            interaction:Reply("Initial")
            client.Rest:clearCalls()

            interaction:DeleteReply()

            const calls = client.Rest:getCalls()
            expect(#calls > 0).to.equal(true)
        end)

        it("should throw if not replied", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)

            expect(function()
                interaction:DeleteReply()
            end).to.throw()
        end)
    end)

    describe("FollowUp", function()
        it("should send follow-up message", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            interaction:Reply("Initial")
            client.Rest:clearCalls()

            interaction:FollowUp("Follow-up")

            const calls = client.Rest:getCalls()
            expect(#calls > 0).to.equal(true)
        end)

        it("should throw if not replied", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)

            expect(function()
                interaction:FollowUp("Follow-up")
            end).to.throw()
        end)
    end)

    describe("DeferUpdate", function()
        it("should defer update for component interactions", function()
            const interaction = Interaction.new(client, MockData.ButtonInteraction)
            interaction:DeferUpdate()

            const calls = client.Rest:getCalls()
            const lastCall = calls[#calls]
            expect(lastCall.body.type).to.equal(6)
        end)

        it("should throw for non-component interactions", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)

            expect(function()
                interaction:DeferUpdate()
            end).to.throw()
        end)
    end)

    describe("Update", function()
        it("should update component interaction message", function()
            const interaction = Interaction.new(client, MockData.ButtonInteraction)
            interaction:Update("Updated content")

            const calls = client.Rest:getCalls()
            const lastCall = calls[#calls]
            expect(lastCall.body.type).to.equal(7)
            expect(lastCall.body.data.content).to.equal("Updated content")
        end)

        it("should throw for non-component interactions", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)

            expect(function()
                interaction:Update("Update")
            end).to.throw()
        end)
    end)

    describe("ShowModal", function()
        it("should show modal", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            interaction:ShowModal({
                custom_id = "test_modal",
                title = "Test Modal",
                components = {},
            })

            const calls = client.Rest:getCalls()
            const lastCall = calls[#calls]
            expect(lastCall.body.type).to.equal(9)
            expect(lastCall.body.data.custom_id).to.equal("test_modal")
        end)

        it("should throw if already replied", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)
            interaction:Reply("Reply")

            expect(function()
                interaction:ShowModal({
                    custom_id = "modal",
                    title = "Modal",
                    components = {},
                })
            end).to.throw()
        end)
    end)

    describe("Respond", function()
        it("should respond with autocomplete choices", function()
            const autocompleteData = table.clone(MockData.SlashCommandInteraction)
            autocompleteData.type = 4
            const interaction = Interaction.new(client, autocompleteData)

            interaction:Respond({
                { name = "Option 1", value = "opt1" },
                { name = "Option 2", value = "opt2" },
            })

            const calls = client.Rest:getCalls()
            const lastCall = calls[#calls]
            expect(lastCall.body.type).to.equal(8)
            expect(lastCall.body.data.choices).to.be.a("table")
        end)

        it("should throw for non-autocomplete interactions", function()
            const interaction = Interaction.new(client, MockData.SlashCommandInteraction)

            expect(function()
                interaction:Respond({})
            end).to.throw()
        end)
    end)
end
