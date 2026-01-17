--[[

Connection

Represents a connection to a Signal. Can be disconnected to stop receiving events.

--]]

local task = require("@lune/task")

local Connection = {}
Connection.__index = Connection

export type Connection = typeof(setmetatable(
    {} :: {
        _func: (...any) -> (),
        _once: boolean?,
        _signal: any,
    },
    Connection
))

function Connection.new<T>(signal: any, func: (...T) -> ()): Connection
    assert(type(signal) == "table", "Expected signal to be a table")
    assert(type(func) == "function", "Expected func to be a function")

    local self = setmetatable({}, Connection)

    self._func = func
    self._signal = signal

    return self
end

function Connection.Disconnect(self: Connection)
    if not self._signal then
        return
    end

    local connections = self._signal._connections
    for i, connection in connections do
        if connection == self then
            table.remove(connections, i)
            break
        end
    end

    self._signal = nil
    self._func = nil :: any
    self._once = nil
end

function Connection.Fire(self: Connection, ...: any)
    task.spawn(self._func, ...)

    if self._once then
        self:Disconnect()
    end
end

return Connection
