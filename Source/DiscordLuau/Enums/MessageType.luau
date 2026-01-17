--[[

MessageType

Discord message types that indicate how the message was created. Most messages are Default
type, but system messages have special types.

--]]

local MessageType = table.freeze({
    -- A default message
    Default = 0,
    -- A recipient was added to a group DM
    RecipientAdd = 1,
    -- A recipient was removed from a group DM
    RecipientRemove = 2,
    -- A call was started
    Call = 3,
    -- A channel name was changed
    ChannelNameChange = 4,
    -- A channel icon was changed
    ChannelIconChange = 5,
    -- A message was pinned
    ChannelPinnedMessage = 6,
    -- A user joined the guild
    UserJoin = 7,
    -- A user boosted the guild
    GuildBoost = 8,
    -- Guild reached boost tier 1
    GuildBoostTier1 = 9,
    -- Guild reached boost tier 2
    GuildBoostTier2 = 10,
    -- Guild reached boost tier 3
    GuildBoostTier3 = 11,
    -- A channel was followed
    ChannelFollowAdd = 12,
    -- Guild was disqualified from discovery
    GuildDiscoveryDisqualified = 14,
    -- Guild was requalified for discovery
    GuildDiscoveryRequalified = 15,
    -- Guild discovery grace period initial warning
    GuildDiscoveryGracePeriodInitialWarning = 16,
    -- Guild discovery grace period final warning
    GuildDiscoveryGracePeriodFinalWarning = 17,
    -- A thread was created
    ThreadCreated = 18,
    -- A reply to another message
    Reply = 19,
    -- A slash command was used
    ChatInputCommand = 20,
    -- A thread starter message
    ThreadStarterMessage = 21,
    -- A guild invite reminder
    GuildInviteReminder = 22,
    -- A context menu command was used
    ContextMenuCommand = 23,
    -- An auto moderation action was taken
    AutoModerationAction = 24,
    -- A role subscription was purchased
    RoleSubscriptionPurchase = 25,
    -- An interaction premium upsell
    InteractionPremiumUpsell = 26,
    -- A stage instance started
    StageStart = 27,
    -- A stage instance ended
    StageEnd = 28,
    -- A user became a stage speaker
    StageSpeaker = 29,
    -- A user raised their hand in stage
    StageRaiseHand = 30,
    -- A stage topic was changed
    StageTopic = 31,
    -- A guild application premium subscription
    GuildApplicationPremiumSubscription = 32,
    -- Guild incident alert mode was enabled
    GuildIncidentAlertModeEnabled = 36,
    -- Guild incident alert mode was disabled
    GuildIncidentAlertModeDisabled = 37,
    -- A guild incident raid was reported
    GuildIncidentReportRaid = 38,
    -- A guild incident false alarm was reported
    GuildIncidentReportFalseAlarm = 39,
    -- A purchase notification
    PurchaseNotification = 44,
    -- A poll result
    PollResult = 46,
})

return MessageType
