--[[

Interaction

Represents a Discord interaction (slash command, button click, etc.) and provides methods
for responding to it.

--]]

local InteractionResponseType = require("../Enums/InteractionResponseType")
local InteractionType = require("../Enums/InteractionType")
local Member = require("./Member")
local Types = require("./Types")
local User = require("./User")

--[=[
    @class Interaction
    @tag structure

    Represents a Discord interaction such as a slash command, button click, select menu,
    or modal submission. Provides methods for replying, deferring, and editing responses.

    ```lua
    client:On("interactionCreate", function(interaction)
        if interaction:IsCommand() and interaction.CommandName == "ping" then
            interaction:Reply("Pong!")
        end
    end)
    ```
]=]
local Interaction = {}
Interaction.__index = Interaction

export type InteractionReplyOptions = {
    content: string?,
    embeds: { { [string]: any } }?,
    ephemeral: boolean?,
    components: { { [string]: any } }?,
    allowed_mentions: { [string]: any }?,
    tts: boolean?,
}

export type Interaction = typeof(setmetatable(
    {} :: {
        _client: any,
        _deferred: boolean,
        _replied: boolean,
        Id: Types.Snowflake,
        ApplicationId: Types.Snowflake,
        Type: number,
        GuildId: Types.Snowflake?,
        ChannelId: Types.Snowflake?,
        Member: Member.Member?,
        User: User.User,
        Token: string,
        Version: number,
        Message: { [string]: any }?,
        AppPermissions: string?,
        Locale: string?,
        GuildLocale: string?,
        CommandName: string?,
        CommandId: Types.Snowflake?,
        CommandType: number?,
        Options: { [string]: any },
        CustomId: string?,
        ComponentType: number?,
        Values: { string }?,
    },
    Interaction
))

function Interaction.new(client: any, data: Types.APIInteraction): Interaction
    local self = setmetatable({}, Interaction)

    self._client = client
    self._deferred = false
    self._replied = false

    self.Id = data.id
    self.ApplicationId = data.application_id
    self.Type = data.type
    self.GuildId = data.guild_id
    self.ChannelId = data.channel_id
    self.Token = data.token
    self.Version = data.version
    self.Message = data.message
    self.AppPermissions = data.app_permissions
    self.Locale = data.locale
    self.GuildLocale = data.guild_locale

    -- Parse user/member
    if data.member then
        -- Get guild from cache if available
        local guild = data.guild_id and client:GetGuild(data.guild_id) or nil
        if guild then
            self.Member = Member.new(client, guild, data.member)
        end
        if data.member.user then
            self.User = User.new(client, data.member.user)
        end
    elseif data.user then
        self.User = User.new(client, data.user)
    end

    -- Parse interaction data
    self.Options = {}
    if data.data then
        self.CommandName = data.data.name
        self.CommandId = data.data.id
        self.CommandType = data.data.type
        self.CustomId = data.data.custom_id
        self.ComponentType = data.data.component_type
        self.Values = data.data.values

        -- Parse options into a key-value map
        if data.data.options then
            self:_parseOptions(data.data.options, data.data.resolved)
        end
    end

    return self
end

function Interaction._parseOptions(
    self: Interaction,
    options: { Types.APIInteractionOption },
    resolved: { [string]: any }?
)
    for _, option in options do
        if option.type == 1 or option.type == 2 then
            -- SubCommand or SubCommandGroup
            self.Options._subcommand = option.name
            if option.options then
                self:_parseOptions(option.options, resolved)
            end
        else
            -- Regular option
            local value = option.value

            -- Resolve users, members, roles, channels from resolved data
            if resolved then
                if option.type == 6 and resolved.users then
                    -- User type
                    local userData = resolved.users[tostring(value)]
                    if userData then
                        value = User.new(self._client, userData)
                    end
                elseif option.type == 7 and resolved.channels then
                    -- Channel type
                    value = resolved.channels[tostring(value)]
                elseif option.type == 8 and resolved.roles then
                    -- Role type
                    value = resolved.roles[tostring(value)]
                elseif option.type == 11 and resolved.attachments then
                    -- Attachment type
                    value = resolved.attachments[tostring(value)]
                end
            end

            self.Options[option.name] = value
        end
    end
end

function Interaction.IsCommand(self: Interaction): boolean
    return self.Type == InteractionType.ApplicationCommand
end

function Interaction.IsButton(self: Interaction): boolean
    return self.Type == InteractionType.MessageComponent and self.ComponentType == 2
end

function Interaction.IsSelectMenu(self: Interaction): boolean
    return self.Type == InteractionType.MessageComponent and self.ComponentType and self.ComponentType >= 3
end

function Interaction.IsAutocomplete(self: Interaction): boolean
    return self.Type == InteractionType.ApplicationCommandAutocomplete
