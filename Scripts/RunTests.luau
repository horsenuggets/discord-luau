#!/usr/bin/env -S lune run

--[[

RunTests

Executes all test suites and exits with appropriate status code.

--]]

local Testable = require("@devpackages/Testable")
local process = require("@lune/process")

local TESTS = {
    { Name = "ChannelTest", Func = require("../Tests/ChannelTest.spec") },
    { Name = "ClientTest", Func = require("../Tests/ClientTest.spec") },
    { Name = "ConnectionTest", Func = require("../Tests/ConnectionTest.spec") },
    { Name = "EmbedTest", Func = require("../Tests/EmbedTest.spec") },
    { Name = "EnumsTest", Func = require("../Tests/EnumsTest.spec") },
    { Name = "GuildTest", Func = require("../Tests/GuildTest.spec") },
    { Name = "IntegrationTest", Func = require("../Tests/IntegrationTest.spec") },
    { Name = "InteractionTest", Func = require("../Tests/InteractionTest.spec") },
    { Name = "MemberTest", Func = require("../Tests/MemberTest.spec") },
    { Name = "MessageTest", Func = require("../Tests/MessageTest.spec") },
    { Name = "RoleTest", Func = require("../Tests/RoleTest.spec") },
    { Name = "SignalTest", Func = require("../Tests/SignalTest.spec") },
    { Name = "SlashCommandBuilderTest", Func = require("../Tests/SlashCommandBuilderTest.spec") },
    { Name = "SnowflakeTest", Func = require("../Tests/SnowflakeTest.spec") },
    { Name = "UserTest", Func = require("../Tests/UserTest.spec") },
}

local function runTests()
    local _, passed = Testable.run(TESTS)
    process.exit(if passed then 0 else 1)
end

runTests()
