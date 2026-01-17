--[[

SignalTest

Tests for the Signal event system.

--]]

local Signal = require("@discordluau/Utils/Signal")
local task = require("@lune/task")

return function()
    describe("Signal.new", function()
        it("should create a new signal", function()
            local signal = Signal.new()
            expect(signal).to.be.ok()
            expect(signal._connections).to.be.a("table")
        end)
    end)

    describe("Connect", function()
        it("should add a connection", function()
            local signal = Signal.new()
            signal:Connect(function() end)
            expect(#signal._connections).to.equal(1)
        end)

        it("should return a connection object", function()
            local signal = Signal.new()
            local connection = signal:Connect(function() end)
            expect(connection).to.be.ok()
            expect(connection.Disconnect).to.be.a("function")
        end)
    end)

    describe("Fire", function()
        it("should call connected handlers", function()
            local signal = Signal.new()
            local called = false
            signal:Connect(function()
                called = true
            end)
            signal:Fire()
            task.wait(0.01)
            expect(called).to.equal(true)
        end)

        it("should pass arguments to handlers", function()
            local signal = Signal.new()
            local receivedValue = nil
            signal:Connect(function(value)
                receivedValue = value
            end)
            signal:Fire("test")
            task.wait(0.01)
            expect(receivedValue).to.equal("test")
        end)

        it("should call multiple handlers", function()
            local signal = Signal.new()
            local count = 0
            signal:Connect(function()
                count += 1
            end)
            signal:Connect(function()
                count += 1
            end)
            signal:Fire()
            task.wait(0.01)
            expect(count).to.equal(2)
        end)
    end)

    describe("Once", function()
        it("should only fire once", function()
            local signal = Signal.new()
            local count = 0
            signal:Once(function()
                count += 1
            end)
            signal:Fire()
            signal:Fire()
            task.wait(0.01)
            expect(count).to.equal(1)
        end)

        it("should be removed after firing", function()
            local signal = Signal.new()
            signal:Once(function() end)
            expect(#signal._connections).to.equal(1)
            signal:Fire()
            task.wait(0.01)
            expect(#signal._connections).to.equal(0)
        end)
    end)

    describe("Disconnect", function()
        it("should remove the connection", function()
            local signal = Signal.new()
            local connection = signal:Connect(function() end)
            expect(#signal._connections).to.equal(1)
            connection:Disconnect()
            expect(#signal._connections).to.equal(0)
        end)

        it("should prevent future calls", function()
            local signal = Signal.new()
            local called = false
            local connection = signal:Connect(function()
                called = true
            end)
            connection:Disconnect()
            signal:Fire()
            task.wait(0.01)
            expect(called).to.equal(false)
        end)
    end)

    describe("Destroy", function()
        it("should remove all connections", function()
            local signal = Signal.new()
            signal:Connect(function() end)
            signal:Connect(function() end)
            expect(#signal._connections).to.equal(2)
            signal:Destroy()
            expect(#signal._connections).to.equal(0)
        end)
    end)
end