end

function Interaction.IsModalSubmit(self: Interaction): boolean
    return self.Type == InteractionType.ModalSubmit
end

function Interaction.GetOption(self: Interaction, name: string): any
    return self.Options[name]
end

function Interaction.GetSubcommand(self: Interaction): string?
    return self.Options._subcommand
end

function Interaction.Reply(self: Interaction, options: InteractionReplyOptions | string)
    assert(not self._replied, "This interaction has already been replied to")

    local data: { [string]: any }

    if type(options) == "string" then
        data = { content = options }
    else
        data = {
            content = options.content,
            embeds = options.embeds,
            components = options.components,
            allowed_mentions = options.allowed_mentions,
            tts = options.tts,
        }

        if options.ephemeral then
            data.flags = 64
        end
    end

    self._client.Rest:CreateInteractionResponse(self.Id, self.Token, {
        type = InteractionResponseType.ChannelMessageWithSource,
        data = data,
    })

    self._replied = true
end

function Interaction.DeferReply(self: Interaction, ephemeral: boolean?)
    assert(not self._replied, "This interaction has already been replied to")
    assert(not self._deferred, "This interaction has already been deferred")

    local data: { [string]: any }?

    if ephemeral then
        data = { flags = 64 }
    end

    self._client.Rest:CreateInteractionResponse(self.Id, self.Token, {
        type = InteractionResponseType.DeferredChannelMessageWithSource,
        data = data,
    })

    self._deferred = true
    self._replied = true
end

function Interaction.EditReply(self: Interaction, options: InteractionReplyOptions | string)
    assert(self._replied, "Cannot edit a reply that has not been sent")

    local data: { [string]: any }

    if type(options) == "string" then
        data = { content = options }
    else
        data = {
            content = options.content,
            embeds = options.embeds,
            components = options.components,
            allowed_mentions = options.allowed_mentions,
        }
    end

    self._client.Rest:EditOriginalInteractionResponse(self.ApplicationId, self.Token, data)
end

function Interaction.DeleteReply(self: Interaction)
    assert(self._replied, "Cannot delete a reply that has not been sent")

    self._client.Rest:DeleteOriginalInteractionResponse(self.ApplicationId, self.Token)
end

function Interaction.FollowUp(self: Interaction, options: InteractionReplyOptions | string)
    assert(self._replied, "Cannot follow up before initial reply")

    local data: { [string]: any }

    if type(options) == "string" then
        data = { content = options }
    else
        data = {
            content = options.content,
            embeds = options.embeds,
            components = options.components,
            allowed_mentions = options.allowed_mentions,
            tts = options.tts,
        }

        if options.ephemeral then
            data.flags = 64
        end
    end

    -- Follow-up uses webhook endpoint
    self._client.Rest:CreateFollowupMessage(self.ApplicationId, self.Token, data)
end

function Interaction.DeferUpdate(self: Interaction)
    assert(not self._replied, "This interaction has already been replied to")
    assert(self.Type == InteractionType.MessageComponent, "DeferUpdate can only be used on component interactions")

    self._client.Rest:CreateInteractionResponse(self.Id, self.Token, {
        type = InteractionResponseType.DeferredUpdateMessage,
    })

    self._deferred = true
    self._replied = true
end

function Interaction.Update(self: Interaction, options: InteractionReplyOptions | string)
    assert(not self._replied, "This interaction has already been replied to")
    assert(self.Type == InteractionType.MessageComponent, "Update can only be used on component interactions")

    local data: { [string]: any }

    if type(options) == "string" then
        data = { content = options }
    else
        data = {
            content = options.content,
            embeds = options.embeds,
            components = options.components,
            allowed_mentions = options.allowed_mentions,
        }
    end

    self._client.Rest:CreateInteractionResponse(self.Id, self.Token, {
        type = InteractionResponseType.UpdateMessage,
        data = data,
    })

    self._replied = true
end

function Interaction.ShowModal(
    self: Interaction,
    modal: {
        custom_id: string,
        title: string,
        components: { { [string]: any } },
    }
)
    assert(not self._replied, "This interaction has already been replied to")

    self._client.Rest:CreateInteractionResponse(self.Id, self.Token, {
        type = InteractionResponseType.Modal,
        data = modal,
    })

    self._replied = true
end

function Interaction.Respond(self: Interaction, choices: { { name: string, value: string | number } })
    assert(self:IsAutocomplete(), "Respond with choices can only be used for autocomplete interactions")

    self._client.Rest:CreateInteractionResponse(self.Id, self.Token, {
        type = InteractionResponseType.ApplicationCommandAutocompleteResult,
        data = { choices = choices },
    })

    self._replied = true
end

return Interaction
