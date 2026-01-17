# discord-luau

A comprehensive Discord API library for Luau, inspired by discord.js.

## Installation

Add to your `wally.toml`:

```toml
[dependencies]
DiscordLuau = "horsenuggets/discord-luau@0.1.0"
```

## Quick Start

```luau
local Discord = require("@packages/discord-luau")
local process = require("@lune/process")

-- Create a client with intents
local client = Discord.Client.new({
    intents = {
        Discord.Intents.Guilds,
        Discord.Intents.GuildMessages,
        Discord.Intents.MessageContent,
    },
})

-- Listen for ready event
client:On("ready", function()
    print(`Logged in as {client.User:GetTag()}!`)
end)

-- Listen for messages
client:On("messageCreate", function(message)
    if message.Content == "!ping" then
        message:Reply("Pong!")
    end
end)

-- Login with your bot token
client:Login(process.env.DISCORD_BOT_TOKEN)
```

## Slash Commands

```luau
local Discord = require("@packages/discord-luau")
local process = require("@lune/process")

local client = Discord.Client.new({
    intents = { Discord.Intents.Guilds },
})

-- Register commands when ready
client:On("ready", function()
    -- Create a slash command using the builder
    local pingCommand = Discord.SlashCommandBuilder.new()
        :SetName("ping")
        :SetDescription("Check bot latency")

    local echoCommand = Discord.SlashCommandBuilder.new()
        :SetName("echo")
        :SetDescription("Echo a message")
        :AddStringOption("message", "The message to echo", { required = true })

    -- Register commands globally
    client:SetGlobalCommands({ pingCommand, echoCommand })
    print("Commands registered!")
end)

-- Handle interactions
client:On("interactionCreate", function(interaction)
    if not interaction:IsCommand() then
        return
    end

    if interaction.CommandName == "ping" then
        interaction:Reply("Pong!")
    elseif interaction.CommandName == "echo" then
        local message = interaction:GetOption("message")
        interaction:Reply(message)
    end
end)

client:Login(process.env.DISCORD_BOT_TOKEN)
```

## Embeds

```luau
local Discord = require("@packages/discord-luau")

local embed = Discord.Embed.new()
    :SetTitle("Hello World")
    :SetDescription("This is an embed!")
    :SetColor(0x5865F2)
    :AddField("Field 1", "Value 1", true)
    :AddField("Field 2", "Value 2", true)
    :SetFooter("Footer text")
    :SetTimestamp()

-- Send embed with a message
message:Reply({ embeds = { embed:ToJSON() } })

-- Or in an interaction
interaction:Reply({ embeds = { embed:ToJSON() } })
```

## Features

- Full Discord Gateway v10 support
- REST API for all Discord endpoints
- Event-driven architecture
- Comprehensive type definitions
- Slash commands and interactions
- Message components (buttons, select menus)
- Reactions and embeds
- Guild, channel, and user management
- Permission handling
- Rate limiting

## Events

The client emits the following events:

- `ready` - Bot is connected and ready
- `messageCreate` - New message received
- `messageUpdate` - Message was edited
- `messageDelete` - Message was deleted
- `interactionCreate` - Slash command or component interaction
- `guildCreate` - Bot joined a guild
- `guildDelete` - Bot left a guild
- `guildMemberAdd` - Member joined a guild
- `guildMemberRemove` - Member left a guild
- `channelCreate` - Channel was created
- `channelUpdate` - Channel was updated
- `channelDelete` - Channel was deleted
- `messageReactionAdd` - Reaction added to a message
- `messageReactionRemove` - Reaction removed from a message
- `typingStart` - User started typing
- `voiceStateUpdate` - Voice state changed
- `presenceUpdate` - Presence changed

## License

MIT
