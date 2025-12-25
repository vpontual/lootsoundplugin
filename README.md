# LootSoundPlugin

LootSoundPlugin is a World of Warcraft addon that enhances your looting experience by playing custom sounds when you loot items, interact with vendors, or engage in trades.

## Features

- Plays a sound when you open a loot window
- Plays random vendor sounds when interacting with merchants
- Plays a sound when selling items to vendors
- Plays a sound when initiating a trade
- Customizable volume control
- Option to choose between different loot sounds

## Installation

1. Download the latest version of the addon
2. Extract the contents to your `World of Warcraft\_retail_\Interface\AddOns` directory
3. Ensure the folder is named `lootsoundplugin`
4. Restart World of Warcraft or reload your UI

## Usage

The addon works automatically once installed. It will play sounds when you:

- Open a loot window
- Interact with a vendor
- Sell items to a vendor
- Initiate a trade with another player

### Settings Panel

Access all settings via the in-game interface:

1. Press ESC
2. Go to Interface > AddOns > LootSound
3. Configure all settings with a user-friendly UI:
   - Enable/disable the addon
   - Adjust volume (0-100%)
   - Choose sound channel (Master or SFX)
   - Select loot sound (Treasure or Wow)
   - Toggle individual sound types (loot, vendor, trade)
   - Enable debug mode
   - Test all sounds

### Slash Commands

You can also customize the addon using slash commands:

- Get help: `/lootsound help`
- Open settings panel: `/lootsound config`
- Set the volume: `/lootsound volume <0.0 to 1.0>`
- Set the sound channel: `/lootsound channel <master|sfx>`
- Set the loot sound: `/lootsound sound <wow|treasure>`
- Enable/disable addon: `/lootsound toggle`
- Toggle sound types: `/lootsound loot`, `/lootsound vendor`, `/lootsound trade`
- Test sounds: `/lootsound test`
- Show current settings: `/lootsound status`
- Toggle debug mode: `/lootsound debug`
- Reset to defaults: `/lootsound reset`

Examples:

```
/lootsound config
/lootsound volume 0.5
/lootsound sound wow
/lootsound channel sfx
/lootsound test
/lootsound reset
```

### Default Settings

- Volume: 50% (0.5)
- Channel: Master
- Loot sound: Treasure
- All sound types enabled (loot, vendor, trade)

## Customization

You can customize the sounds used by the addon by replacing the sound files in the `sounds` directory. The addon uses the following sound files:

- `treasure.ogg`: Default loot sound
- `wow.ogg`: Alternative loot sound
- `quitpoking.ogg`: Trade sound
- Various vendor sounds in the `sounds` directory

## Version History

- 1.1: Current version

## Known Issues

- The "junk" sound feature is currently commented out in the code

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License

Copyright (c) 2024 vpontual

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## Credits

Created by veepee

Some game files were sourced from [WOWHEAD](www.wowhead.com)
