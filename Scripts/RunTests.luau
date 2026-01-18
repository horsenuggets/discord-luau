#!/usr/bin/env -S lune run

--[[

RunTests

Executes all test suites and exits with appropriate status code.

Usage:
    lune run Scripts/RunTests              -- Run all tests
    lune run Scripts/RunTests Voice        -- Run tests matching "Voice"
    lune run Scripts/RunTests Voice Lava   -- Run tests matching "Voice" or "Lava"

--]]

local Testable = require("@devpackages/Testable")
local process = require("@lune/process")

-- Load environment variables from .env file
local loadEnv = require("@self/LoadEnv")
loadEnv()

-- Disable parallel execution for integration tests that make API calls
-- This prevents rate limiting issues with the Discord API
Testable.configure({
    Parallel = false,
})

local ALL_TESTS = {
    { Name = "ChannelTest", Func = require("@tests/ChannelTest.spec") },
    { Name = "ClientTest", Func = require("@tests/ClientTest.spec") },
    { Name = "ConnectionTest", Func = require("@tests/ConnectionTest.spec") },
    { Name = "EmbedTest", Func = require("@tests/EmbedTest.spec") },
    { Name = "EnumsTest", Func = require("@tests/EnumsTest.spec") },
    { Name = "GuildTest", Func = require("@tests/GuildTest.spec") },
    { Name = "IntegrationTest", Func = require("@tests/IntegrationTest.spec") },
    { Name = "InteractionTest", Func = require("@tests/InteractionTest.spec") },
    { Name = "LavalinkTest", Func = require("@tests/LavalinkTest.spec") },
    { Name = "MemberTest", Func = require("@tests/MemberTest.spec") },
    { Name = "MessageTest", Func = require("@tests/MessageTest.spec") },
    { Name = "RoleTest", Func = require("@tests/RoleTest.spec") },
    { Name = "SignalTest", Func = require("@tests/SignalTest.spec") },
    { Name = "SlashCommandBuilderTest", Func = require("@tests/SlashCommandBuilderTest.spec") },
    { Name = "SnowflakeTest", Func = require("@tests/SnowflakeTest.spec") },
    { Name = "UserTest", Func = require("@tests/UserTest.spec") },
    { Name = "VoiceIntegrationTest", Func = require("@tests/VoiceIntegrationTest.spec") },
    { Name = "VoiceStateTest", Func = require("@tests/VoiceStateTest.spec") },
}

local function filterTests(filters: { string }): { { Name: string, Func: () -> () } }
    if #filters == 0 then
        return ALL_TESTS
    end

    local filtered = {}
    for _, test in ALL_TESTS do
        for _, filter in filters do
            if string.find(string.lower(test.Name), string.lower(filter)) then
                table.insert(filtered, test)
                break
            end
        end
    end
    return filtered
end

local function runTests()
    local tests = filterTests(process.args)

    if #tests == 0 then
        print("No tests matched the provided filters.")
        process.exit(1)
    end

    if #process.args > 0 then
        local names = {}
        for _, test in tests do
            table.insert(names, test.Name)
        end
        print(`Running {#tests} test suite(s): {table.concat(names, ", ")}`)
    end

    local _, passed = Testable.run(tests)
    process.exit(if passed then 0 else 1)
end

runTests()
