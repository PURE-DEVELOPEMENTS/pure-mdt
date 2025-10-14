# PURE-MDT

A REDM resource for managing police MDT (Mobile Data Terminal) operations. This script provides client and server functionality for police roleplay servers, including database integration and configuration options.

## Features
- Police MDT system for REDM
- Client and server Lua scripts
- Configurable via `config.lua`
- SQL installation script for database setup

## Installation
1. Clone or download this repository into your REDM resources folder.
2. Import the `installation.sql` file into your database to set up required tables.
3. Configure settings in `config.lua` as needed.
4. Add `ensure pure-mdt` to your server's `server.cfg`.

## File Structure
- `config.lua` - Configuration options
- `fxmanifest.lua` - Resource manifest
- `installation.sql` - SQL setup script
- `client/main.lua` - Client-side logic
- `server/main.lua` - Server-side logic

## Usage
- Start your REDM server and ensure the resource is running.
- Use MDT features in-game as configured.
- Command to open mdt is - /SMDT (Can be changed in config) and to check fines is /fine (can be changed in config)

## Support
For issues or feature requests, open an issue on the repository or contact PURE-DEVELOPEMENTS.
