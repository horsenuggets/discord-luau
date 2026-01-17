--[[

IntegrationTest

Integration tests that run against the real Discord API. These tests require a valid bot
token and test channel configuration via environment variables or GitHub secrets.

Environment variables:
> DISCORD_BOT_TOKEN - The bot token for authentication
> DISCORD_TEST_GUILD_ID - Guild ID for testing
> DISCORD_TEST_TEXT_CHANNEL_ID - Text channel ID for testing messages
> DISCORD_TEST_VOICE_CHANNEL_ID - Voice channel ID for testing
> DISCORD_TEST_CATEGORY_ID - Category ID for testing
> DISCORD_TEST_FORUM_CHANNEL_ID - Forum channel ID for testing

These tests are skipped when running locally without proper configuration.

--]]

local process = require("@lune/process")
local task = require("@lune/task")

local Rest = require("@discordluau/Rest")
local TestUtils = require("./Helpers/TestUtils")

-- Get environment variables
local BOT_TOKEN = process.env.DISCORD_BOT_TOKEN
local GUILD_ID = process.env.DISCORD_TEST_GUILD_ID
local TEXT_CHANNEL_ID = process.env.DISCORD_TEST_TEXT_CHANNEL_ID
local _VOICE_CHANNEL_ID = process.env.DISCORD_TEST_VOICE_CHANNEL_ID
local _CATEGORY_ID = process.env.DISCORD_TEST_CATEGORY_ID
local _FORUM_CHANNEL_ID = process.env.DISCORD_TEST_FORUM_CHANNEL_ID

-- Check if integration tests should run
local function shouldRunIntegrationTests(): boolean
    return BOT_TOKEN ~= nil and BOT_TOKEN ~= "" and GUILD_ID ~= nil and TEXT_CHANNEL_ID ~= nil
end

