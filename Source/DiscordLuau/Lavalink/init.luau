--[[

Lavalink

Re-exports the Lavalink class and its type so callers can require the folder directly.

--]]

const Lavalink = require("@self/Lavalink")

export type Lavalink = Lavalink.Lavalink

return Lavalink
