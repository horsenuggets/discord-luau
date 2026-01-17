--[[

ClientTest

Tests for the Client class.

--]]

local Client = require("@discordluau/Classes/Client")
local GatewayIntent = require("@discordluau/Enums/GatewayIntent")
local MockClient = require("./Helpers/MockClient")
local MockData = require("./Helpers/MockData")
local TestUtils = require("./Helpers/TestUtils")

return function()
    describe("Client.new", function()
        it("should create a client with default options", function()
            local client = Client.new()
            expect(client).to.be.ok()
            expect(client.Guilds).to.be.a("table")
            expect(client.Channels).to.be.a("table")
            expect(client.Users).to.be.a("table")
        end)

        it("should create a client with numeric intents", function()
            local intents = bit32.bor(GatewayIntent.Guilds, GatewayIntent.GuildMessages)
            local client = Client.new({ intents = intents })
            expect(client._intents).to.equal(intents)
        end)

        it("should create a client with array intents", function()
            local client = Client.new({
                intents = { GatewayIntent.Guilds, GatewayIntent.GuildMessages, GatewayIntent.GuildMembers },
            })

            local expected = bit32.bor(GatewayIntent.Guilds, GatewayIntent.GuildMessages, GatewayIntent.GuildMembers)
            expect(client._intents).to.equal(expected)
        end)

        it("should initialize empty collections", function()
            local client = Client.new()
            expect(next(client.Guilds)).to.equal(nil)
            expect(next(client.Channels)).to.equal(nil)
            expect(next(client.Users)).to.equal(nil)
        end)

        it("should have _createMessage factory function", function()
            local client = Client.new()
            expect(client._createMessage).to.be.a("function")
        end)
    end)

    describe("Event handling", function()
        it("should register event handlers", function()
            local client = Client.new()
            local called = false

            client:On("test", function()
                called = true
            end)

            client:_emit("test")
            expect(called).to.equal(true)
        end)

        it("should call handlers with arguments", function()
            local client = Client.new()
            local receivedArgs = nil

            client:On("test", function(arg1, arg2)
                receivedArgs = { arg1, arg2 }
            end)

            client:_emit("test", "hello", 42)
            expect(receivedArgs[1]).to.equal("hello")
            expect(receivedArgs[2]).to.equal(42)
        end)

        it("should support multiple handlers", function()
            local client = Client.new()
            local count = 0

            client:On("test", function()
                count += 1
            end)
            client:On("test", function()
                count += 1
            end)

            client:_emit("test")
            expect(count).to.equal(2)
        end)

        it("should return disconnect function", function()
            local client = Client.new()
            local count = 0

            local disconnect = client:On("test", function()
                count += 1
            end)

            client:_emit("test")
            expect(count).to.equal(1)

            disconnect()
            client:_emit("test")
            expect(count).to.equal(1)
        end)

        it("should validate eventName type", function()
            local client = Client.new()

            expect(function()
                client:On(123 :: any, function() end)
            end).to.throw()
        end)

        it("should validate handler type", function()
            local client = Client.new()

            expect(function()
                client:On("test", "not a function" :: any)
            end).to.throw()
        end)
    end)

    describe("Once", function()
        it("should fire handler only once", function()
            local client = Client.new()
            local count = 0

            client:Once("test", function()
                count += 1
            end)

            client:_emit("test")
            client:_emit("test")
            expect(count).to.equal(1)
        end)

        it("should return disconnect function", function()
            local client = Client.new()
            local called = false

            local disconnect = client:Once("test", function()
                called = true
            end)

            disconnect()
            client:_emit("test")
            expect(called).to.equal(false)
        end)
    end)

    describe("Cache methods", function()
        local client

        beforeEach(function()
            client = MockClient.newWithData()
        end)

        describe("GetGuild", function()
            it("should return cached guild", function()
                local guild = client:GetGuild(MockData.Snowflakes.GuildId)
                expect(guild).to.be.ok()
                expect(guild.Id).to.equal(MockData.Snowflakes.GuildId)
            end)

            it("should return nil for non-existent guild", function()
                expect(client:GetGuild("nonexistent")).to.equal(nil)
            end)

            it("should validate guildId type", function()
                expect(function()
                    client:GetGuild(123 :: any)
                end).to.throw()
            end)
        end)

        describe("GetChannel", function()
            it("should return cached channel", function()
                local channel = client:GetChannel(MockData.Snowflakes.ChannelId)
                expect(channel).to.be.ok()
                expect(channel.Id).to.equal(MockData.Snowflakes.ChannelId)
            end)

            it("should return nil for non-existent channel", function()
                expect(client:GetChannel("nonexistent")).to.equal(nil)
            end)

            it("should validate channelId type", function()
                expect(function()
                    client:GetChannel(123 :: any)
                end).to.throw()
            end)
        end)

        describe("GetUser", function()
            it("should return cached user", function()
                local user = client:GetUser(MockData.Snowflakes.UserId)
                expect(user).to.be.ok()
                expect(user.Id).to.equal(MockData.Snowflakes.UserId)
            end)

            it("should return nil for non-existent user", function()
                expect(client:GetUser("nonexistent")).to.equal(nil)
            end)

            it("should validate userId type", function()
                expect(function()
                    client:GetUser(123 :: any)
                end).to.throw()
            end)
        end)
    end)

    describe("IsReady", function()
        it("should return false when not ready", function()
            local client = Client.new()
            expect(client:IsReady()).to.equal(false)
        end)

        it("should return true when ready", function()
            local client = MockClient.newWithData()
            expect(client:IsReady()).to.equal(true)
        end)
    end)

    describe("GetUptime", function()
        it("should return nil when not ready", function()
            local client = Client.new()
            expect(client:GetUptime()).to.equal(nil)
        end)

        it("should return uptime when ready", function()
            local client = MockClient.newWithData()
            local uptime = client:GetUptime()
            expect(uptime).to.be.a("number")
            expect(uptime >= 0).to.equal(true)
        end)
    end)

    describe("Destroy", function()
        it("should clear all state", function()
            local client = MockClient.newWithData()

            -- Add some handlers
            client:On("test", function() end)

            -- Verify state exists
            expect(client.User).to.be.ok()
            expect(next(client.Guilds)).to.be.ok()
            expect(next(client.Channels)).to.be.ok()
            expect(next(client.Users)).to.be.ok()

            -- Destroy
            client:Destroy()

            -- Verify state cleared
            expect(client.User).to.equal(nil)
            expect(client.Rest).to.equal(nil)
            expect(client.ReadyAt).to.equal(nil)
            expect(next(client.Guilds)).to.equal(nil)
            expect(next(client.Channels)).to.equal(nil)
            expect(next(client.Users)).to.equal(nil)
        end)
    end)

    describe("__tostring", function()
        it("should return not logged in when no user", function()
            local client = Client.new()
            expect(tostring(client)).to.equal("Client(not logged in)")
        end)

        it("should return client with user tag when logged in", function()
            local client = MockClient.newWithData()
            expect(TestUtils.contains(tostring(client), "Client(")).to.equal(true)
        end)
    end)

    describe("_handleDispatchEvent", function()
        local client

        beforeEach(function()
            client = Client.new()
        end)

        it("should handle GUILD_CREATE event", function()
            local receivedGuild = nil
            client:On("guildCreate", function(guild)
                receivedGuild = guild
            end)

            client:_handleDispatchEvent("GUILD_CREATE", MockData.GatewayGuildCreate)

            expect(receivedGuild).to.be.ok()
            expect(receivedGuild.Id).to.equal(MockData.Snowflakes.GuildId)
            expect(client.Guilds[MockData.Snowflakes.GuildId]).to.be.ok()
        end)

        it("should cache channels from GUILD_CREATE", function()
            client:_handleDispatchEvent("GUILD_CREATE", MockData.GatewayGuildCreate)

            expect(client.Channels[MockData.Snowflakes.ChannelId]).to.be.ok()
        end)

        it("should handle GUILD_DELETE event", function()
            -- First create the guild
            client:_handleDispatchEvent("GUILD_CREATE", MockData.GatewayGuildCreate)

            local receivedGuild = nil
            client:On("guildDelete", function(guild)
                receivedGuild = guild
            end)

            client:_handleDispatchEvent("GUILD_DELETE", { id = MockData.Snowflakes.GuildId })

            expect(receivedGuild).to.be.ok()
            expect(client.Guilds[MockData.Snowflakes.GuildId]).to.equal(nil)
        end)

        it("should handle GUILD_DELETE with unavailable flag", function()
            -- First create the guild
            client:_handleDispatchEvent("GUILD_CREATE", MockData.GatewayGuildCreate)

            local unavailableCalled = false
            client:On("guildUnavailable", function()
                unavailableCalled = true
            end)

            client:_handleDispatchEvent("GUILD_DELETE", { id = MockData.Snowflakes.GuildId, unavailable = true })

            expect(unavailableCalled).to.equal(true)
            expect(client.Guilds[MockData.Snowflakes.GuildId]).to.be.ok()
            expect(client.Guilds[MockData.Snowflakes.GuildId].Unavailable).to.equal(true)
        end)

        it("should handle CHANNEL_CREATE event", function()
            local receivedChannel = nil
            client:On("channelCreate", function(channel)
                receivedChannel = channel
            end)

            client:_handleDispatchEvent("CHANNEL_CREATE", MockData.TextChannel)

            expect(receivedChannel).to.be.ok()
            expect(client.Channels[MockData.TextChannel.id]).to.be.ok()
        end)

        it("should handle CHANNEL_DELETE event", function()
            -- First create the channel
            client:_handleDispatchEvent("CHANNEL_CREATE", MockData.TextChannel)

            local receivedChannel = nil
            client:On("channelDelete", function(channel)
                receivedChannel = channel
            end)

            client:_handleDispatchEvent("CHANNEL_DELETE", MockData.TextChannel)

            expect(receivedChannel).to.be.ok()
            expect(client.Channels[MockData.TextChannel.id]).to.equal(nil)
        end)

        it("should handle MESSAGE_CREATE event", function()
            local receivedMessage = nil
            client:On("messageCreate", function(message)
                receivedMessage = message
            end)

            client:_handleDispatchEvent("MESSAGE_CREATE", MockData.Message)

            expect(receivedMessage).to.be.ok()
            expect(receivedMessage.Id).to.equal(MockData.Message.id)
            expect(receivedMessage.Content).to.equal(MockData.Message.content)
        end)

        it("should cache author from MESSAGE_CREATE", function()
            client:_handleDispatchEvent("MESSAGE_CREATE", MockData.Message)
            expect(client.Users[MockData.User.id]).to.be.ok()
        end)

        it("should handle MESSAGE_DELETE event", function()
            local receivedData = nil
            client:On("messageDelete", function(data)
                receivedData = data
            end)

            client:_handleDispatchEvent("MESSAGE_DELETE", {
                channel_id = MockData.Snowflakes.ChannelId,
                id = MockData.Snowflakes.MessageId,
            })

            expect(receivedData).to.be.ok()
            expect(receivedData.id).to.equal(MockData.Snowflakes.MessageId)
        end)

        it("should handle INTERACTION_CREATE event", function()
            local receivedInteraction = nil
            client:On("interactionCreate", function(interaction)
                receivedInteraction = interaction
            end)

            client:_handleDispatchEvent("INTERACTION_CREATE", MockData.SlashCommandInteraction)

            expect(receivedInteraction).to.be.ok()
            expect(receivedInteraction.Id).to.equal(MockData.SlashCommandInteraction.id)
        end)

        it("should emit raw event for unhandled events", function()
            local receivedRaw = nil
            client:On("raw", function(data)
                receivedRaw = data
            end)

            client:_handleDispatchEvent("UNKNOWN_EVENT", { foo = "bar" })

            expect(receivedRaw).to.be.ok()
            expect(receivedRaw.t).to.equal("UNKNOWN_EVENT")
            expect(receivedRaw.d.foo).to.equal("bar")
        end)
    end)
end
