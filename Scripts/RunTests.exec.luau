#!/usr/bin/env -S lune run

--[[

RunTests.exec

Executes all test suites and exits with appropriate status code. Optionally pass a test
name as an argument to run only that test suite.

[Usage] ./Scripts/RunTests.exec.luau [TestName]

--]]

const Dotenv = require("@devpackages/Dotenv")
const Testable = require("@devpackages/Testable")
const process = require("@lune/process")
const stdio = require("@lune/stdio")

const RunTests = {}

--[[
    Requires every test suite. The integration suites read their credentials from the
    environment when they load, so this must run after the .env file is loaded.
--]]
function RunTests.load()
    return {
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
end

function RunTests.exec()
    -- Load environment variables from .env file (optional)
    pcall(Dotenv.load)

    -- Disable parallel execution for integration tests that make API calls
    -- This prevents rate limiting issues with the Discord API
    Testable.configure({
        Parallel = false,
    })

    const tests = RunTests.load()
    const filterName = process.args[1]
    local testsToRun = tests

    if filterName then
        testsToRun = {}
        for _, test in tests do
            if test.Name == filterName then
                table.insert(testsToRun, test)
            end
        end

        if #testsToRun == 0 then
            stdio.ewrite(`No test suite found with name "{filterName}".\n`)
            stdio.ewrite("Available test suites:\n")
            for _, test in tests do
                stdio.ewrite(`  - {test.Name}\n`)
            end
            process.exit(1)
        end
    end

    const _, passed = Testable.run(testsToRun)
    process.exit(if passed then 0 else 1)
end

RunTests.exec()
