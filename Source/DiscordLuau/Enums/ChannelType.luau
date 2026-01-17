--[[

ChannelType

Discord channel types that identify the kind of channel. Different channel types have
different capabilities and behaviors.

--]]

local ChannelType = table.freeze({
    -- A text channel within a guild
    GuildText = 0,
    -- A direct message between users
    DM = 1,
    -- A voice channel within a guild
    GuildVoice = 2,
    -- A direct message between multiple users
    GroupDM = 3,
    -- An organizational category that contains up to 50 channels
    GuildCategory = 4,
    -- A channel that users can follow and crosspost into their own guild
    GuildAnnouncement = 5,
    -- A temporary sub-channel within a Guild Announcement channel
    AnnouncementThread = 10,
    -- A temporary sub-channel within a Guild Text or Forum channel
    PublicThread = 11,
    -- A temporary sub-channel viewable only by invited users
    PrivateThread = 12,
    -- A voice channel for hosting events with an audience
    GuildStageVoice = 13,
    -- A channel in a Student Hub listing servers
    GuildDirectory = 14,
    -- A channel that can only contain threads
    GuildForum = 15,
    -- A channel similar to forum channels but for media
    GuildMedia = 16,
})

return ChannelType
