--[[

ConnectionTest

Tests for the Connection class.

--]]

const Signal = require("@discordluau/Utils/Signal")

return function()
    describe("Connection", function()
        it("should be created by Signal:Connect", function()
            const signal = Signal.new()
            const connection = signal:Connect(function() end)

            expect(connection).to.be.ok()
            expect(connection.Connected).to.equal(true)
        end)

        it("should start in connected state", function()
            const signal = Signal.new()
            const connection = signal:Connect(function() end)

            expect(connection.Connected).to.equal(true)
        end)

        describe("Disconnect", function()
            it("should disconnect when called", function()
                const signal = Signal.new()
                const connection = signal:Connect(function() end)

                connection:Disconnect()

                expect(connection.Connected).to.equal(false)
            end)

            it("should prevent future calls", function()
                const signal = Signal.new()
                local callCount = 0
                const connection = signal:Connect(function()
                    callCount += 1
                end)

                signal:Fire()
                expect(callCount).to.equal(1)

                connection:Disconnect()

                signal:Fire()
                expect(callCount).to.equal(1)
            end)

            it("should be safe to call multiple times", function()
                const signal = Signal.new()
                const connection = signal:Connect(function() end)

                connection:Disconnect()
                connection:Disconnect()
                connection:Disconnect()

                expect(connection.Connected).to.equal(false)
            end)
        end)

        describe("multiple connections", function()
            it("should allow multiple connections to same signal", function()
                const signal = Signal.new()
                local count1 = 0
                local count2 = 0

                const conn1 = signal:Connect(function()
                    count1 += 1
                end)
                const conn2 = signal:Connect(function()
                    count2 += 1
                end)

                signal:Fire()

                expect(count1).to.equal(1)
                expect(count2).to.equal(1)
                expect(conn1.Connected).to.equal(true)
                expect(conn2.Connected).to.equal(true)
            end)

            it("should disconnect independently", function()
                const signal = Signal.new()
                local count1 = 0
                local count2 = 0

                const conn1 = signal:Connect(function()
                    count1 += 1
                end)
                const conn2 = signal:Connect(function()
                    count2 += 1
                end)

                signal:Fire()
                conn1:Disconnect()
                signal:Fire()

                expect(count1).to.equal(1)
                expect(count2).to.equal(2)
                expect(conn1.Connected).to.equal(false)
                expect(conn2.Connected).to.equal(true)
            end)
        end)
    end)
end
