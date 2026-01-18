--[[

SlashCommandBuilder

A builder class for creating Discord slash commands with a fluent API. Supports options,
subcommands, and permission requirements.

--]]

local ApplicationCommandOptionType = require("../Enums/ApplicationCommandOptionType")
local ApplicationCommandType = require("../Enums/ApplicationCommandType")

--[=[
    @class SlashCommandBuilder
    @tag structure

    A builder class for creating Discord slash commands with a fluent API.
    Supports options, subcommands, and permission requirements.

    ```lua
    local pingCommand = Discord.SlashCommandBuilder.new()
        :SetName("ping")
        :SetDescription("Check bot latency")

    local echoCommand = Discord.SlashCommandBuilder.new()
        :SetName("echo")
        :SetDescription("Echo a message")
        :AddStringOption("message", "The message to echo", { required = true })

    client:SetGlobalCommands({ pingCommand, echoCommand })
    ```
]=]
local SlashCommandBuilder = {}
SlashCommandBuilder.__index = SlashCommandBuilder

export type SlashCommandOptionChoice = {
    name: string,
    value: string | number,
}

export type SlashCommandOption = {
    type: number,
    name: string,
    description: string,
    required: boolean?,
    choices: { SlashCommandOptionChoice }?,
    options: { SlashCommandOption }?,
    min_value: number?,
    max_value: number?,
    min_length: number?,
    max_length: number?,
    autocomplete: boolean?,
    channel_types: { number }?,
}

export type SlashCommandBuilder = typeof(setmetatable(
    {} :: {
        _data: {
            name: string?,
            description: string?,
            type: number,
            options: { SlashCommandOption },
            default_member_permissions: string?,
            dm_permission: boolean?,
            nsfw: boolean?,
        },
    },
    SlashCommandBuilder
))

function SlashCommandBuilder.new(): SlashCommandBuilder
    local self = setmetatable({}, SlashCommandBuilder)

    self._data = {
        type = ApplicationCommandType.ChatInput,
        options = {},
    }

    return self
end

