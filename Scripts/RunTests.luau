#!/usr/bin/env -S lune run

--[[

RunTests

Executes all test suites and exits with appropriate status code.

--]]

local Testable = require("@devpackages/Testable")
local process = require("@lune/process")

local TESTS = {
    { Name = "EmbedTest", Func = require("../Tests/EmbedTest.spec") },
    { Name = "EnumsTest", Func = require("../Tests/EnumsTest.spec") },
    { Name = "SignalTest", Func = require("../Tests/SignalTest.spec") },
    { Name = "SlashCommandBuilderTest", Func = require("../Tests/SlashCommandBuilderTest.spec") },
    { Name = "SnowflakeTest", Func = require("../Tests/SnowflakeTest.spec") },
}

local function runTests()
    local _, passed = Testable.run(TESTS)
    process.exit(if passed then 0 else 1)
end

runTests()
