--[[

Signal

A simple event system for subscribing to and firing events. Supports one-time connections
and immediate fire callbacks.

--]]

local Connection = require("./Connection")
local task = require("@lune/task")

local Signal = {}
Signal.__index = Signal

export type Signal<T...> = typeof(setmetatable(
    {} :: {
        _connections: { Connection.Connection },
        _immediateFire: ((Connection.Connection) -> ())?,
    },
    Signal
))

function Signal.new<T...>(): Signal<T...>
    local self = setmetatable({}, Signal)

    self._connections = {}

    return self
end

function Signal.Fire<T...>(self: Signal<T...>, ...: T...)
    for _, connection in self._connections do
        task.spawn(connection._func, ...)

        if connection._once then
            connection:Disconnect()
        end
    end
end

function Signal.Connect<T...>(self: Signal<T...>, func: (...any) -> ()): Connection.Connection
    assert(type(func) == "function", "Expected func to be a function")

    local connection = Connection.new(self, func)

    table.insert(self._connections, connection)

    if self._immediateFire then
        task.spawn(self._immediateFire, connection)
    end

    return connection
end

function Signal.Once<T...>(self: Signal<T...>, func: (...any) -> ()): Connection.Connection
    assert(type(func) == "function", "Expected func to be a function")

    local connection = Connection.new(self, func)
    connection._once = true

    table.insert(self._connections, connection)

    if self._immediateFire then
        task.spawn(self._immediateFire, connection)
    end

    return connection
end

function Signal.SetImmediateFire<T...>(self: Signal<T...>, func: (Connection.Connection) -> ())
    assert(type(func) == "function", "Expected func to be a function")

    self._immediateFire = func
end

function Signal.Wait<T...>(self: Signal<T...>): T...
    local thread = coroutine.running()
    local connection: Connection.Connection

    connection = self:Once(function(...)
        task.spawn(thread, ...)
    end)

    return coroutine.yield()
end

function Signal.Destroy<T...>(self: Signal<T...>)
    for _, connection in self._connections do
        connection:Disconnect()
    end

    table.clear(self._connections)
    self._immediateFire = nil
end

return Signal
