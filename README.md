# SubnauticaOxygenAlerts

World of Warcraft addon that plays oxygen warning sounds while underwater.

## Features
- Plays custom audio at oxygen thresholds (50%, 25%, 10%, 1%).
- At the halfway mark it picks the right line: the "50%" sound when half the
  breath bar is still more than 30 seconds (extended breath from items or the
  Undead racial), otherwise the "30 seconds" sound.
- Uses the BREATH mirror timer and updates even if the timer UI is hidden.
- Native options panel under Game Menu > Options > AddOns, with buttons to test
  each alert sound.

## Installation
1) Copy the `SubnauticaOxygenAlerts` folder into your WoW AddOns directory,
   e.g. `World of Warcraft/<flavour>/Interface/AddOns/`:
   - WoW Forever: `_forever_`
   - Classic Era: `_classic_era_`
   - TBC Anniversary: `_anniversary_`
   - Mists of Pandaria Classic: `_classic_`
2) Ensure `SubnauticaOxygenAlerts` is enabled on the character select AddOns list.
3) Reload the UI (`/reload ui`) if the game is already running.

## Usage
- Dive underwater and the addon will play sounds at the configured thresholds.
- Sounds are stored in `src/` and are played on the `Dialog` channel by default.
- Options: Game Menu > Options > AddOns > Subnautica Oxygen Alerts, or `/soa`.

### Slash Commands
- `/soa` - Open the options panel.

## Configuration
The options panel holds alert volume, sound channel and the two sound test
buttons. The addon never writes to chat.
Edit `SubnauticaOxygenAlerts.lua` and adjust `PERCENT_THRESHOLDS` if you want different
timings or sound files.

## Development Notes
- The addon listens to `MIRROR_TIMER_START/STOP/PAUSE` for the `BREATH` timer.
- Remaining oxygen is updated every 0.1s. Mirror timers report milliseconds;
  `state.unitsPerSecond` is derived from the reported maximum so a client that
  reports seconds instead does not shift the thresholds.
- `MIRRORTIMER_NUMTIMERS` is no longer required - clients without the global
  fall back to scanning three mirror timers.
- The options panel registers through `Settings.RegisterCanvasLayoutCategory`
  where available and falls back to `InterfaceOptions_AddCategory`.

## Supported Clients
Interface versions 16001 (WoW Forever), 11508 (Classic Era), 20505 (TBC Anniversary),
50503 (Mists of Pandaria Classic).

## Credits
Author: Nightbert
Subnautica sound assets are owned by Unknown Worlds Entertainment.
