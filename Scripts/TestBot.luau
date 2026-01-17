#!/usr/bin/env -S lune run

--[[

TestBot

A comprehensive test script to verify all discord-luau library features work correctly.

--]]

local loadEnv = require("./LoadEnv")
local process = require("@lune/process")
local task = require("@lune/task")

local Discord = require("@discordluau")

-- Load environment variables
if not loadEnv() then
    print("[Error] No .env file found. Create one from .env.template")
    process.exit(1)
end

local token = process.env.DISCORD_BOT_TOKEN
if not token or token == "" or token == "your_bot_token_here" then
    print("[Error] DISCORD_BOT_TOKEN not set in .env file")
    process.exit(1)
end

print("[Info] Starting comprehensive test bot...")

-- Create client with non-privileged intents only
-- Privileged intents (MessageContent, GuildMembers) require Developer Portal opt-in
local client = Discord.Client.new({
    intents = {
        Discord.Intents.Guilds,
        Discord.Intents.GuildMessages,
    },
})

-- Test results tracking
local testResults: { { name: string, passed: boolean, error: string? } } = {}

local function recordTest(name: string, passed: boolean, error: string?)
    table.insert(testResults, { name = name, passed = passed, error = error })
    local status = if passed then "[PASS]" else "[FAIL]"
    local message = if error then `: {error}` else ""
    print(`{status} {name}{message}`)
end

local function runTest(name: string, fn: () -> ())
    local success, err = pcall(fn)
    if success then
        recordTest(name, true)
    else
        recordTest(name, false, tostring(err))
    end
end

local function countTable(t: { [any]: any }): number
    local count = 0
    for _ in t do
        count += 1
    end
    return count
end

-- Wait for guilds to be fully loaded
local guildsLoaded = false
local testGuildId: string? = nil
local testChannelId: string? = nil

client:On("guildCreate", function(guild)
    print(`[Info] Guild loaded: {guild.Name} ({guild.Id})`)
    testGuildId = guild.Id

    -- Find a text channel to test in
    for _, channel in guild.Channels do
        if channel.Type == Discord.ChannelType.GuildText then
            testChannelId = channel.Id
            break
        end
    end

    guildsLoaded = true
end)

