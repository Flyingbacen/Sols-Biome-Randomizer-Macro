# Biome Randomizer / Strange Controller Sol's RNG Macro

AutoHotkey script for automatic use of the Biome Randomizer and Strange Controller in Sol's RNG. Designed to run while the game is in fullscreen mode.

## Features

- Automatically uses Biome Randomizer and Strange Controller on cooldown
- Sends periodic AFK actions to keep the game active
    - both have customizable intervals in `settings.ini`
- Uses Windows OCR to locate inventory UI elements
    - Might have support for sending a webhook if detects Eden—untested

## Requirements

- AutoHotkey v2 (if using AHK version)
- Roblox running in fullscreen
- `settings.ini`, `CaptureScreen.ahk`, `CreateFormData.ahk` located next to the script if using AHK version

## Installation

### If using AHK version
1. Place `Biome randomizer.ahk`, `settings.ini`, `CaptureScreen.ahk`, `OCR.ahk`, and `CreateFormData.ahk` in the same folder.
2. Launch `Biome randomizer.ahk` with AutoHotkey v2.

### If using EXE version
1. Download the EXE from the [realeases page](https://github.com/Flyingbacen/Sols-Biome-Randomizer-Macro/releases/latest)
2. Place `settings.ini` in the same folder
3. Lauch `Biome randomizer.exe`

## Usage

- The script expects the Roblox window to be fullscreen. <br/> Coordinates were intended for fullscreen 1080p at 100% scale
- Configure inventory and crafting coordinates in `settings.ini` if needed 
    - Unless on different scaling settings, this shouldn't be necessary
- If you have other windows that may contain the name roblox:
    - Press the button `CTRL+Click = active window`
    - hold <kbd>CTRL</kbd> and click on the window you want it to target. It will automatically set it as the target
- Press Toggle Active
- If you need to use a controller early, press the force button. The timer will automatically accomdate for the earlier use.

## Configuration

Edit `settings.ini` to adjust:

- Inventory coordinates
- Crafting and crafting menu positions
- Cooldowns for Biome Randomizer and Strange Controller
- AFK interval
- Discord webhook settings

## Notes

- Fullscreen mode is recommended for reliable coordinate-based clicks.
- If the script cannot find the target window, set the AFK target manually.
- The script saves settings back to `settings.ini` on exit.