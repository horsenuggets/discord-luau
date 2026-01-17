--[[

GatewayIntent

Discord Gateway intents that control which events the bot receives. Some intents are
privileged and require approval from Discord for verified bots.

--]]

local GatewayIntent = table.freeze({
    -- Guild events (create, update, delete, role events, etc.)
    Guilds = bit32.lshift(1, 0),
    -- Guild member events (add, update, remove) - PRIVILEGED
    GuildMembers = bit32.lshift(1, 1),
    -- Guild moderation events (ban, unban, audit log)
    GuildModeration = bit32.lshift(1, 2),
    -- Guild emoji and sticker events
    GuildEmojisAndStickers = bit32.lshift(1, 3),
    -- Guild integration events
    GuildIntegrations = bit32.lshift(1, 4),
    -- Guild webhook events
    GuildWebhooks = bit32.lshift(1, 5),
    -- Guild invite events
    GuildInvites = bit32.lshift(1, 6),
    -- Guild voice state events
    GuildVoiceStates = bit32.lshift(1, 7),
    -- Guild presence events - PRIVILEGED
    GuildPresences = bit32.lshift(1, 8),
    -- Guild message events (create, update, delete)
    GuildMessages = bit32.lshift(1, 9),
    -- Guild message reaction events
    GuildMessageReactions = bit32.lshift(1, 10),
    -- Guild message typing events
    GuildMessageTyping = bit32.lshift(1, 11),
    -- Direct message events
    DirectMessages = bit32.lshift(1, 12),
    -- Direct message reaction events
    DirectMessageReactions = bit32.lshift(1, 13),
    -- Direct message typing events
    DirectMessageTyping = bit32.lshift(1, 14),
    -- Message content access - PRIVILEGED
    MessageContent = bit32.lshift(1, 15),
    -- Guild scheduled event events
    GuildScheduledEvents = bit32.lshift(1, 16),
    -- Auto moderation configuration events
    AutoModerationConfiguration = bit32.lshift(1, 20),
    -- Auto moderation execution events
    AutoModerationExecution = bit32.lshift(1, 21),
    -- Guild message poll events
    GuildMessagePolls = bit32.lshift(1, 24),
    -- Direct message poll events
    DirectMessagePolls = bit32.lshift(1, 25),
})

return GatewayIntent