function SlashCommandBuilder.SetName(self: SlashCommandBuilder, name: string): SlashCommandBuilder
    assert(type(name) == "string", "Expected name to be a string")
    assert(#name >= 1 and #name <= 32, "Command name must be 1-32 characters")
    assert(
        string.match(name, "^[%l%d_-]+$"),
        "Command name must be lowercase alphanumeric with dashes and underscores only"
    )

    self._data.name = name
    return self
end

function SlashCommandBuilder.SetDescription(self: SlashCommandBuilder, description: string): SlashCommandBuilder
    assert(type(description) == "string", "Expected description to be a string")
    assert(#description >= 1 and #description <= 100, "Description must be 1-100 characters")

    self._data.description = description
    return self
end

function SlashCommandBuilder.SetType(self: SlashCommandBuilder, commandType: number): SlashCommandBuilder
    assert(type(commandType) == "number", "Expected commandType to be a number")

    self._data.type = commandType
    return self
end

function SlashCommandBuilder.SetDefaultMemberPermissions(
    self: SlashCommandBuilder,
    permissions: string | number
): SlashCommandBuilder
    if type(permissions) == "number" then
        self._data.default_member_permissions = tostring(permissions)
    else
        assert(type(permissions) == "string", "Expected permissions to be a string or number")
        self._data.default_member_permissions = permissions
    end

    return self
end

function SlashCommandBuilder.SetDMPermission(self: SlashCommandBuilder, allowed: boolean): SlashCommandBuilder
    assert(type(allowed) == "boolean", "Expected allowed to be a boolean")

    self._data.dm_permission = allowed
    return self
end

function SlashCommandBuilder.SetNSFW(self: SlashCommandBuilder, nsfw: boolean): SlashCommandBuilder
    assert(type(nsfw) == "boolean", "Expected nsfw to be a boolean")

    self._data.nsfw = nsfw
    return self
end

function SlashCommandBuilder.AddOption(self: SlashCommandBuilder, option: SlashCommandOption): SlashCommandBuilder
    assert(type(option) == "table", "Expected option to be a table")
    assert(type(option.type) == "number", "Expected option.type to be a number")
    assert(type(option.name) == "string", "Expected option.name to be a string")
    assert(type(option.description) == "string", "Expected option.description to be a string")

    table.insert(self._data.options, option)
    return self
end

function SlashCommandBuilder.AddStringOption(
    self: SlashCommandBuilder,
    name: string,
    description: string,
    options: {
        required: boolean?,
        choices: { SlashCommandOptionChoice }?,
        min_length: number?,
        max_length: number?,
        autocomplete: boolean?,
    }?
): SlashCommandBuilder
    assert(type(name) == "string", "Expected name to be a string")
    assert(type(description) == "string", "Expected description to be a string")

    local option: SlashCommandOption = {
        type = ApplicationCommandOptionType.String,
        name = name,
        description = description,
    }

    if options then
        option.required = options.required
        option.choices = options.choices
        option.min_length = options.min_length
        option.max_length = options.max_length
        option.autocomplete = options.autocomplete
    end

    table.insert(self._data.options, option)
    return self
end

function SlashCommandBuilder.AddIntegerOption(
    self: SlashCommandBuilder,
    name: string,
    description: string,
    options: {
        required: boolean?,
        choices: { SlashCommandOptionChoice }?,
        min_value: number?,
        max_value: number?,
        autocomplete: boolean?,
    }?
): SlashCommandBuilder
    assert(type(name) == "string", "Expected name to be a string")
    assert(type(description) == "string", "Expected description to be a string")

    local option: SlashCommandOption = {
        type = ApplicationCommandOptionType.Integer,
        name = name,
        description = description,
    }

    if options then
        option.required = options.required
        option.choices = options.choices
        option.min_value = options.min_value
        option.max_value = options.max_value
        option.autocomplete = options.autocomplete
    end

    table.insert(self._data.options, option)
    return self
end

function SlashCommandBuilder.AddNumberOption(
    self: SlashCommandBuilder,
    name: string,
    description: string,
    options: {
        required: boolean?,
        choices: { SlashCommandOptionChoice }?,
        min_value: number?,
        max_value: number?,
        autocomplete: boolean?,
    }?
): SlashCommandBuilder
    assert(type(name) == "string", "Expected name to be a string")
    assert(type(description) == "string", "Expected description to be a string")

    local option: SlashCommandOption = {
        type = ApplicationCommandOptionType.Number,
        name = name,
        description = description,
    }

    if options then
        option.required = options.required
        option.choices = options.choices
        option.min_value = options.min_value
        option.max_value = options.max_value
        option.autocomplete = options.autocomplete
    end

    table.insert(self._data.options, option)
    return self
end

function SlashCommandBuilder.AddBooleanOption(
    self: SlashCommandBuilder,
    name: string,
    description: string,
    options: { required: boolean? }?
): SlashCommandBuilder
    assert(type(name) == "string", "Expected name to be a string")
    assert(type(description) == "string", "Expected description to be a string")

    local option: SlashCommandOption = {
        type = ApplicationCommandOptionType.Boolean,
        name = name,
        description = description,
    }

    if options then
        option.required = options.required
    end

    table.insert(self._data.options, option)
    return self
end

function SlashCommandBuilder.AddUserOption(
    self: SlashCommandBuilder,
    name: string,
    description: string,
    options: { required: boolean? }?
): SlashCommandBuilder
    assert(type(name) == "string", "Expected name to be a string")
    assert(type(description) == "string", "Expected description to be a string")

    local option: SlashCommandOption = {
        type = ApplicationCommandOptionType.User,
        name = name,
        description = description,
    }

    if options then
        option.required = options.required
    end

    table.insert(self._data.options, option)
    return self
end

function SlashCommandBuilder.AddChannelOption(
    self: SlashCommandBuilder,
    name: string,
    description: string,
    options: {
        required: boolean?,
        channel_types: { number }?,
    }?
): SlashCommandBuilder
    assert(type(name) == "string", "Expected name to be a string")
    assert(type(description) == "string", "Expected description to be a string")

    local option: SlashCommandOption = {
        type = ApplicationCommandOptionType.Channel,
        name = name,
        description = description,
    }

    if options then
        option.required = options.required
        option.channel_types = options.channel_types
    end

    table.insert(self._data.options, option)
    return self
end

function SlashCommandBuilder.AddRoleOption(
    self: SlashCommandBuilder,
    name: string,
    description: string,
    options: { required: boolean? }?
): SlashCommandBuilder
    assert(type(name) == "string", "Expected name to be a string")
    assert(type(description) == "string", "Expected description to be a string")

    local option: SlashCommandOption = {
        type = ApplicationCommandOptionType.Role,
        name = name,
        description = description,
    }

    if options then
        option.required = options.required
    end

    table.insert(self._data.options, option)
    return self
end

function SlashCommandBuilder.AddMentionableOption(
    self: SlashCommandBuilder,
    name: string,
    description: string,
    options: { required: boolean? }?
): SlashCommandBuilder
    assert(type(name) == "string", "Expected name to be a string")
    assert(type(description) == "string", "Expected description to be a string")

    local option: SlashCommandOption = {
        type = ApplicationCommandOptionType.Mentionable,
        name = name,
        description = description,
    }

    if options then
        option.required = options.required
    end

    table.insert(self._data.options, option)
    return self
end

function SlashCommandBuilder.AddAttachmentOption(
    self: SlashCommandBuilder,
    name: string,
    description: string,
    options: { required: boolean? }?
): SlashCommandBuilder
    assert(type(name) == "string", "Expected name to be a string")
    assert(type(description) == "string", "Expected description to be a string")

    local option: SlashCommandOption = {
        type = ApplicationCommandOptionType.Attachment,
        name = name,
        description = description,
    }

    if options then
        option.required = options.required
    end

    table.insert(self._data.options, option)
    return self
end

function SlashCommandBuilder.AddSubCommand(
    self: SlashCommandBuilder,
    name: string,
    description: string,
    options: { SlashCommandOption }?
): SlashCommandBuilder
    assert(type(name) == "string", "Expected name to be a string")
    assert(type(description) == "string", "Expected description to be a string")

    local option: SlashCommandOption = {
        type = ApplicationCommandOptionType.SubCommand,
        name = name,
        description = description,
        options = options,
    }

    table.insert(self._data.options, option)
    return self
end

function SlashCommandBuilder.AddSubCommandGroup(
    self: SlashCommandBuilder,
    name: string,
    description: string,
    subcommands: { SlashCommandOption }
): SlashCommandBuilder
    assert(type(name) == "string", "Expected name to be a string")
    assert(type(description) == "string", "Expected description to be a string")
    assert(type(subcommands) == "table", "Expected subcommands to be a table")

    local option: SlashCommandOption = {
        type = ApplicationCommandOptionType.SubCommandGroup,
        name = name,
        description = description,
        options = subcommands,
    }

    table.insert(self._data.options, option)
    return self
end

function SlashCommandBuilder.ToJSON(self: SlashCommandBuilder): { [string]: any }
    assert(self._data.name, "Command name is required")
    assert(self._data.description, "Command description is required")

    local data: { [string]: any } = {
        name = self._data.name,
        description = self._data.description,
        type = self._data.type,
    }

    if #self._data.options > 0 then
        data.options = self._data.options
    end

    if self._data.default_member_permissions then
        data.default_member_permissions = self._data.default_member_permissions
    end

    if self._data.dm_permission ~= nil then
        data.dm_permission = self._data.dm_permission
    end

    if self._data.nsfw then
        data.nsfw = self._data.nsfw
    end

    return data
end

return SlashCommandBuilder
