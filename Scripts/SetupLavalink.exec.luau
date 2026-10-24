#!/usr/bin/env -S lune run

--[[

SetupLavalink

Downloads and configures Lavalink server for local development and testing.

--]]

local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")

local LAVALINK_VERSION = "4.0.8"
local LAVALINK_DIR = "Dependencies/lavalink"
local JAR_PATH = `{LAVALINK_DIR}/Lavalink.jar`
local CONFIG_PATH = `{LAVALINK_DIR}/application.yml`

local DOWNLOAD_URL = `https://github.com/lavalink-devs/Lavalink/releases/download/{LAVALINK_VERSION}/Lavalink.jar`

local DEFAULT_CONFIG = [[
server:
  port: 2333
  address: 0.0.0.0

lavalink:
  plugins:
    - dependency: "dev.lavalink.youtube:youtube-plugin:1.11.0"
      snapshot: false
  server:
    password: "lifeisroblox"
    sources:
      youtube: true
      bandcamp: true
      soundcloud: true
      twitch: true
      vimeo: true
      http: true
      local: true
    filters:
      volume: true
      equalizer: true
      karaoke: true
      timescale: true
      tremolo: true
      vibrato: true
      distortion: true
      rotation: true
      channelMix: true
      lowPass: true

logging:
  level:
    root: INFO
    lavalink: INFO
]]

local function fileExists(path: string): boolean
    local success, result = pcall(function()
        return fs.isFile(path)
    end)
    return success and result == true
end

local function dirExists(path: string): boolean
    local success, result = pcall(function()
        return fs.isDir(path)
    end)
    return success and result == true
end

local function downloadFile(url: string, path: string): boolean
    print(`Downloading from {url}...`)

    local response = net.request({
        url = url,
        method = "GET",
    })

    if not response.ok then
        print(`Failed to download ({response.statusCode} {response.statusMessage})`)
        return false
    end

    fs.writeFile(path, response.body)
    print(`Downloaded to {path}`)
    return true
end

local function main()
    print("Setting up Lavalink...")

    -- Create directory if needed
    if not dirExists(LAVALINK_DIR) then
        print(`Creating {LAVALINK_DIR}/...`)
        fs.writeDir(LAVALINK_DIR)
    end

    -- Download JAR if not present
    if fileExists(JAR_PATH) then
        print(`Lavalink.jar already exists at {JAR_PATH}`)
    else
        local success = downloadFile(DOWNLOAD_URL, JAR_PATH)
        if not success then
            process.exit(1)
        end
    end

    -- Create config if not present
    if fileExists(CONFIG_PATH) then
        print(`Config already exists at {CONFIG_PATH}`)
    else
        print(`Creating {CONFIG_PATH}...`)
        fs.writeFile(CONFIG_PATH, DEFAULT_CONFIG)
    end

    print("")
    print("Lavalink setup complete!")
    print("")
    print("[To start Lavalink]")
    print(`  cd {LAVALINK_DIR} && java -jar Lavalink.jar`)
    print("")
    print('Default password is "lifeisroblox"')
    print("Edit application.yml to change settings.")
end

main()
