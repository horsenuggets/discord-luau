--[[

MessageTest

Tests for the Message structure class.

--]]

local Message = require("@discordluau/Structures/Message")
local MockClient = require("./Helpers/MockClient")
local MockData = require("./Helpers/MockData")
local TestUtils = require("./Helpers/TestUtils")

return function()
    local client

    beforeAll(function()
        client = MockClient.newWithData()
    end)

    beforeEach(function()
        client.Rest:clearCalls()
    end)

    describe("Message.new", function()
        it("should create a message from API data", function()
            local message = Message.new(client, MockData.Message)
            expect(message.Id).to.equal(MockData.Snowflakes.MessageId)
            expect(message.Content).to.equal("Hello, world!")
        end)

        it("should validate client parameter", function()
            expect(function()
                Message.new(nil :: any, MockData.Message)
            end).to.throw()
        end)

        it("should validate data parameter", function()
            expect(function()
                Message.new(client, nil :: any)
            end).to.throw()
        end)
    end)

    describe("Message properties", function()
        it("should parse all standard properties", function()
            local message = Message.new(client, MockData.Message)

            expect(message.Id).to.equal(MockData.Message.id)
            expect(message.ChannelId).to.equal(MockData.Message.channel_id)
            expect(message.Content).to.equal(MockData.Message.content)
            expect(message.Timestamp).to.equal(MockData.Message.timestamp)
            expect(message.Tts).to.equal(MockData.Message.tts)
            expect(message.MentionEveryone).to.equal(MockData.Message.mention_everyone)
            expect(message.Pinned).to.equal(MockData.Message.pinned)
            expect(message.Type).to.equal(MockData.Message.type)
        end)

        it("should parse author as User object", function()
            local message = Message.new(client, MockData.Message)
            expect(message.Author).to.be.ok()
            expect(message.Author.Id).to.equal(MockData.User.id)
            expect(message.Author.Username).to.equal(MockData.User.username)
        end)

        it("should parse mentions as User objects", function()
            local messageData = table.clone(MockData.Message)
            messageData.mentions = { MockData.User, MockData.BotUser }
            local message = Message.new(client, messageData)

            expect(#message.Mentions).to.equal(2)
            expect(message.Mentions[1].Username).to.equal(MockData.User.username)
            expect(message.Mentions[2].Username).to.equal(MockData.BotUser.username)
        end)

        it("should parse embeds array", function()
            local message = Message.new(client, MockData.MessageWithEmbed)
            expect(#message.Embeds).to.equal(1)
            expect(message.Embeds[1].title).to.equal("Test Embed")
        end)

        it("should parse message reference", function()
            local message = Message.new(client, MockData.ReplyMessage)
            expect(message.MessageReference).to.be.ok()
            expect(message.MessageReference.message_id).to.equal(MockData.Snowflakes.MessageId)
        end)

        it("should parse referenced message", function()
            local message = Message.new(client, MockData.ReplyMessage)
            expect(message.ReferencedMessage).to.be.ok()
            expect(message.ReferencedMessage.Content).to.equal("Hello, world!")
        end)
    end)

    describe("Reply", function()
        it("should send a reply with string content", function()
            local message = Message.new(client, MockData.Message)
            message:Reply("This is a reply")

            local calls = client.Rest:getCalls()
            expect(#calls > 0).to.equal(true)

            local lastCall = calls[#calls]
            expect(lastCall.method).to.equal("POST")
            expect(lastCall.body.content).to.equal("This is a reply")
            expect(lastCall.body.message_reference).to.be.ok()
            expect(lastCall.body.message_reference.message_id).to.equal(message.Id)
        end)

        it("should send a reply with options", function()
            local message = Message.new(client, MockData.Message)
            message:Reply({ content = "Reply content", tts = true })

            local calls = client.Rest:getCalls()
            local lastCall = calls[#calls]
            expect(lastCall.body.content).to.equal("Reply content")
            expect(lastCall.body.tts).to.equal(true)
            expect(lastCall.body.message_reference).to.be.ok()
        end)
    end)

    describe("Edit", function()
        it("should edit message with string content", function()
            local message = Message.new(client, MockData.Message)
            message:Edit("Edited content")

            local calls = client.Rest:getCalls()
            local lastCall = calls[#calls]
            expect(lastCall.method).to.equal("PATCH")
            expect(lastCall.body.content).to.equal("Edited content")
        end)

        it("should edit message with options", function()
            local message = Message.new(client, MockData.Message)
            message:Edit({ content = "New content", embeds = {} })

            local calls = client.Rest:getCalls()
            local lastCall = calls[#calls]
            expect(lastCall.body.content).to.equal("New content")
            expect(lastCall.body.embeds).to.be.a("table")
        end)
    end)

    describe("Delete", function()
        it("should delete the message", function()
            local message = Message.new(client, MockData.Message)
            message:Delete()

            local calls = client.Rest:getCalls()
            local lastCall = calls[#calls]
            expect(lastCall.method).to.equal("DELETE")
            expect(TestUtils.contains(lastCall.endpoint, "messages")).to.equal(true)
        end)
    end)

    describe("React", function()
        it("should add a reaction", function()
            local message = Message.new(client, MockData.Message)
            message:React("👍")

            local calls = client.Rest:getCalls()
            local lastCall = calls[#calls]
            expect(lastCall.method).to.equal("PUT")
            expect(TestUtils.contains(lastCall.endpoint, "reactions")).to.equal(true)
        end)
    end)

    describe("RemoveReaction", function()
        it("should remove own reaction", function()
            local message = Message.new(client, MockData.Message)
            message:RemoveReaction("👍")

            local calls = client.Rest:getCalls()
            local lastCall = calls[#calls]
            expect(lastCall.method).to.equal("DELETE")
            expect(TestUtils.contains(lastCall.endpoint, "@me")).to.equal(true)
        end)

        it("should remove user reaction", function()
            local message = Message.new(client, MockData.Message)
            message:RemoveReaction("👍", MockData.Snowflakes.UserId)

            local calls = client.Rest:getCalls()
            local lastCall = calls[#calls]
            expect(lastCall.method).to.equal("DELETE")
            expect(TestUtils.contains(lastCall.endpoint, MockData.Snowflakes.UserId)).to.equal(true)
        end)
    end)

    describe("Pin", function()
        it("should pin the message", function()
            local message = Message.new(client, MockData.Message)
            message:Pin()

            local calls = client.Rest:getCalls()
            local lastCall = calls[#calls]
            expect(lastCall.method).to.equal("PUT")
            expect(TestUtils.contains(lastCall.endpoint, "pins")).to.equal(true)
        end)
    end)

    describe("Unpin", function()
        it("should unpin the message", function()
            local message = Message.new(client, MockData.Message)
            message:Unpin()

            local calls = client.Rest:getCalls()
            local lastCall = calls[#calls]
            expect(lastCall.method).to.equal("DELETE")
            expect(TestUtils.contains(lastCall.endpoint, "pins")).to.equal(true)
        end)
    end)

    describe("GetUrl", function()
        it("should return guild message URL", function()
            local messageData = table.clone(MockData.Message)
            local message = Message.new(client, messageData)
            message.GuildId = MockData.Snowflakes.GuildId

            local url = message:GetUrl()
            expect(TestUtils.contains(url, MockData.Snowflakes.GuildId)).to.equal(true)
            expect(TestUtils.contains(url, MockData.Message.channel_id)).to.equal(true)
            expect(TestUtils.contains(url, MockData.Message.id)).to.equal(true)
        end)

        it("should return DM message URL", function()
            local message = Message.new(client, MockData.Message)
            local url = message:GetUrl()

            expect(TestUtils.contains(url, "@me")).to.equal(true)
            expect(TestUtils.contains(url, MockData.Message.channel_id)).to.equal(true)
            expect(TestUtils.contains(url, MockData.Message.id)).to.equal(true)
        end)
    end)

    describe("IsFromBot", function()
        it("should return false for user messages", function()
            local message = Message.new(client, MockData.Message)
            expect(message:IsFromBot()).to.equal(false)
        end)

        it("should return true for bot messages", function()
            local message = Message.new(client, MockData.MessageWithEmbed)
            expect(message:IsFromBot()).to.equal(true)
        end)
    end)

    describe("IsFromWebhook", function()
        it("should return false for normal messages", function()
            local message = Message.new(client, MockData.Message)
            expect(message:IsFromWebhook()).to.equal(false)
        end)

        it("should return true for webhook messages", function()
            local messageData = table.clone(MockData.Message)
            messageData.webhook_id = MockData.Snowflakes.WebhookId
            local message = Message.new(client, messageData)

            expect(message:IsFromWebhook()).to.equal(true)
        end)
    end)

    describe("IsReply", function()
        it("should return false for normal messages", function()
            local message = Message.new(client, MockData.Message)
            expect(message:IsReply()).to.equal(false)
        end)

        it("should return true for reply messages", function()
            local message = Message.new(client, MockData.ReplyMessage)
            expect(message:IsReply()).to.equal(true)
        end)
    end)

    describe("IsPinned", function()
        it("should return false for unpinned messages", function()
            local message = Message.new(client, MockData.Message)
            expect(message:IsPinned()).to.equal(false)
        end)

        it("should return true for pinned messages", function()
            local messageData = table.clone(MockData.Message)
            messageData.pinned = true
            local message = Message.new(client, messageData)

            expect(message:IsPinned()).to.equal(true)
        end)
    end)

    describe("HasEmbeds", function()
        it("should return false for messages without embeds", function()
            local message = Message.new(client, MockData.Message)
            expect(message:HasEmbeds()).to.equal(false)
        end)

        it("should return true for messages with embeds", function()
            local message = Message.new(client, MockData.MessageWithEmbed)
            expect(message:HasEmbeds()).to.equal(true)
        end)
    end)

    describe("HasAttachments", function()
        it("should return false for messages without attachments", function()
            local message = Message.new(client, MockData.Message)
            expect(message:HasAttachments()).to.equal(false)
        end)

        it("should return true for messages with attachments", function()
            local messageData = table.clone(MockData.Message)
            messageData.attachments = { { id = "123", filename = "test.png" } }
            local message = Message.new(client, messageData)

            expect(message:HasAttachments()).to.equal(true)
        end)
    end)

    describe("__tostring", function()
        it("should return Message(id) format", function()
            local message = Message.new(client, MockData.Message)
            expect(tostring(message)).to.equal(`Message({MockData.Message.id})`)
        end)
    end)
end