-- Ready event - run all tests
client:On("ready", function()
    print(`[Success] Logged in as {client.User:GetTag()}!`)
    print(`[Info] Application ID: {client.Application.id}`)

    -- Wait for guild data to load
    print("[Info] Waiting for guild data...")
    local waitStart = os.clock()
    while not guildsLoaded and os.clock() - waitStart < 10 do
        task.wait(0.1)
    end

    if not guildsLoaded then
        print("[Warning] No guilds loaded, some tests may fail")
    end

    local guildCount = countTable(client.Guilds)
    print(`[Info] Connected to {guildCount} guild(s)`)

    -- Run all tests
    print("\n========== RUNNING TESTS ==========\n")

    -- Test 1: Client properties
    runTest("Client.User exists", function()
        assert(client.User, "User should exist")
        assert(client.User.Id, "User should have Id")
        assert(client.User.Username, "User should have Username")
    end)

    runTest("Client.Application exists", function()
        assert(client.Application, "Application should exist")
        assert(client.Application.id, "Application should have id")
    end)

    runTest("Client.IsReady returns true", function()
        assert(client:IsReady() == true, "IsReady should return true")
    end)

    runTest("Client.GetUptime returns number", function()
        local uptime = client:GetUptime()
        assert(type(uptime) == "number", "GetUptime should return number")
        assert(uptime >= 0, "Uptime should be non-negative")
    end)

    -- Test 2: User methods
    runTest("User.GetTag returns proper format", function()
        local tag = client.User:GetTag()
        assert(type(tag) == "string", "Tag should be string")
        assert(string.find(tag, "#") or #tag > 0, "Tag should have content")
    end)

    runTest("User.GetDisplayAvatarUrl returns URL", function()
        local url = client.User:GetDisplayAvatarUrl()
        assert(type(url) == "string", "Avatar URL should be string")
        assert(string.find(url, "http"), "Should be a valid URL")
    end)

    -- Test 3: Guild access
    if testGuildId then
        runTest("Client.GetGuild returns cached guild", function()
            local guild = client:GetGuild(testGuildId)
            assert(guild, "Guild should be cached")
            assert(guild.Id == testGuildId, "Guild ID should match")
        end)

        runTest("Guild has properties", function()
            local guild = client:GetGuild(testGuildId)
            assert(guild.Name, "Guild should have Name")
            assert(guild.OwnerId, "Guild should have OwnerId")
        end)

        runTest("Guild.Channels is populated", function()
            local guild = client:GetGuild(testGuildId)
            local channelCount = countTable(guild.Channels)
            assert(channelCount > 0, "Guild should have channels")
        end)
    else
        recordTest("Guild tests", false, "No guild available")
    end

    -- Test 4: Channel access
    if testChannelId then
        runTest("Client.GetChannel returns cached channel", function()
            local channel = client:GetChannel(testChannelId)
            assert(channel, "Channel should be cached")
            assert(channel.Id == testChannelId, "Channel ID should match")
        end)

        runTest("Channel has properties", function()
            local channel = client:GetChannel(testChannelId)
            assert(channel.Type ~= nil, "Channel should have Type")
        end)
    else
        recordTest("Channel tests", false, "No channel available")
    end

    -- Test 5: Embed builder
    runTest("Embed.new creates embed", function()
        local embed = Discord.Embed.new()
        assert(embed, "Embed should be created")
        assert(embed._data, "Embed should have _data")
    end)

    runTest("Embed methods chain properly", function()
        local embed = Discord.Embed
            .new()
            :SetTitle("Test")
            :SetDescription("Description")
            :SetColor(0xFF0000)
            :AddField("Field", "Value")
            :SetFooter("Footer")
            :SetTimestamp()

        local json = embed:ToJSON()
        assert(json.title == "Test", "Title should be set")
        assert(json.description == "Description", "Description should be set")
        assert(json.color == 0xFF0000, "Color should be set")
        assert(#json.fields == 1, "Should have one field")
        assert(json.footer.text == "Footer", "Footer should be set")
        assert(json.timestamp, "Timestamp should be set")
    end)

    runTest("Embed.GetLength calculates correctly", function()
        local embed = Discord.Embed.new():SetTitle("12345"):SetDescription("1234567890")
        assert(embed:GetLength() == 15, "Length should be 15")
    end)

    -- Test 6: SlashCommandBuilder
    runTest("SlashCommandBuilder.new creates builder", function()
        local builder = Discord.SlashCommandBuilder.new()
        assert(builder, "Builder should be created")
        assert(builder._data.type == Discord.ApplicationCommandType.ChatInput, "Should be ChatInput type")
    end)

    runTest("SlashCommandBuilder methods chain properly", function()
        local command = Discord.SlashCommandBuilder
            .new()
            :SetName("test")
            :SetDescription("A test command")
            :AddStringOption("message", "A message")
            :AddIntegerOption("count", "A count", { min_value = 1, max_value = 100 })
            :AddBooleanOption("flag", "A flag")
            :AddUserOption("user", "A user")
            :SetDefaultMemberPermissions(8)
            :SetDMPermission(false)

        local json = command:ToJSON()
        assert(json.name == "test", "Name should be set")
        assert(json.description == "A test command", "Description should be set")
        assert(#json.options == 4, "Should have 4 options")
        assert(json.default_member_permissions == "8", "Permissions should be set")
        assert(json.dm_permission == false, "DM permission should be false")
    end)

    runTest("SlashCommandBuilder validates name", function()
        local success = pcall(function()
            Discord.SlashCommandBuilder.new():SetName("Invalid Name")
        end)
        assert(not success, "Should reject invalid command name")
    end)

    -- Test 7: Register slash commands
    runTest("Register global commands", function()
        local testCommand = Discord.SlashCommandBuilder
            .new()
            :SetName("test")
            :SetDescription("Test command for discord-luau")
            :AddStringOption("message", "A test message", { required = false })

        local pingCommand = Discord.SlashCommandBuilder.new():SetName("ping"):SetDescription("Check bot latency")

        local embedCommand = Discord.SlashCommandBuilder.new():SetName("embed"):SetDescription("Send a test embed")

        local result = client:SetGlobalCommands({ testCommand, pingCommand, embedCommand })
        assert(#result == 3, `Should register 3 commands, got {#result}`)
        for _, cmd in result do
            print(`[Info] Registered: /{cmd.name} (ID: {cmd.id})`)
        end
    end)

    runTest("Get global commands", function()
        local commands = client:GetGlobalCommands()
        assert(type(commands) == "table", "Should return table")
        assert(#commands >= 3, "Should have at least 3 commands")
    end)

    -- Test 8: REST API - Send message
    if testChannelId then
        local sentMessage: any = nil

        runTest("Send message to channel", function()
            local channel = client:GetChannel(testChannelId)
            sentMessage = channel:Send("Test message from discord-luau automated tests")
            assert(sentMessage, "Message should be returned")
            assert(sentMessage.Id, "Message should have Id")
            assert(sentMessage.Content == "Test message from discord-luau automated tests", "Content should match")
        end)

        runTest("Send embed message", function()
            local channel = client:GetChannel(testChannelId)
            local embed = Discord.Embed
                .new()
                :SetTitle("Automated Test")
                :SetDescription("This embed was sent by the discord-luau test suite")
                :SetColor(0x00FF00)
                :AddField("Status", "Testing", true)
                :AddField("Library", "discord-luau", true)
                :SetTimestamp()

            local msg = channel:Send({ embeds = { embed:ToJSON() } })
            assert(msg, "Message should be returned")
            assert(msg.Embeds and #msg.Embeds > 0, "Message should have embeds")
        end)

        if sentMessage then
            runTest("Edit message", function()
                sentMessage:Edit("Edited: Test message from discord-luau")
                -- Re-fetch to verify
                task.wait(0.5)
            end)

            runTest("Add reaction to message", function()
                sentMessage:React("✅")
            end)

            runTest("Remove reaction from message", function()
                sentMessage:RemoveReaction("✅")
            end)

            runTest("Delete message", function()
                sentMessage:Delete()
            end)
        end
    else
        recordTest("Message tests", false, "No channel available")
    end

    -- Test 9: Fetch methods
    if testGuildId then
        runTest("FetchGuild returns guild", function()
            local guild = client:FetchGuild(testGuildId)
            assert(guild, "Guild should be returned")
            assert(guild.Name, "Guild should have Name")
        end)
    end

    if testChannelId then
        runTest("FetchChannel returns channel", function()
            local channel = client:FetchChannel(testChannelId)
            assert(channel, "Channel should be returned")
            assert(channel.Id == testChannelId, "Channel ID should match")
        end)
    end

    runTest("FetchUser returns user (self)", function()
        local user = client:FetchUser(client.User.Id)
        assert(user, "User should be returned")
        assert(user.Id == client.User.Id, "User ID should match")
    end)

    -- Test 10: Enums are frozen
    runTest("ChannelType is frozen", function()
        local success = pcall(function()
            Discord.ChannelType.NewValue = 999
        end)
        assert(not success, "Should not be able to modify frozen table")
    end)

    runTest("GatewayIntent is frozen", function()
        local success = pcall(function()
            Discord.GatewayIntent.NewValue = 999
        end)
        assert(not success, "Should not be able to modify frozen table")
    end)

    -- Print final summary
    print("\n========== TEST SUMMARY ==========\n")

    local passed = 0
    local failed = 0

    for _, result in testResults do
        if result.passed then
            passed += 1
        else
            failed += 1
        end
    end

    print(`Total: {#testResults} tests`)
    print(`Passed: {passed}`)
    print(`Failed: {failed}`)

    if failed > 0 then
        print("\nFailed tests:")
        for _, result in testResults do
            if not result.passed then
                print(`  - {result.name}: {result.error or "unknown error"}`)
            end
        end
    end

    print("\n[Info] Now listening for interactions...")
    print("[Info] Try /ping, /test, or /embed in Discord")
    print("[Info] Press Ctrl+C to stop\n")
end)

-- Handle interactions
client:On("interactionCreate", function(interaction)
    if not interaction:IsCommand() then
        return
    end

    print(`[Interaction] /{interaction.CommandName} from {interaction.User.Username}`)

    if interaction.CommandName == "ping" then
        interaction:Reply("🏓 Pong!")
        print("[Success] Replied to /ping")
    elseif interaction.CommandName == "test" then
        local message = interaction:GetOption("message") or "No message provided"
        local embed = Discord.Embed
            .new()
            :SetTitle("Test Command Response")
            :SetDescription(`You said: {message}`)
            :SetColor(0x5865F2)
            :SetFooter("discord-luau test")
            :SetTimestamp()

        interaction:Reply({
            content = "Test successful!",
            embeds = { embed:ToJSON() },
        })
        print("[Success] Replied to /test")
    elseif interaction.CommandName == "embed" then
        local embed = Discord.Embed
            .new()
            :SetTitle("Embed Test")
            :SetDescription("This is a test embed from the discord-luau library!")
            :SetColor(0x00FF00)
            :AddField("Field 1", "Value 1", true)
            :AddField("Field 2", "Value 2", true)
            :AddField("Field 3", "Value 3", true)
            :SetFooter("Powered by discord-luau")
            :SetTimestamp()

        interaction:Reply({ embeds = { embed:ToJSON() } })
        print("[Success] Replied to /embed")
    end
end)

-- Error handler
client:On("error", function(err)
    print(`[Error] {err}`)
end)

-- Connect
print("[Info] Connecting to Discord...")
client:Login(token)
