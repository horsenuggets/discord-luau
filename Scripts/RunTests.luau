#!/usr/bin/env -S lune run

--[[

RunTests

Executes all test suites and exits with appropriate status code.

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

local TESTS = {
    { Name = "ChannelTest", Func = require("@tests/ChannelTest.spec") },
    { Name = "ClientTest", Func = require("@tests/ClientTest.spec") },
    { Name = "ConnectionTest", Func = require("@tests/ConnectionTest.spec") },
    { Name = "EmbedTest", Func = require("@tests/EmbedTest.spec") },
    { Name = "EnumsTest", Func = require("@tests/EnumsTest.spec") },
    { Name = "GuildTest", Func = require("@tests/GuildTest.spec") },
    { Name = "IntegrationTest", Func = require("@tests/IntegrationTest.spec") },
    { Name = "InteractionTest", Func = require("@tests/InteractionTest.spec") },
    { Name = "MemberTest", Func = require("@tests/MemberTest.spec") },
    { Name = "MessageTest", Func = require("@tests/MessageTest.spec") },
    { Name = "RoleTest", Func = require("@tests/RoleTest.spec") },
    { Name = "SignalTest", Func = require("@tests/SignalTest.spec") },
    { Name = "SlashCommandBuilderTest", Func = require("@tests/SlashCommandBuilderTest.spec") },
    { Name = "SnowflakeTest", Func = require("@tests/SnowflakeTest.spec") },
    { Name = "UserTest", Func = require("@tests/UserTest.spec") },
}

local function runTests()
    local _, passed = Testable.run(TESTS)
    process.exit(if passed then 0 else 1)
end

runTests()
