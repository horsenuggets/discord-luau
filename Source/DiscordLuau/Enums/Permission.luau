--[[

Permission

Discord permission flags that control what actions users can perform. These are bitwise
flags that can be combined to create permission sets.

--]]

local Permission = table.freeze({
    -- Allows creation of instant invites
    CreateInstantInvite = bit32.lshift(1, 0),
    -- Allows kicking members
    KickMembers = bit32.lshift(1, 1),
    -- Allows banning members
    BanMembers = bit32.lshift(1, 2),
    -- Allows all permissions and bypasses channel permission overwrites
    Administrator = bit32.lshift(1, 3),
    -- Allows management and editing of channels
    ManageChannels = bit32.lshift(1, 4),
    -- Allows management and editing of the guild
    ManageGuild = bit32.lshift(1, 5),
    -- Allows for the addition of reactions to messages
    AddReactions = bit32.lshift(1, 6),
    -- Allows for viewing of audit logs
    ViewAuditLog = bit32.lshift(1, 7),
    -- Allows for using priority speaker in a voice channel
    PrioritySpeaker = bit32.lshift(1, 8),
    -- Allows the user to go live
    Stream = bit32.lshift(1, 9),
    -- Allows guild members to view a channel
    ViewChannel = bit32.lshift(1, 10),
    -- Allows for sending messages in a channel
    SendMessages = bit32.lshift(1, 11),
    -- Allows for sending of /tts messages
    SendTTSMessages = bit32.lshift(1, 12),
    -- Allows for deletion of other users messages
    ManageMessages = bit32.lshift(1, 13),
    -- Links sent by users with this permission will be auto-embedded
    EmbedLinks = bit32.lshift(1, 14),
    -- Allows for uploading images and files
    AttachFiles = bit32.lshift(1, 15),
    -- Allows for reading of message history
    ReadMessageHistory = bit32.lshift(1, 16),
    -- Allows for using the @everyone tag to notify all users
    MentionEveryone = bit32.lshift(1, 17),
    -- Allows the usage of custom emojis from other servers
    UseExternalEmojis = bit32.lshift(1, 18),
    -- Allows for viewing guild insights
    ViewGuildInsights = bit32.lshift(1, 19),
    -- Allows for joining of a voice channel
    Connect = bit32.lshift(1, 20),
    -- Allows for speaking in a voice channel
    Speak = bit32.lshift(1, 21),
    -- Allows for muting members in a voice channel
    MuteMembers = bit32.lshift(1, 22),
    -- Allows for deafening of members in a voice channel
    DeafenMembers = bit32.lshift(1, 23),
    -- Allows for moving of members between voice channels
    MoveMembers = bit32.lshift(1, 24),
    -- Allows for using voice-activity-detection in a voice channel
    UseVAD = bit32.lshift(1, 25),
    -- Allows for modification of own nickname
    ChangeNickname = bit32.lshift(1, 26),
    -- Allows for modification of other users nicknames
    ManageNicknames = bit32.lshift(1, 27),
    -- Allows management and editing of roles
    ManageRoles = bit32.lshift(1, 28),
    -- Allows management and editing of webhooks
    ManageWebhooks = bit32.lshift(1, 29),
    -- Allows management and editing of guild expressions
    ManageGuildExpressions = bit32.lshift(1, 30),
    -- Allows members to use application commands
    UseApplicationCommands = bit32.lshift(1, 31),
    -- Allows for requesting to speak in stage channels
    RequestToSpeak = 0x100000000,
    -- Allows for creating, editing, and deleting scheduled events
    ManageEvents = 0x200000000,
    -- Allows for deleting and archiving threads
    ManageThreads = 0x400000000,
    -- Allows for creating public and announcement threads
    CreatePublicThreads = 0x800000000,
    -- Allows for creating private threads
    CreatePrivateThreads = 0x1000000000,
    -- Allows the usage of custom stickers from other servers
    UseExternalStickers = 0x2000000000,
    -- Allows for sending messages in threads
    SendMessagesInThreads = 0x4000000000,
    -- Allows for using Activities in a voice channel
    UseEmbeddedActivities = 0x8000000000,
    -- Allows for timing out users
    ModerateMembers = 0x10000000000,
    -- Allows for viewing role subscription insights
    ViewCreatorMonetizationAnalytics = 0x20000000000,
    -- Allows for using soundboard in a voice channel
    UseSoundboard = 0x40000000000,
    -- Allows for creating emojis, stickers, and soundboard sounds
    CreateGuildExpressions = 0x80000000000,
    -- Allows for creating scheduled events
    CreateEvents = 0x100000000000,
    -- Allows the usage of custom soundboard sounds from other servers
    UseExternalSounds = 0x200000000000,
    -- Allows sending voice messages
    SendVoiceMessages = 0x400000000000,
    -- Allows sending polls
    SendPolls = 0x2000000000000,
    -- Allows user-installed apps to send public responses
    UseExternalApps = 0x4000000000000,
})

return Permission
