# SubnauticaOxygenAlerts

World of Warcraft addon that plays oxygen warning sounds while underwater.

## Features
- Plays custom audio at oxygen thresholds (50%, 25%, 10%, 1%).
- Uses the BREATH mirror timer and updates even if the timer UI is hidden.
- Simple slash command for testing.

## Installation
1) Copy the `Subnautica` folder into your WoW AddOns directory:
   - Retail: `World of Warcraft/_retail_/Interface/AddOns/`
   - Classic: `World of Warcraft/_classic_/Interface/AddOns/`
2) Ensure `Subnautica` is enabled on the character select AddOns list.
3) Reload the UI (`/reload`) if the game is already running.

## Usage
- Dive underwater and the addon will play sounds at the configured thresholds.
- Sounds are stored in `src/` and are played on the `SFX` channel.

### Slash Commands
- `/subnautica test` - Play a test sound.

## Configuration
Edit `Subnautica.lua` and adjust `PERCENT_THRESHOLDS` if you want different timings
or sound files.

## Development Notes
- The addon listens to `MIRROR_TIMER_START/STOP/PAUSE` for the `BREATH` timer.
- Remaining oxygen is tracked in milliseconds and updated every 0.1s.

## Credits
Author: Nightbert
Subnautica sound assets are owned by Unknown Worlds Entertainment.
