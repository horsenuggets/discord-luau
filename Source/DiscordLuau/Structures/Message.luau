--[[

Message

Represents a Discord message. Contains content, author, attachments, embeds, and provides
methods for replying, reacting, and editing.

--]]

local Member = require("./Member")
local Types = require("./Types")
local User = require("./User")

-- Deferred require to avoid circular dependency with Channel
local Channel: any = nil
local function getChannel()
    if not Channel then
        Channel = require("./Channel")
    end
    return Channel
end

--[=[
    @class Message
    @tag structure

    Represents a Discord message with content, author, attachments, and embeds.
    Provides methods for replying, reacting, editing, and deleting.

    ```lua
    client:On("messageCreate", function(message)
        if message.Content == "!ping" then
            message:Reply("Pong!")
        end
    end)
    ```
]=]
local Message = {}
Message.__index = Message

export type Message = typeof(setmetatable(
    {} :: {
        Activity: Types.APIMessageActivity?,
        ApplicationId: Types.Snowflake?,
        Attachments: { Types.APIAttachment },
        Author: User.User,
        Channel: any?,
        ChannelId: Types.Snowflake,
        Client: Types.Client,
        Components: { Types.APIComponent }?,
        Content: string,
        EditedTimestamp: string?,
        Embeds: { Types.APIEmbed },
        Flags: number?,
        Guild: Types.Guild?,
        GuildId: Types.Snowflake?,
        Id: Types.Snowflake,
        Interaction: Types.APIMessageInteraction?,
        Member: Member.Member?,
        MentionChannels: { Types.APIChannelMention }?,
        MentionEveryone: boolean,
        MentionRoles: { Types.Snowflake },
        Mentions: { User.User },
        MessageReference: Types.APIMessageReference?,
        Nonce: (string | number)?,
        Pinned: boolean,
        Poll: Types.APIPoll?,
        Position: number?,
        Reactions: { Types.APIReaction }?,
        ReferencedMessage: Message?,
        StickerItems: { Types.APIStickerItem }?,
        Thread: any?,
        Timestamp: string,
        Tts: boolean,
        Type: number,
        WebhookId: Types.Snowflake?,
        _data: Types.APIMessage,
    },
    Message
))

function Message.new(client: Types.Client, data: Types.APIMessage): Message
    assert(type(client) == "table", "Expected client to be a table")
    assert(type(data) == "table", "Expected data to be a table")

    local self = setmetatable({}, Message)

    self.Client = client
    self._data = data

    self:_patch(data)

    return self
end

function Message._patch(self: Message, data: Types.APIMessage)
    self.Activity = data.activity
    self.ApplicationId = data.application_id
    self.Attachments = data.attachments
    self.Author = User.new(self.Client, data.author)
    self.ChannelId = data.channel_id
    self.Components = data.components
    self.Content = data.content
    self.EditedTimestamp = data.edited_timestamp
    self.Embeds = data.embeds
    self.Flags = data.flags
    self.Id = data.id
    self.Interaction = data.interaction
    self.MentionChannels = data.mention_channels
    self.MentionEveryone = data.mention_everyone
    self.MentionRoles = data.mention_roles
    self.MessageReference = data.message_reference
    self.Nonce = data.nonce
    self.Pinned = data.pinned
    self.Poll = data.poll
    self.Position = data.position
    self.Reactions = data.reactions
    self.StickerItems = data.sticker_items
    self.Timestamp = data.timestamp
    self.Tts = data.tts
    self.Type = data.type
    self.WebhookId = data.webhook_id

    -- Parse mentions into User objects
    self.Mentions = {}
    for _, userData in data.mentions do
        table.insert(self.Mentions, User.new(self.Client, userData))
    end

    -- Parse member if present
    if data.member then
        -- Need guild context for Member, will be set later if available
        self.Member = nil
    end

    -- Parse thread if present
    if data.thread then
        self.Thread = getChannel().new(self.Client, data.thread, self.Guild)
    end

    -- Parse referenced message if present
    if data.referenced_message then
        self.ReferencedMessage = Message.new(self.Client, data.referenced_message)
    end
end

function Message.Reply(self: Message, options: string | Types.MessageSendOptions): Message
    local body: Types.MessageSendOptions
    if type(options) == "string" then
        body = {
            content = options,
            message_reference = {
                message_id = self.Id,
                channel_id = self.ChannelId,
                guild_id = self.GuildId,
            },
        }
    else
        body = options
        body.message_reference = {
            message_id = self.Id,
            channel_id = self.ChannelId,
            guild_id = self.GuildId,
        }
    end

    return self.Client.Rest:CreateMessage(self.ChannelId, body)
end

function Message.Edit(self: Message, options: string | Types.MessageSendOptions): Message
    local body: Types.MessageSendOptions
    if type(options) == "string" then
        body = { content = options }
    else
        body = options
    end

    return self.Client.Rest:EditMessage(self.ChannelId, self.Id, body)
end

function Message.Delete(self: Message)
    self.Client.Rest:DeleteMessage(self.ChannelId, self.Id)
end

function Message.React(self: Message, emoji: string)
    self.Client.Rest:CreateReaction(self.ChannelId, self.Id, emoji)
end

function Message.RemoveReaction(self: Message, emoji: string, userId: Types.Snowflake?)
    if userId then
        self.Client.Rest:DeleteUserReaction(self.ChannelId, self.Id, emoji, userId)
    else
        self.Client.Rest:DeleteOwnReaction(self.ChannelId, self.Id, emoji)
    end
end

function Message.Pin(self: Message)
    self.Client.Rest:PinMessage(self.ChannelId, self.Id)
end

function Message.Unpin(self: Message)
    self.Client.Rest:UnpinMessage(self.ChannelId, self.Id)
end

function Message.StartThread(self: Message, name: string, options: { auto_archive_duration: number? }?): any
    return self.Client.Rest:StartThreadFromMessage(self.ChannelId, self.Id, name, options)
end

function Message.CrossPost(self: Message): Message
    return self.Client.Rest:CrosspostMessage(self.ChannelId, self.Id)
end

function Message.GetUrl(self: Message): string
    if self.GuildId then
        return `https://discord.com/channels/{self.GuildId}/{self.ChannelId}/{self.Id}`
    else
        return `https://discord.com/channels/@me/{self.ChannelId}/{self.Id}`
    end
end

function Message.IsFromBot(self: Message): boolean
    return self.Author.Bot
end

function Message.IsFromWebhook(self: Message): boolean
    return self.WebhookId ~= nil
end

function Message.IsReply(self: Message): boolean
    return self.Type == 19 or self.MessageReference ~= nil
end

function Message.IsPinned(self: Message): boolean
    return self.Pinned
end

function Message.HasEmbeds(self: Message): boolean
    return #self.Embeds > 0
end

function Message.HasAttachments(self: Message): boolean
    return #self.Attachments > 0
end

function Message.__tostring(self: Message): string
    return `Message({self.Id})`
end

return Message
