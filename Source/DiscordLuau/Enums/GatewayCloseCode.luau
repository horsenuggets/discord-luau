--[[

GatewayCloseCode

Discord Gateway close codes that may be received when the WebSocket connection closes.
These codes help identify why the connection was closed and what action to take.

--]]

local GatewayCloseCode = table.freeze({
    -- Unknown error; try reconnecting
    UnknownError = 4000,
    -- Invalid Gateway opcode or payload
    UnknownOpcode = 4001,
    -- Invalid payload sent
    DecodeError = 4002,
    -- Payload sent before identifying
    NotAuthenticated = 4003,
    -- Invalid token provided
    AuthenticationFailed = 4004,
    -- Already authenticated
    AlreadyAuthenticated = 4005,
    -- Invalid sequence number when resuming
    InvalidSeq = 4007,
    -- Rate limited; slow down
    RateLimited = 4008,
    -- Session timed out; reconnect and start new session
    SessionTimedOut = 4009,
    -- Invalid shard
    InvalidShard = 4010,
    -- Sharding required
    ShardingRequired = 4011,
    -- Invalid API version
    InvalidApiVersion = 4012,
    -- Invalid intents
    InvalidIntents = 4013,
    -- Disallowed intents
    DisallowedIntents = 4014,
})

return GatewayCloseCode
