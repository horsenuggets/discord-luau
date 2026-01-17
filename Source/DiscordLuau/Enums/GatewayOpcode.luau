--[[

GatewayOpcode

Discord Gateway opcodes for WebSocket communication. These opcodes indicate the type of
payload being sent or received through the gateway connection.

--]]

local GatewayOpcode = table.freeze({
    -- Receive: An event was dispatched
    Dispatch = 0,
    -- Send/Receive: Fired periodically to keep connection alive
    Heartbeat = 1,
    -- Send: Starts a new session during initial handshake
    Identify = 2,
    -- Send: Update the client's presence
    PresenceUpdate = 3,
    -- Send: Used to join/leave or move between voice channels
    VoiceStateUpdate = 4,
    -- Send: Resume a previous session that was disconnected
    Resume = 6,
    -- Receive: You should attempt to reconnect and resume immediately
    Reconnect = 7,
    -- Send: Request information about offline guild members in a large guild
    RequestGuildMembers = 8,
    -- Receive: The session has been invalidated
    InvalidSession = 9,
    -- Receive: Sent immediately after connecting, contains heartbeat_interval
    Hello = 10,
    -- Receive: Sent in response to receiving a heartbeat to acknowledge receipt
    HeartbeatAck = 11,
    -- Send: Request information about soundboard sounds in a set of guilds
    RequestSoundboardSounds = 31,
})

return GatewayOpcode
