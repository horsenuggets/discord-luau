--[[

Embed

Builder class for creating rich embed content for messages. Supports title, description,
fields, images, author, footer, and more.

--]]

local Types = require("@self/Types")

local Embed = {}
Embed.__index = Embed

export type Embed = typeof(setmetatable(
    {} :: {
        _data: Types.APIEmbed,
    },
    Embed
))

function Embed.new(data: Types.APIEmbed?): Embed
    local self = setmetatable({}, Embed)

    self._data = data or {}

    return self
end

function Embed.SetTitle(self: Embed, title: string): Embed
    assert(type(title) == "string", "Expected title to be a string")
    assert(#title <= 256, "Title must be 256 characters or less")

    self._data.title = title
    return self
end

function Embed.SetDescription(self: Embed, description: string): Embed
    assert(type(description) == "string", "Expected description to be a string")
    assert(#description <= 4096, "Description must be 4096 characters or less")

    self._data.description = description
    return self
end

function Embed.SetUrl(self: Embed, url: string): Embed
    assert(type(url) == "string", "Expected url to be a string")

    self._data.url = url
    return self
end

function Embed.SetTimestamp(self: Embed, timestamp: string?): Embed
    if timestamp then
        assert(type(timestamp) == "string", "Expected timestamp to be a string")
        self._data.timestamp = timestamp
    else
        -- Use current time in ISO format
        self._data.timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
    end
    return self
end

function Embed.SetColor(self: Embed, color: number): Embed
    assert(type(color) == "number", "Expected color to be a number")
    assert(color >= 0 and color <= 0xFFFFFF, "Color must be between 0 and 16777215")

    self._data.color = color
    return self
end

function Embed.SetColorHex(self: Embed, hex: string): Embed
    assert(type(hex) == "string", "Expected hex to be a string")

    -- Remove # prefix if present
    if hex:sub(1, 1) == "#" then
        hex = hex:sub(2)
    end

    local color = tonumber(hex, 16)
    assert(color, `Invalid hex color "{hex}"`)

    self._data.color = color
    return self
end

function Embed.SetFooter(self: Embed, text: string, iconUrl: string?): Embed
    assert(type(text) == "string", "Expected text to be a string")
    assert(#text <= 2048, "Footer text must be 2048 characters or less")

    self._data.footer = {
        text = text,
        icon_url = iconUrl,
    }
    return self
end

function Embed.SetImage(self: Embed, url: string): Embed
    assert(type(url) == "string", "Expected url to be a string")

    self._data.image = { url = url }
    return self
end

function Embed.SetThumbnail(self: Embed, url: string): Embed
    assert(type(url) == "string", "Expected url to be a string")

    self._data.thumbnail = { url = url }
    return self
end

function Embed.SetAuthor(self: Embed, name: string, options: { url: string?, icon_url: string? }?): Embed
    assert(type(name) == "string", "Expected name to be a string")
    assert(#name <= 256, "Author name must be 256 characters or less")

    self._data.author = {
        name = name,
        url = options and options.url,
        icon_url = options and options.icon_url,
    }
    return self
end

function Embed.AddField(self: Embed, name: string, value: string, inline: boolean?): Embed
    assert(type(name) == "string", "Expected name to be a string")
    assert(type(value) == "string", "Expected value to be a string")
    assert(#name <= 256, "Field name must be 256 characters or less")
    assert(#value <= 1024, "Field value must be 1024 characters or less")

    local embedFields = self._data.fields
    if not embedFields then
        embedFields = {}
        self._data.fields = embedFields
    end

    assert(#embedFields < 25, "Embeds can have at most 25 fields")

    table.insert(embedFields, {
        name = name,
        value = value,
        inline = inline or false,
    })

    return self
end

function Embed.SetFields(self: Embed, fields: { { name: string, value: string, inline: boolean? } }): Embed
    assert(type(fields) == "table", "Expected fields to be a table")
    assert(#fields <= 25, "Embeds can have at most 25 fields")

    local embedFields: { Types.APIEmbedField } = {}
    self._data.fields = embedFields
    for _, field in fields do
        assert(type(field.name) == "string", "Expected field.name to be a string")
        assert(type(field.value) == "string", "Expected field.value to be a string")
        assert(#field.name <= 256, "Field name must be 256 characters or less")
        assert(#field.value <= 1024, "Field value must be 1024 characters or less")

        table.insert(embedFields, {
            name = field.name,
            value = field.value,
            inline = field.inline or false,
        })
    end

    return self
end

function Embed.ClearFields(self: Embed): Embed
    self._data.fields = {}
    return self
end

function Embed.ToJSON(self: Embed): Types.APIEmbed
    return self._data
end

function Embed.GetLength(self: Embed): number
    local length = 0

    if self._data.title then
        length += #self._data.title
    end
    if self._data.description then
        length += #self._data.description
    end
    if self._data.footer and self._data.footer.text then
        length += #self._data.footer.text
    end
    if self._data.author and self._data.author.name then
        length += #self._data.author.name
    end
    if self._data.fields then
        for _, field in self._data.fields do
            length += #field.name + #field.value
        end
    end

    return length
end

function Embed.__tostring(self: Embed): string
    return `Embed({self._data.title or "untitled"})`
end

return Embed
