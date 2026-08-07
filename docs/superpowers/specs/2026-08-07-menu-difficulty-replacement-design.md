# Menu Difficulty Replacement Design

## Goal

Make the new-campaign **Combat Difficulty** and **Economy Difficulty** menu
choices have no gameplay effect in an Alternate Difficulties campaign. Enemy
budgets use the mod's roster/custom-combat model; economy behavior uses
explicit Alternate Difficulties settings.

This design applies to new campaigns. The campaign's internally stored combat
and economy difficulty values are normalized to Normal when it is created.

## Scope

### Menu-difficulty normalization

Add an asset-manager compatibility hook, loaded after Legends, that normalizes
both campaign difficulty fields to `Const.Difficulty.Normal` before the
vanilla/Legends campaign setup consumes them. The hook also returns Normal from
all three public accessors:

- `getCombatDifficulty()`
- `getEconomicDifficulty()`
- `getDifficulty()` (the legacy combat alias)

This covers all vanilla, Legends, and compatible-mod callers that use these
accessors. It also covers the small number of raw `m.CombatDifficulty` and
`m.EconomicDifficulty` callers, because the stored fields themselves are
normalized at campaign creation.

The mod does not edit vanilla, Legends, or third-party-mod files. The original
choices remain irrelevant instead of being reinterpreted as Alternate
Difficulties settings.

### Combat encounter budgets

The existing contract hook remains the source of contract enemy scaling:

```text
contract enemy budget = base resources x contract skull x roster multiplier x Custom Enemy Difficulty
```

Contract skulls remain visible risk choices and are not replaced.

Add a world-faction-action hook for both generic helpers that currently mix
player strength, campaign day, and Combat Difficulty into world-party resources:

- `getScaledDifficultyMult()`
- `getReputationToDifficultyLightMult()`

Both will return `roster multiplier x Custom Enemy Difficulty`. Therefore
patrols, roamers, ambushers, caravans, armies, and other faction-action parties
that use either helper no longer obtain a multiplier from the Combat Difficulty
menu, player strength, equipment value, or campaign day. Distance, settlement
resources, crisis multipliers, party templates, and authored event modifiers
remain intact because they are applied by the callers outside these helpers.

Other combat-difficulty checks (for example, non-budget Legendary feature gates
in other mods) receive Normal through the centralized accessor policy. This
mod continues not to enable Legendary-only stats, perks, poison, AI, or other
authored content.

### Economy settings

Retain `Custom Enemy Difficulty` for combat only. Add an **Economy Overrides**
settings page with independently adjustable values. The defaults deliberately
use different points in the Legends Hard-to-Legendary range:

| Setting | Default | Legends reference |
| --- | ---: | --- |
| Shop Cost Multiplier | 1.09 | High Legendary |
| Sell and Loot Value Multiplier | 0.925 | Mid Legendary |
| Contract Payment Multiplier | 0.90 | Legendary |
| Minimum Contract Payment | 10 | Legendary |
| Minimum Per-Head Contract Payment | 1 | Legendary |
| Healing and Repair Speed Multiplier | 0.275 | Low Legendary |
| Ammo Capacity | 75 | Mid Legendary |
| Medicine Capacity | 38 | Mid Legendary |
| Tools Capacity | 38 | Mid Legendary |
| Stash Capacity | 21 | Low Legendary |

Use positive numeric range settings with the following bounds:

| Setting | Minimum | Maximum | Step |
| --- | ---: | ---: | ---: |
| Shop Cost | 0.50 | 2.00 | 0.01 |
| Sell and Loot Value | 0.10 | 2.00 | 0.005 |
| Contract Payment | 0.10 | 2.00 | 0.01 |
| Healing and Repair Speed | 0.05 | 2.00 | 0.005 |
| Minimum Contract Payment | 0 | 1,000 | 1 |
| Minimum Per-Head Payment | 0 | 100 | 1 |
| Ammo, Medicine, Tools Capacity | 1 | 1,000 | 1 |
| Stash Capacity | 1 | 500 | 1 |

### Central economy application

Create one economy-policy module that reads the settings and writes the active
values into the **Normal** entries of the difficulty tables after Legends has
loaded:

- `Const.Difficulty.BuyPriceMult`
- `Const.Difficulty.SellPriceMult`
- `Const.Difficulty.PaymentMult`
- `Const.Difficulty.MinPayments`
- `Const.Difficulty.MinHeadPayments`
- `Const.Difficulty.HealMult`
- `Const.Difficulty.RepairMult`
- `Const.Difficulty.MaxResources`
- `Const.LegendMod.MaxResources`

Because the asset-manager policy always reports Normal, all normal
getter-based economy callers consume these explicit values: shops, selling,
loot, contract payments/floors, healing, repairing, camp healing/repairing,
resource caps, and the initial Legends stash-cap calculation. This approach
provides broad coverage without maintaining dozens of duplicate per-script
hooks.

The user settings are absolute values, not derived from the selected menu
difficulty or from the enemy slider. Their changes are applied immediately to
future price/payment calculations and subsequent healing/repair ticks.

### Safe live capacity changes

Changing a resource cap never deletes ammo, medicine, or tools already held.
The new cap is enforced on later additions and refill/repair operations.

Increasing the stash cap applies immediately. Decreasing it is deferred while
the stash contains more entries than the requested cap; the mod logs the
requested and effective caps and applies the reduction once it can do so
without losing an item.

### Diagnostics and documentation

At campaign initialization and after an Economy Overrides setting changes, log:

- original selected menu combat/economy values and the normalized Normal value;
- active custom combat multiplier;
- every active economy override value;
- any deferred stash-cap reduction.

Update `readme.md`, `summary.md`, and `docs/compatibility.md` to state that
both game-menu difficulty choices are ignored, distinguish roster combat
scaling from economy overrides, and document the safe capacity behavior.

## Verification

1. Start two disposable new campaigns with opposite game-menu combat/economy
   selections. Confirm the initialization logs report the same normalized
   values and active Alternate Difficulties values.
2. Generate equivalent normal contracts and faction-action patrols/roamers.
   Confirm their budget logs use roster/custom combat values, not selected
   menu difficulty, player strength, equipment, or campaign day.
3. Change each economy setting and verify its corresponding shop, sell/loot,
   contract payment, heal/repair, or capacity result changes immediately.
4. Confirm a payment floor uses the configured minimum values.
5. Lower each resource cap below the current resource amount and confirm no
   resource is deleted; further additions do not exceed the cap after the
   amount falls below it.
6. Attempt to lower the stash capacity below its occupied size. Confirm items
   are retained, the log reports a deferred reduction, and the capacity lowers
   only after enough space is free.
7. Run the existing dynamic-troop and contract-skull checks to confirm the
   new policy does not alter their intended behavior.

## Non-goals

- Editing vanilla, Legends, or third-party-mod source files.
- Enabling or tuning Legendary-only enemy content.
- Changing the contract skull meaning or authored special-contract rules.
- Retroactively resizing already-spawned world parties.
- Deleting resources or stash items when a user lowers an option.
