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

const process = require("@lune/process")
const task = require("@lune/task")

const Rest = require("@discordluau/Rest")
const TestUtils = require("./Helpers/TestUtils")

-- Get environment variables
const BOT_TOKEN = process.env.DISCORD_BOT_TOKEN
const GUILD_ID = process.env.DISCORD_TEST_GUILD_ID
const TEXT_CHANNEL_ID = process.env.DISCORD_TEST_TEXT_CHANNEL_ID
const VOICE_CHANNEL_ID = process.env.DISCORD_TEST_VOICE_CHANNEL_ID
const CATEGORY_ID = process.env.DISCORD_TEST_CATEGORY_ID
const _FORUM_CHANNEL_ID = process.env.DISCORD_TEST_FORUM_CHANNEL_ID

-- Channel types
const CHANNEL_TYPE_TEXT = 0
const CHANNEL_TYPE_VOICE = 2

-- Permission overwrite types
const OVERWRITE_TYPE_ROLE = 0
const OVERWRITE_TYPE_MEMBER = 1

-- Check if integration tests should run
const function shouldRunIntegrationTests(): boolean
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
    const mockClient = { _eventHandlers = {} }
    local botUserId: string?

    beforeAll(function()
        rest = Rest.new(mockClient, BOT_TOKEN)

        -- Get the bot's user ID for permission tests
        const user = rest:GetCurrentUser()
        botUserId = user.id
    end)

    describe("REST API Integration", function()
        describe("User endpoints", function()
            it("should get current user", function()
                const user = rest:GetCurrentUser()

                expect(user).to.be.ok()
                expect(user.id).to.be.a("string")
                expect(user.username).to.be.a("string")
                expect(user.bot).to.equal(true)
            end)
        end)

        describe("Guild endpoints", function()
            it("should get guild", function()
                const guild = rest:GetGuild(GUILD_ID)

                expect(guild).to.be.ok()
                expect(guild.id).to.equal(GUILD_ID)
                expect(guild.name).to.be.a("string")
            end)

            it("should get guild with counts", function()
                const guild = rest:GetGuild(GUILD_ID, true)

                expect(guild).to.be.ok()
                expect(guild.approximate_member_count).to.be.a("number")
            end)

            it("should get guild channels", function()
                const channels = rest:GetGuildChannels(GUILD_ID)

                expect(channels).to.be.a("table")
                expect(#channels > 0).to.equal(true)
            end)

            it("should get guild roles", function()
                const roles = rest:GetGuildRoles(GUILD_ID)

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
                const channel = rest:GetChannel(TEXT_CHANNEL_ID)

                expect(channel).to.be.ok()
                expect(channel.id).to.equal(TEXT_CHANNEL_ID)
                expect(channel.type).to.be.a("number")
            end)

            it("should get voice channel", function()
                if not VOICE_CHANNEL_ID then
                    return
                end

                const channel = rest:GetChannel(VOICE_CHANNEL_ID)

                expect(channel).to.be.ok()
                expect(channel.id).to.equal(VOICE_CHANNEL_ID)
                expect(channel.type).to.equal(CHANNEL_TYPE_VOICE)
            end)

            it("should get category channel", function()
                if not CATEGORY_ID then
                    return
                end

                const channel = rest:GetChannel(CATEGORY_ID)

                expect(channel).to.be.ok()
                expect(channel.id).to.equal(CATEGORY_ID)
                expect(channel.type).to.equal(4) -- GuildCategory
            end)
        end)

        describe("Channel creation and deletion", function()
            local createdChannelId: string?

            it("should create a text channel", function()
                const timestamp = os.date("%H%M%S")
                const channel = rest:CreateGuildChannel(GUILD_ID, {
                    name = `integration-test-{timestamp}`,
                    type = CHANNEL_TYPE_TEXT,
                    parent_id = CATEGORY_ID,
                    topic = "Created by integration test",
                }, "Integration test channel creation")

                expect(channel).to.be.ok()
                expect(channel.id).to.be.a("string")
                expect(channel.type).to.equal(CHANNEL_TYPE_TEXT)
                expect(TestUtils.contains(channel.name, "integration-test")).to.equal(true)

                if CATEGORY_ID then
                    expect(channel.parent_id).to.equal(CATEGORY_ID)
                end

                createdChannelId = channel.id
            end)

            it("should modify a channel", function()
                if not createdChannelId then
                    return
                end

                const channel = rest:ModifyChannel(createdChannelId, {
                    topic = "Modified by integration test",
                }, "Integration test channel modification")

                expect(channel).to.be.ok()
                expect(channel.topic).to.equal("Modified by integration test")
            end)

            it("should delete the created channel", function()
                if not createdChannelId then
                    return
                end

                -- Delete the channel
                rest:DeleteChannel(createdChannelId, "Integration test cleanup")

                -- Verify it's deleted by trying to fetch it
                const success = pcall(function()
                    rest:GetChannel(createdChannelId :: string)
                end)

                expect(success).to.equal(false)
                createdChannelId = nil
            end)

            afterAll(function()
                -- Clean up if test failed before deletion
                if createdChannelId then
                    pcall(function()
                        rest:DeleteChannel(createdChannelId :: string, "Integration test cleanup")
                    end)
                end
            end)
        end)

        describe("Channel permissions", function()
            local testChannelId: string?
            local everyoneRoleId: string?

            beforeAll(function()
                -- Create a test channel for permission tests
                const timestamp = os.date("%H%M%S")
                const channel = rest:CreateGuildChannel(GUILD_ID, {
                    name = `perm-test-{timestamp}`,
                    type = CHANNEL_TYPE_TEXT,
                    parent_id = CATEGORY_ID,
                }, "Integration test for permissions")

                testChannelId = channel.id

                -- Get the @everyone role ID (same as guild ID)
                everyoneRoleId = GUILD_ID
            end)

            it("should set permission overwrites for a role", function()
                if not testChannelId or not everyoneRoleId then
                    return
                end

                task.wait(1)

                -- Deny SendMessages for @everyone role
                rest:EditChannelPermissions(testChannelId, everyoneRoleId, {
                    deny = tostring(bit32.bor(
                        bit32.lshift(1, 11) -- SendMessages
                    )),
                    type = OVERWRITE_TYPE_ROLE,
                }, "Integration test permission change")

                -- Verify the channel now has the permission overwrite
                const channel = rest:GetChannel(testChannelId)
                expect(channel.permission_overwrites).to.be.a("table")

                local foundOverwrite = false
                for _, overwrite in channel.permission_overwrites do
                    if overwrite.id == everyoneRoleId then
                        foundOverwrite = true
                        break
                    end
                end
                expect(foundOverwrite).to.equal(true)
            end)

            it("should set permission overwrites for the bot user", function()
                if not testChannelId or not botUserId then
                    return
                end

                task.wait(1)

                -- Allow SendMessages for the bot (member overwrite)
                rest:EditChannelPermissions(testChannelId, botUserId, {
                    allow = tostring(bit32.bor(
                        bit32.lshift(1, 11), -- SendMessages
                        bit32.lshift(1, 10) -- ViewChannel
                    )),
                    type = OVERWRITE_TYPE_MEMBER,
                }, "Integration test member permission")

                task.wait(1)

                -- Verify the permission overwrite exists
                const channel = rest:GetChannel(testChannelId)

                local foundBotOverwrite = false
                for _, overwrite in channel.permission_overwrites do
                    if overwrite.id == botUserId then
                        foundBotOverwrite = true
                        break
                    end
                end
                expect(foundBotOverwrite).to.equal(true)
            end)

            it("should delete permission overwrites", function()
                if not testChannelId or not botUserId then
                    return
                end

                task.wait(1)

                -- Delete the bot's permission overwrite
                rest:DeleteChannelPermission(testChannelId, botUserId, "Integration test cleanup")

                task.wait(1)

                -- Verify the overwrite is removed
                const channel = rest:GetChannel(testChannelId)

                local foundBotOverwrite = false
                for _, overwrite in channel.permission_overwrites do
                    if overwrite.id == botUserId then
                        foundBotOverwrite = true
                        break
                    end
                end
                expect(foundBotOverwrite).to.equal(false)
            end)

            afterAll(function()
                -- Clean up test channel
                if testChannelId then
                    pcall(function()
                        rest:DeleteChannel(testChannelId :: string, "Integration test cleanup")
                    end)
                end
            end)
        end)

        describe("Message endpoints", function()
            local createdMessageId: string?

            it("should send a message", function()
                task.wait(1)
                const timestamp = os.date("%Y-%m-%d %H:%M:%S")
                const message = rest:CreateMessage(TEXT_CHANNEL_ID, {
                    content = `[Integration Test] Message created at {timestamp}`,
                })

                expect(message).to.be.ok()
                expect(message.id).to.be.a("string")
                expect(TestUtils.contains(message.content, "Integration Test")).to.equal(true)

                createdMessageId = message.id
            end)

            it("should send a message with an embed", function()
                const message = rest:CreateMessage(TEXT_CHANNEL_ID, {
                    content = "[Integration Test] Message with embed",
                    embeds = {
                        {
                            title = "Test Embed",
                            description = "This is a test embed from the integration tests",
                            color = 0x5865F2,
                            fields = {
                                { name = "Field 1", value = "Value 1", inline = true },
                                { name = "Field 2", value = "Value 2", inline = true },
                            },
                            footer = { text = "Integration Test" },
                        },
                    },
                })

                expect(message).to.be.ok()
                expect(message.embeds).to.be.a("table")
                expect(#message.embeds).to.equal(1)
                expect(message.embeds[1].title).to.equal("Test Embed")

                -- Clean up
                task.wait(0.5)
                rest:DeleteMessage(TEXT_CHANNEL_ID, message.id)
            end)

            it("should get messages", function()
                const messages = rest:GetChannelMessages(TEXT_CHANNEL_ID, { limit = 5 })

                expect(messages).to.be.a("table")
                expect(#messages > 0).to.equal(true)
            end)

            it("should get a specific message", function()
                if not createdMessageId then
                    return
                end

                const message = rest:GetChannelMessage(TEXT_CHANNEL_ID, createdMessageId)

                expect(message).to.be.ok()
                expect(message.id).to.equal(createdMessageId)
            end)

            it("should edit a message", function()
                if not createdMessageId then
                    -- Create a message first
                    const message = rest:CreateMessage(TEXT_CHANNEL_ID, {
                        content = "[Integration Test] To be edited",
                    })
                    createdMessageId = message.id
                end

                const editedMessage = rest:EditMessage(TEXT_CHANNEL_ID, createdMessageId :: string, {
                    content = "[Integration Test] Message has been edited",
                })

                expect(editedMessage).to.be.ok()
                expect(editedMessage.content).to.equal("[Integration Test] Message has been edited")
                expect(editedMessage.edited_timestamp).to.be.ok()
            end)

            it("should delete a message", function()
                -- Create a message to delete
                const message = rest:CreateMessage(TEXT_CHANNEL_ID, {
                    content = "[Integration Test] This message will be deleted",
                })

                expect(message).to.be.ok()

                -- Wait a moment to avoid rate limits
                task.wait(0.5)

                -- Delete the message
                rest:DeleteMessage(TEXT_CHANNEL_ID, message.id)

                -- Verify it's deleted by trying to fetch it (should fail)
                const success = pcall(function()
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
                const message = rest:CreateMessage(TEXT_CHANNEL_ID, {
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

            it("should add multiple reactions", function()
                if not testMessageId then
                    return
                end

                rest:CreateReaction(TEXT_CHANNEL_ID, testMessageId, "🎉")
                task.wait(0.3)
                rest:CreateReaction(TEXT_CHANNEL_ID, testMessageId, "🔥")
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

            it("should delete all reactions for a specific emoji", function()
                if not testMessageId then
                    return
                end

                -- Add a reaction
                rest:CreateReaction(TEXT_CHANNEL_ID, testMessageId, "⭐")
                task.wait(0.5)

                -- Delete all reactions for that emoji
                rest:DeleteAllReactionsForEmoji(TEXT_CHANNEL_ID, testMessageId, "⭐")
            end)

            it("should delete all reactions", function()
                if not testMessageId then
                    return
                end

                -- Delete all reactions from the message
                rest:DeleteAllReactions(TEXT_CHANNEL_ID, testMessageId)

                task.wait(0.5)

                -- Verify the message has no reactions
                const message = rest:GetChannelMessage(TEXT_CHANNEL_ID, testMessageId)
                const hasReactions = message.reactions ~= nil and #message.reactions > 0
                expect(hasReactions).to.equal(false)
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

        describe("Pin endpoints", function()
            local testMessageId: string?

            beforeAll(function()
                const message = rest:CreateMessage(TEXT_CHANNEL_ID, {
                    content = "[Integration Test] Pin test message",
                })
                testMessageId = message.id
            end)

            it("should pin a message", function()
                if not testMessageId then
                    return
                end

                rest:PinMessage(TEXT_CHANNEL_ID, testMessageId)

                -- Verify it's pinned
                const pins = rest:GetPinnedMessages(TEXT_CHANNEL_ID)
                local isPinned = false
                for _, pin in pins do
                    if pin.id == testMessageId then
                        isPinned = true
                        break
                    end
                end
                expect(isPinned).to.equal(true)
            end)

            it("should get pinned messages", function()
                const pins = rest:GetPinnedMessages(TEXT_CHANNEL_ID)

                expect(pins).to.be.a("table")
            end)

            it("should unpin a message", function()
                if not testMessageId then
                    return
                end

                task.wait(1)
                rest:UnpinMessage(TEXT_CHANNEL_ID, testMessageId)
                task.wait(1)

                -- Verify it's unpinned
                const pins = rest:GetPinnedMessages(TEXT_CHANNEL_ID)
                local isPinned = false
                for _, pin in pins do
                    if pin.id == testMessageId then
                        isPinned = true
                        break
                    end
                end
                expect(isPinned).to.equal(false)
            end)

            afterAll(function()
                if testMessageId then
                    pcall(function()
                        rest:UnpinMessage(TEXT_CHANNEL_ID, testMessageId :: string)
                        rest:DeleteMessage(TEXT_CHANNEL_ID, testMessageId :: string)
                    end)
                end
            end)
        end)

        describe("Thread endpoints", function()
            local testMessageId: string?
            local testThreadId: string?

            beforeAll(function()
                task.wait(1)
                const message = rest:CreateMessage(TEXT_CHANNEL_ID, {
                    content = "[Integration Test] Thread test message",
                })
                testMessageId = message.id
            end)

            it("should create a thread from a message", function()
                if not testMessageId then
                    return
                end

                task.wait(1)
                const timestamp = os.date("%H%M%S")
                const thread = rest:StartThreadFromMessage(
                    TEXT_CHANNEL_ID,
                    testMessageId,
                    `test-thread-{timestamp}`,
                    { auto_archive_duration = 60 }
                )

                expect(thread).to.be.ok()
                expect(thread.id).to.be.a("string")
                expect(TestUtils.contains(thread.name, "test-thread")).to.equal(true)

                testThreadId = thread.id
            end)

            it("should send a message in the thread", function()
                if not testThreadId then
                    return
                end

                task.wait(1)
                const message = rest:CreateMessage(testThreadId, {
                    content = "[Integration Test] Message in thread",
                })

                expect(message).to.be.ok()
                expect(message.channel_id).to.equal(testThreadId)
            end)

            afterAll(function()
                -- Clean up thread and message
                if testThreadId then
                    pcall(function()
                        rest:DeleteChannel(testThreadId :: string, "Integration test cleanup")
                    end)
                end
                if testMessageId then
                    pcall(function()
                        rest:DeleteMessage(TEXT_CHANNEL_ID, testMessageId :: string)
                    end)
                end
            end)
        end)

        describe("Role endpoints", function()
            local createdRoleId: string?

            it("should create a role", function()
                task.wait(1)
                const timestamp = os.date("%H%M%S")
                const role = rest:CreateGuildRole(GUILD_ID, {
                    name = `test-role-{timestamp}`,
                    color = 0xFF5733,
                    hoist = false,
                    mentionable = false,
                }, "Integration test role creation")

                expect(role).to.be.ok()
                expect(role.id).to.be.a("string")
                expect(TestUtils.contains(role.name, "test-role")).to.equal(true)
                expect(role.color).to.equal(0xFF5733)

                createdRoleId = role.id
            end)

            it("should modify a role", function()
                if not createdRoleId then
                    return
                end

                task.wait(1)
                const role = rest:ModifyGuildRole(GUILD_ID, createdRoleId, {
                    name = "modified-test-role",
                    color = 0x3498DB,
                }, "Integration test role modification")

                expect(role).to.be.ok()
                expect(role.name).to.equal("modified-test-role")
                expect(role.color).to.equal(0x3498DB)
            end)

            it("should delete the created role", function()
                if not createdRoleId then
                    return
                end

                task.wait(1)
                rest:DeleteGuildRole(GUILD_ID, createdRoleId, "Integration test cleanup")

                -- Verify it's deleted by checking guild roles
                const roles = rest:GetGuildRoles(GUILD_ID)
                local roleExists = false
                for _, role in roles do
                    if role.id == createdRoleId then
                        roleExists = true
                        break
                    end
                end
                expect(roleExists).to.equal(false)

                createdRoleId = nil
            end)

            afterAll(function()
                if createdRoleId then
                    pcall(function()
                        rest:DeleteGuildRole(GUILD_ID, createdRoleId :: string, "Integration test cleanup")
                    end)
                end
            end)
        end)

        describe("Gateway endpoints", function()
            it("should get gateway URL", function()
                const gateway = rest:GetGateway()

                expect(gateway).to.be.ok()
                expect(gateway.url).to.be.a("string")
                expect(TestUtils.contains(gateway.url, "wss://")).to.equal(true)
            end)

            it("should get gateway bot info", function()
                const gatewayBot = rest:GetGatewayBot()

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
                const user = rest:GetCurrentUser()
                applicationId = user.id
            end)

            it("should get global commands", function()
                if not applicationId then
                    return
                end

                const commands = rest:GetGlobalApplicationCommands(applicationId)
                expect(commands).to.be.a("table")
            end)

            it("should get guild commands", function()
                if not applicationId then
                    return
                end

                const commands = rest:GetGuildApplicationCommands(applicationId, GUILD_ID)
                expect(commands).to.be.a("table")
            end)
        end)
    end)
end
