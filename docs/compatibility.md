# Compatibility boundary

Alternate Difficulties requires MSU and Legends, and its loader queues after
`mod_msu` and `mod_legends`.

## Legends APIs used

- `hooks/contracts/contract.nut`: the mod replaces the normal contract
  `getScaledDifficultyMult()` calculation.
- `config/world_entity_common.nut`: the mod replaces `dynamicSelectTroop()`
  with the same selection algorithm, except that an under-budget `MinR` troop
  is never unlocked by campaign day.
- `states/world/asset_manager`: the mod normalizes Combat/Economy Difficulty
  for new campaigns and loaded saves, then supplies its own Normal-slot policy
  values for standard getter-based callers.
- `factions/faction_action`: generic world-party budget helpers use deployed
  roster scaling and Custom Enemy Difficulty rather than player strength,
  campaign day, or Combat Difficulty.
- `World.Assets.getBrothersMaxInCombat()` and `World.getPlayerRoster().getAll()`:
  only the non-reserve brothers eligible for deployment are sampled.
- Normal contract `create()`: reviewed normal types receive their fixed visible
  skull before their offer can be displayed.

## Contract boundary

Only these contract IDs receive the fixed 1-4 skull table:

- `contract.destroy_goblin_camp`
- `contract.destroy_orc_camp`
- `contract.drive_away_bandits`
- `contract.drive_away_barbarians`
- `contract.drive_away_nomads`
- `contract.free_greenskin_prisoners`
- `contract.hunting_alps`
- `contract.hunting_hexen`
- `contract.hunting_sandgolems`
- `contract.hunting_schrats`
- `contract.hunting_serpents`
- `contract.hunting_unholds`
- `contract.hunting_webknechts`
- `contract.investigate_cemetery`
- `contract.return_item`
- `contract.roaming_beasts`
- `contract.roaming_beasts_desert`

Every other contract keeps its script-authored `DifficultyMult`. In particular,
the known special families are excluded: arena and tournament, big game and
legendary hunts, barbarian king, warlord, siege, holy-site, decisive-battle,
last-stand, settlement-defense, noble-war, caravan-raid, and crisis contracts.
The following normal-looking but individually authored types are also excluded
until reviewed: delivery, escort caravan, discover location, patrol, privateering,
root out undead, restore location, slave uprising, and tutorial.

## Developer Test Lab boundary

The Test Lab creates a selected offer by calling its installed faction action
only after that action's normal world requirements return a positive score. It
does not construct a contract class directly, reroll or remove settlement
offers, or create a contract away from the action's own settlement home. This
is why it is limited to the five documented test contract types.

## Inputs intentionally excluded

The normal-contract and generic faction-action replacements do not read
campaign day, `getStrength()`, item value, named-item value, stored equipment,
or the campaign Combat Difficulty option. The deployed-roster formula uses
only deployable count and average brother level. Separately authored event
encounters and day-based champion logic remain outside the roster-budget scope,
but their Combat/Economy menu reads receive the safe Normal policy index.
