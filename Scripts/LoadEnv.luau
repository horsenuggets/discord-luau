--[[

LoadEnv

Loads environment variables from a .env file into process.env.

--]]

local fs = require("@lune/fs")
local process = require("@lune/process")

local function loadEnv(path: string?)
    local envPath = path or ".env"

    if not fs.isFile(envPath) then
        return false
    end

    local content = fs.readFile(envPath)
    local lines = string.split(content, "\n")

    for _, line in lines do
        -- Skip empty lines and comments
        line = string.match(line, "^%s*(.-)%s*$") -- trim
        if line == "" or string.sub(line, 1, 1) == "#" then
            continue
        end

        -- Parse KEY=value
        local key, value = string.match(line, "^([%w_]+)=(.*)$")
        if key and value then
            -- Remove quotes if present
            value = string.match(value, "^[\"'](.*)[\"']$") or value
            process.env[key] = value
        end
    end

    return true
end

return loadEnv
