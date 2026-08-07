# Alternate Difficulties

An MSU and Legends compatibility mod for readable, roster-based encounter scaling and configurable economy pressure.

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

The new-campaign **Combat Difficulty** and **Economy Difficulty** choices are
ignored for new campaigns and existing saves. The game receives its safe Normal
index while this mod provides the actual combat and economy values.

## Economy Overrides

The **Economy Overrides** page provides independent, live-adjustable values:

| Setting | Default | Effect |
| --- | ---: | --- |
| Shop Cost Multiplier | 1.09 | Shop purchase and service costs |
| Sell and Loot Value Multiplier | 0.925 | Item and valuable sale value |
| Contract Payment Multiplier | 0.90 | Normal contract payment after skull and barter factors |
| Minimum Contract Payment / Per-head Payment | 10 / 1 | Legends contract payment floors |
| Healing and Repair Speed Multiplier | 0.275 | Natural/camp healing and repair speed |
| Ammo / Medicine / Tools Capacity | 75 / 38 / 38 | Base carried-resource caps |
| Stash Capacity | 21 | Base stash slots before origin, brother, follower, hand-cart, and wagon bonuses |

Lowering an ammo, medicine, tools, or stash option never deletes owned assets.
Resource caps take effect once the current amount falls below the new cap. A
stash reduction waits until enough slots are free, then applies automatically.
Changing a setting cannot resize an existing world party or tactical enemy.

## Contract skulls

Reviewed normal-contract types receive one fixed offer value when created:

| Skull | Encounter multiplier | Payment multiplier |
| --- | ---: | ---: |
| 1 | 0.85 | 0.85 |
| 2 | 1.00 | 1.00 |
| 3 | 1.25 | 1.35 |
| 4 | 1.50 | 1.80 |

The skull is still multiplied into the contract's enemy budget, so it is the
visible contract-risk choice. Authored special contracts retain their own
difficulty until individually reviewed; see [compatibility.md](docs/compatibility.md).

## Developer Test Lab

The **Developer Test Lab** page is disabled by default and is intended for a
disposable new campaign. Nothing runs when a save loads, a town is entered, or
a setting changes. Enable it, then press one explicit action button:

- **Set All Roster Levels** raises every current brother, including reserves,
  to the selected level. It never lowers a brother, adds money, or changes gear.
- **Grant Mid-tier Loadout** adds one complete non-named kit per current
  brother to the stash. Each kit contains `mail_hauberk`,
  `nasal_helmet_with_mail`, `hand_axe`, `warhammer`, `arming_sword`, `flail`,
  and `billhook`. It never equips, replaces, or removes an item. It does
  nothing if the stash does not have room for the complete grant.
- **Grant Crowns** adds exactly the configured amount once for that button
  press.
- **Generate Selected Normal Contract** creates exactly one selected contract
  only through the game's native faction action. It preserves existing offers,
  refuses unavailable world requirements, and then applies the selected 1-4
  skull before the offer is displayed. The supported test types are Drive Off
  Brigands, Investigate Cemetery, Hunt Webknechts, Hunt Unholds, and Drive Off
  Nomads. The settlement must be that faction's contract home, so this cannot
  place an offer in another town.

## Debug logging

Debug logging is enabled by default and can be changed in Mod Settings. Logs are written to:

`C:\Users\gujar\Documents\Battle Brothers\log.html`

For scaling diagnosis, search for these labels:

- `[Telemetry][Brother]` and `[Telemetry][Roster]`: every brother, reserve
  status, deployed count, average level, and all multiplier inputs.
- `[Telemetry][Contract]`: contract type, skull multiplier, and skull payment
  multiplier.
- `[Telemetry][Combat]`: actual player, allied, enemy, and neutral actor totals
  after a battle has spawned.
- `[Telemetry][Type]` and `[Telemetry][Actor]`: enemy/allied type totals and
  one detailed record per non-player actor.

## Verification TODO

The following work remains before the mod's complete behavior can be claimed as
verified in-game:

- [ ] Remove or disable the Test Lab **Advance Campaign Days** action. Its
  current virtual-time change does not advance `World.getTime().Days`, so it is
  not a valid calendar test.
- [ ] Test the `MinR` day-bypass patch without changing the campaign day: set
  Legends' **Dynamic Day To Skip** to `1`, then generate encounters on day 2 or
  later. Under-budget `MinR` troops must still be logged as excluded.
- [ ] Move combat telemetry to a post-spawn point, so its player/allied/enemy
  totals and actor details match the actual tactical encounter.
- [ ] Generate and accept a supported normal Test Lab contract, then confirm
  its log records the roster-based contract multiplier.
- [ ] Repeat that contract test with a different combat-difficulty option. The
  enemy-scaling multiplier must remain `roster multiplier × Custom Enemy
  Difficulty`.
- [ ] Load campaigns made with opposite Combat/Economy menu selections. Both
  must log `normalized existing save` with effective Normal values.
- [ ] Change an Economy Overrides setting in an existing campaign, then check
  a shop, sell value, normal contract payment, and healing/repair tick.
- [ ] Spawn a new patrol or roamer and confirm its log has
  `[FactionActionScaling]` with roster and custom multiplier values.
- [ ] Lower a resource or stash capacity below the current amount. Confirm the
  log reports a safe deferred stash reduction and no assets are deleted.

## Build

From the `mod_alternate_difficulties` directory, build with `modbb`. This
template writes the local archive under `mod_alternate_difficulties/dist`, then
attempts to copy it into the game's `data` directory.
