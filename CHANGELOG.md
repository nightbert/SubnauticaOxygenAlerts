# Changelog

## [1.2.0]
- Halfway alert now depends on the actual breath length: plays `oxygen_50.ogg`
  ("50% left") when half the bar is more than 30 seconds, otherwise
  `oxygen_30s.ogg` ("30 seconds left"). Extended breath (items, Undead racial)
  no longer announces the wrong thing.
- Renamed the old `oxygen_50.ogg` to `oxygen_30s.ogg` (it is the 30 seconds
  line) and added the real 50% line as `oxygen_50.ogg`.
- Settings now live in a native panel under Game Menu > Options > AddOns
  (Settings API on modern clients, Interface Options on older ones) instead of
  a standalone window. `/soa` opens it.
- Added sound test buttons for both halfway alerts to the options panel, and
  dropped the `/soa test` and `/soa test30` commands in favour of them. `/soa`
  now only opens the options panel.
- Default alert channel changed from `SFX` to `Dialog` (existing saved settings
  keep their channel).
- Added an addon icon (`spell_shadow_demonbreath`, the water breathing icon).
- Removed all chat output.
- Added support for the WoW Forever client (interface 16001), with a fallback
  for the mirror timer count on clients that no longer expose
  `MIRRORTIMER_NUMTIMERS`.

## [1.1.0]
- Version bump: addon version set to 1.1.0.
- Client support: released for Interface versions Classic (11508), Classic TBC Anniversary (20505), Mists of Pandaria Classic (50503).
- Slash command update: use `/soa config` as the primary command (alias: `/soa settings`).
