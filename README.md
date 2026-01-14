# SubnauticaOxygenAlerts

World of Warcraft addon that plays oxygen warning sounds while underwater.

## Features
- Plays custom audio at oxygen thresholds (50%, 25%, 10%, 1%).
- Uses the BREATH mirror timer and updates even if the timer UI is hidden.
- Slash commands for testing and configuration.

## Installation
1) Copy the `SubnauticaOxygenAlerts` folder into your WoW AddOns directory:
   - Retail: `World of Warcraft/_retail_/Interface/AddOns/`
   - Classic: `World of Warcraft/_classic_/Interface/AddOns/`
2) Ensure `Subnautica Oxygen Alerts` is enabled on the character select AddOns list.
3) Reload the UI (`/reload`) if the game is already running.

## Usage
- Dive underwater and the addon will play sounds at the configured thresholds.
- Sounds are stored in `src/` and are played on the `SFX` channel.
- Open the config with `/soa config` to change volume and sound channel.

### Slash Commands
- `/soa test` - Play a test sound.
- `/soa config` (or `/soa settings`) - Open the configuration window.

## Configuration
Use `/soa config` to adjust volume and sound channel.
Edit `SubnauticaOxygenAlerts.lua` and adjust `PERCENT_THRESHOLDS` if you want different
timings or sound files.

## Development Notes
- The addon listens to `MIRROR_TIMER_START/STOP/PAUSE` for the `BREATH` timer.
- Remaining oxygen is tracked in milliseconds and updated every 0.1s.

## Credits
Author: Nightbert
Subnautica sound assets are owned by Unknown Worlds Entertainment.

Addon on Curseforge: https://www.curseforge.com/wow/addons/subnautica-oxygen-alerts
