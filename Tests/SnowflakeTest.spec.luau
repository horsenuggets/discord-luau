--[[

SnowflakeTest

Tests for the Snowflake utility functions.

--]]

local Snowflake = require("@discordluau/Utils/Snowflake")

return function()
    -- Discord's example snowflake: 175928847299117063
    -- Timestamp: 1462015105796 (2016-04-30T11:18:25.796Z)
    local testSnowflake = "175928847299117063"

    describe("getTimestamp", function()
        it("should extract timestamp from snowflake", function()
            local timestamp = Snowflake.getTimestamp(testSnowflake)
            expect(type(timestamp)).to.equal("number")
            expect(timestamp).to.be.near(1462015105796, 1000)
        end)

        it("should throw for invalid snowflake", function()
            expect(function()
                Snowflake.getTimestamp("invalid")
            end).to.throw()
        end)

        it("should require string input", function()
            expect(function()
                Snowflake.getTimestamp(12345 :: any)
            end).to.throw()
        end)
    end)

    describe("getWorkerId", function()
        it("should extract worker ID from snowflake", function()
            local workerId = Snowflake.getWorkerId(testSnowflake)
            expect(type(workerId)).to.equal("number")
            expect(workerId).to.be.ok()
        end)
    end)

    describe("getProcessId", function()
        it("should extract process ID from snowflake", function()
            local processId = Snowflake.getProcessId(testSnowflake)
            expect(type(processId)).to.equal("number")
            expect(processId).to.be.ok()
        end)
    end)

    describe("getIncrement", function()
        it("should extract increment from snowflake", function()
            local increment = Snowflake.getIncrement(testSnowflake)
            expect(type(increment)).to.equal("number")
            expect(increment).to.be.ok()
        end)
    end)

    describe("compare", function()
        it("should return -1 when a < b", function()
            local result = Snowflake.compare("100", "200")
            expect(result).to.equal(-1)
        end)

        it("should return 1 when a > b", function()
            local result = Snowflake.compare("200", "100")
            expect(result).to.equal(1)
        end)

        it("should return 0 when a == b", function()
            local result = Snowflake.compare("100", "100")
            expect(result).to.equal(0)
        end)

        it("should throw for invalid snowflakes", function()
            expect(function()
                Snowflake.compare("invalid", "100")
            end).to.throw()
        end)
    end)
end
