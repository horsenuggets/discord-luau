# Changelog

## 0.1.8
- Added version-match CI check to ensure README version stays in sync
- Fixed README version to match VERSION file

## 0.1.7
- Added Moonwave function documentation to Client class methods
- Fixed API documentation extraction by specifying source directory

## 0.1.6
- Fixed wally package requiring by restructuring init.luau files
- Moved implementation from init.luau to regular .luau files for correct path resolution
- Package now works correctly when installed as a wally dependency

## 0.1.5
- Fixed docs workflow by using correct build command

## 0.1.4
- Added Moonwave documentation configuration
- Added GitHub Actions workflow for deploying docs to GitHub Pages
- Added doc comments to core structures for API documentation

## 0.1.3
- Updated wally to 0.3.2-horse.4.1 with dev dependency isolation
- Removed unnecessary [place] config from wally.toml
- Added workflow_dispatch trigger to release-checks workflow

## 0.1.2
- Replaced built-in LoadEnv with dotenv-luau package

## 0.1.1
- Added Lavalink setup script for easy local development
- Added LoadFile method for loading local audio files
- Added separate tests for mp3 and wav audio playback
- Fixed WebSocket message handling for Lune compatibility
- Removed TestBot script (now covered by unit tests)

## 0.1.0
- Added VoiceState structure for tracking voice channel connections
- Added Lavalink audio integration module for music playback
- Added moderation methods to Member (Kick, Ban, Timeout, SetNickname) and Guild
- Added channel permission overwrite REST endpoints
- Added mock client infrastructure for unit testing
- Added comprehensive tests for Discord structures and REST API
- Added voice integration tests for joining/leaving voice channels
- Added Git LFS tracking for audio test files
- Fixed cyclic dependency between Channel and Message
- Fixed static analysis warnings for unused imports and variables
- Fixed Connected property on Connection class
- Improved test runner configuration

## 0.0.1
- Initial release
