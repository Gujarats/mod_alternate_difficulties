# Alternate Difficulties

An MSU and Legends compatibility mod for readable, roster-based encounter scaling.

## Requirements and load order

- Modern Hooks
- MSU 1.9.0 or later
- Legends

Load this mod after `mod_msu` and `mod_legends`.

## Scaling model

Only brothers eligible for deployment contribute to roster scaling. Reserves, campaign day, player-party strength, equipment price, named-item value, and stored equipment are excluded.

```
countScore = deployedCount / 6.0
levelScore = averageLevel / 6.0
rosterMultiplier = clamp(0.75, 1.40, 0.50 * countScore + 0.50 * levelScore)
finalEncounterMultiplier = rosterMultiplier * Custom Enemy Difficulty
```

Six deployable level-6 brothers are the roster baseline of `1.00`.

## Custom Enemy Difficulty

The **Custom Enemy Difficulty** setting is available in Mod Settings during a campaign. It defaults to `1.10` and ranges from `0.85 to 2.00` in `0.01` steps.

`1.15` is Legends' highest native numeric enemy-budget multiplier (Expert). Values above `1.15` increase only this mod's encounter budget. They do not enable Legends' separate Legendary enemy perks, stat changes, poison effects, or AI behavior. A changed value affects newly calculated encounters; an enemy party already spawned on the world map does not resize.

## Contract skulls

The planned normal-contract offer values are:

| Skull | Encounter multiplier | Payment multiplier |
| --- | ---: | ---: |
| 1 | 0.85 | 0.85 |
| 2 | 1.00 | 1.00 |
| 3 | 1.25 | 1.35 |
| 4 | 1.50 | 1.80 |

Authored special contracts retain their own difficulty until they are individually reviewed for compatibility.

## Debug logging

Debug logging is enabled by default and can be changed in Mod Settings. Logs are written to:

`C:\Users\gujar\Documents\Battle Brothers\log.html`

## Build

Build with `modbb`. The archive is produced under `mod_alternate_difficulties/build`.