return function()
    if not shouldRunIntegrationTests() then
        describe("Integration tests (SKIPPED)", function()
            it("should skip when no credentials", function()
                -- This test is a placeholder to indicate tests were skipped
                expect(true).to.equal(true)
            end)
        end)
        return
    end

    local rest
    local mockClient = { _eventHandlers = {} }

    beforeAll(function()
        rest = Rest.new(mockClient, BOT_TOKEN)
    end)

    describe("REST API Integration", function()
        describe("User endpoints", function()
            it("should get current user", function()
                local user = rest:GetCurrentUser()

                expect(user).to.be.ok()
                expect(user.id).to.be.a("string")
                expect(user.username).to.be.a("string")
                expect(user.bot).to.equal(true)
            end)
        end)

        describe("Guild endpoints", function()
            it("should get guild", function()
                local guild = rest:GetGuild(GUILD_ID)

                expect(guild).to.be.ok()
                expect(guild.id).to.equal(GUILD_ID)
                expect(guild.name).to.be.a("string")
            end)

            it("should get guild with counts", function()
                local guild = rest:GetGuild(GUILD_ID, true)

                expect(guild).to.be.ok()
                expect(guild.approximate_member_count).to.be.a("number")
            end)

            it("should get guild channels", function()
                local channels = rest:GetGuildChannels(GUILD_ID)

                expect(channels).to.be.a("table")
                expect(#channels > 0).to.equal(true)
            end)

            it("should get guild roles", function()
                local roles = rest:GetGuildRoles(GUILD_ID)

                expect(roles).to.be.a("table")
                expect(#roles > 0).to.equal(true)

                -- Should have @everyone role
                local hasEveryone = false
                for _, role in roles do
                    if role.name == "@everyone" then
                        hasEveryone = true
                        break
                    end
                end
                expect(hasEveryone).to.equal(true)
            end)
        end)

        describe("Channel endpoints", function()
            it("should get channel", function()
                local channel = rest:GetChannel(TEXT_CHANNEL_ID)

                expect(channel).to.be.ok()
                expect(channel.id).to.equal(TEXT_CHANNEL_ID)
                expect(channel.type).to.be.a("number")
            end)
        end)

        describe("Message endpoints", function()
            local createdMessageId: string?

            it("should send a message", function()
                local timestamp = os.date("%Y-%m-%d %H:%M:%S")
                local message = rest:CreateMessage(TEXT_CHANNEL_ID, {
                    content = `[Integration Test] Message created at {timestamp}`,
                })

                expect(message).to.be.ok()
                expect(message.id).to.be.a("string")
                expect(TestUtils.contains(message.content, "Integration Test")).to.equal(true)

                createdMessageId = message.id
            end)

            it("should get messages", function()
                local messages = rest:GetChannelMessages(TEXT_CHANNEL_ID, { limit = 5 })

                expect(messages).to.be.a("table")
                expect(#messages > 0).to.equal(true)
            end)

            it("should edit a message", function()
                if not createdMessageId then
                    -- Create a message first
                    local message = rest:CreateMessage(TEXT_CHANNEL_ID, {
                        content = "[Integration Test] To be edited",
                    })
                    createdMessageId = message.id
                end

                local editedMessage = rest:EditMessage(TEXT_CHANNEL_ID, createdMessageId :: string, {
                    content = "[Integration Test] Message has been edited",
                })

                expect(editedMessage).to.be.ok()
                expect(editedMessage.content).to.equal("[Integration Test] Message has been edited")
                expect(editedMessage.edited_timestamp).to.be.ok()
            end)

            it("should delete a message", function()
                -- Create a message to delete
                local message = rest:CreateMessage(TEXT_CHANNEL_ID, {
                    content = "[Integration Test] This message will be deleted",
                })

                expect(message).to.be.ok()

                -- Wait a moment to avoid rate limits
                task.wait(0.5)

                -- Delete the message
                rest:DeleteMessage(TEXT_CHANNEL_ID, message.id)

                -- Verify it's deleted by trying to fetch it (should fail)
                local success = pcall(function()
                    rest:GetChannelMessage(TEXT_CHANNEL_ID, message.id)
                end)

                expect(success).to.equal(false)
            end)

            afterAll(function()
                -- Clean up any remaining test message
                if createdMessageId then
                    pcall(function()
                        rest:DeleteMessage(TEXT_CHANNEL_ID, createdMessageId :: string)
                    end)
                end
            end)
        end)

        describe("Reaction endpoints", function()
            local testMessageId: string?

            beforeAll(function()
                -- Create a test message for reactions
                local message = rest:CreateMessage(TEXT_CHANNEL_ID, {
                    content = "[Integration Test] Reaction test message",
                })
                testMessageId = message.id
            end)

            it("should add a reaction", function()
                if not testMessageId then
                    return
                end

                -- Add a reaction (should not throw)
                rest:CreateReaction(TEXT_CHANNEL_ID, testMessageId, "👍")
            end)

            it("should remove own reaction", function()
                if not testMessageId then
                    return
                end

                -- First add a reaction
                rest:CreateReaction(TEXT_CHANNEL_ID, testMessageId, "❤️")
                task.wait(0.5)

                -- Then remove it
                rest:DeleteOwnReaction(TEXT_CHANNEL_ID, testMessageId, "❤️")
            end)

            afterAll(function()
                -- Clean up test message
                if testMessageId then
                    pcall(function()
                        rest:DeleteMessage(TEXT_CHANNEL_ID, testMessageId :: string)
                    end)
                end
            end)
        end)

        describe("Gateway endpoints", function()
            it("should get gateway URL", function()
                local gateway = rest:GetGateway()

                expect(gateway).to.be.ok()
                expect(gateway.url).to.be.a("string")
                expect(TestUtils.contains(gateway.url, "wss://")).to.equal(true)
            end)

            it("should get gateway bot info", function()
                local gatewayBot = rest:GetGatewayBot()

                expect(gatewayBot).to.be.ok()
                expect(gatewayBot.url).to.be.a("string")
                expect(gatewayBot.shards).to.be.a("number")
                expect(gatewayBot.session_start_limit).to.be.a("table")
            end)
        end)

        describe("Application commands", function()
            local applicationId: string?

            beforeAll(function()
                -- Get the application ID from the bot user
                local user = rest:GetCurrentUser()
                applicationId = user.id
            end)

            it("should get global commands", function()
                if not applicationId then
                    return
                end

                local commands = rest:GetGlobalApplicationCommands(applicationId)
                expect(commands).to.be.a("table")
            end)

            it("should get guild commands", function()
                if not applicationId then
                    return
                end

                local commands = rest:GetGuildApplicationCommands(applicationId, GUILD_ID)
                expect(commands).to.be.a("table")
            end)
        end)
    end)
end
