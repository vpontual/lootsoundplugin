# LootSound Addon v1.3 - Release Notes

## Major Updates
1. Complete Code Restructure
   - Improved organization with separate modules for configuration, state management, and utilities
   - Better error handling and validation throughout
   - More efficient event handling
   - Improved performance and reliability

2. New Individual Sound Controls
   - Separate toggles for each sound type:
     * Loot sounds
     * Vendor sounds
     * Trade sounds
   - Main addon toggle remains as master control
   - Each sound type can be enabled/disabled independently

3. Enhanced User Interface
   - Color-coded status messages
   - Improved error reporting
   - Better feedback for all commands
   - Comprehensive status display

## New Commands
- `/lootsound loot` - Toggle loot sounds
- `/lootsound vendor` - Toggle vendor sounds
- `/lootsound trade` - Toggle trade sounds
- `/lootsound status` - Show all current settings
- `/lootsound help` - Display all available commands

## Existing Features
- Volume control: `/lootsound volume <0.0 to 1.0>`
- Sound selection: `/lootsound sound <wow|treasure>`
- Master toggle: `/lootsound toggle`

## Technical Improvements
- Better input validation for all commands
- Protected sound playback to prevent errors
- Improved sound file validation
- Better state management
- More efficient event handling

## Installation
1. Copy the addon folder to your WoW Interface/AddOns directory
2. Restart World of Warcraft if it's running
3. Make sure the addon is enabled in your addon list

## Usage Tips
- Use `/lootsound status` to see current settings
- Individual sound toggles let you customize exactly what you want to hear
- Volume can be adjusted independently of other game sounds
- Trade sounds require both players to have the addon installed

## Known Limitations
- Trade sounds only work when both players have the addon
- Sound files must be .ogg format
- Volume setting is separate from WoW's master volume

## Compatibility
- Tested with current retail version of World of Warcraft
- Should work with most UI addons
- No known conflicts with other addons

## Feedback and Support
If you encounter any issues or have suggestions, please report them at [your preferred contact method/repository].