# Alternate Difficulties: Scaling Summary

## Day-based enemy scaling removed by this mod

`DynamicTroops.register()` replaces Legends' `Const.World.Common.dynamicSelectTroop`.

In Legends, a troop with a `MinR` requirement is normally excluded while the
encounter has too few resources. However, after a difficulty-dependent campaign
day (`dateToSkip`), Legends stops enforcing that requirement and can select the
under-budget troop.

This mod removes that bypass. Both direct spawn-list entries and `SortedTypes`
entries now use the same unconditional rule:

```nut
if (_resources < minr)
{
    continue;
}
```

As a result, campaign day never unlocks a troop whose `MinR` requirement is
higher than the encounter's available resources.

The relevant code is in:

- `scripts/mods/alternate_difficulties/compatibility/legends_dynamic_troop_patch.nut`
  - direct entries: `dynamicSelectTroop`, `MinR` check
  - `SortedTypes` entries: `dynamicSelectTroop`, nested `MinR` check

## Contract encounter scaling

`LegendsContract.registerHooks()` replaces the contract method
`getScaledDifficultyMult()`.

The replacement does not read `World.getTime().Days`, player strength, item
value, or Legends' combat-difficulty setting. It calculates the roster-based
part of a contract's enemy budget:

```text
scaled multiplier = deployed-roster multiplier × Custom Enemy Difficulty
```

Normal contract scripts then calculate enemy resources by multiplying their
base resources by both the contract skull and this scaled multiplier:

```text
enemy resources = base contract resources × contract skull × scaled multiplier
```

`contract skull` is `this.m.DifficultyMult`, returned by
`getDifficultyMult()`. Therefore the skull remains the player-visible measure
of contract enemy strength, while the global Legends combat-difficulty option
does not contribute to the calculation.

The relevant code is in:

- `scripts/mods/alternate_difficulties/compatibility/legends_contract_patch.nut`
  - `getScaledDifficultyMult()`

If the desired design is roster-only scaling, remove the `Custom Enemy
Difficulty` factor from this function and the corresponding setting from
`settings.nut`.

## Equipment-based enemy scaling removed by this mod

Legends' normal-contract implementation calculates encounter scaling from:

```nut
this.World.State.getPlayer().getStrength()
```

Player strength is affected by equipment, so that calculation can make better
or more valuable gear increase the enemy budget.

This mod replaces that calculation in `getScaledDifficultyMult()` with
`RosterScaling.getSnapshot()`. The snapshot reads only the number of brothers
eligible for deployment and their levels. It does not call `getStrength()`,
inspect inventory, or read item values.

Consequently, changing equipment cannot change this mod's normal-contract
encounter multiplier.

Relevant code:

- `scripts/mods/alternate_difficulties/compatibility/legends_contract_patch.nut`
  - `getScaledDifficultyMult()` chooses roster scaling instead of player strength.
- `scripts/mods/alternate_difficulties/deployed_roster_scaling.nut`
  - `RosterScaling.getSnapshot()` reads deployed count and `bro.getLevel()` only.

## Day-based systems this mod does not remove

This patch is not a global removal of all Legends day progression. In
particular, it does not change Legends' champion/miniboss chance adjustment
after day 100 (`getMinibossChances`), or other independent event and faction
scripts that use campaign day.

## Contract skulls and payments

The current mod also assigns a random 1–4 skull value to normal contracts.
That value affects both enemy resources and payment scaling. Contract scripts
use `getDifficultyMult()` (the skull value) together with
`getScaledDifficultyMult()` when spawning enemies.

Relevant functions:

- `ContractOffers.applyNormalContractOffer()` assigns the contract's skull.
- `ContractOffers.getPaymentMultiplier()` maps a skull value to payment.
- `q.create()` calls `applyNormalContractOffer()` after a contract is created.
- `q.getPaymentMult()` applies the skull's payment multiplier.

For example, with three brothers at levels 1, 2, and 3, the roster multiplier
is clamped to `0.75`. With the default Custom Enemy Difficulty setting of
`1.10`, the scaled multiplier is `0.825`. The resulting skull multipliers are
`0.70125`, `0.825`, `1.03125`, and `1.2375` for skulls 1 through 4.

## Developer Test Lab

The disabled-by-default **Developer Test Lab** in Mod Settings is intended for
a disposable new campaign. Every operation needs two deliberate actions:
enable the Test Lab and press its button. Nothing is triggered by loading a
save, entering a settlement, or changing a setting.

- **Set All Roster Levels** only raises each current brother (including
  reserves) to the selected level; it does not lower levels or touch gear.
- **Grant Mid-tier Loadout** adds one non-named kit per current brother to the
  stash: `mail_hauberk`, `nasal_helmet_with_mail`, `hand_axe`, `warhammer`,
  `arming_sword`, `flail`, and `billhook`. It never equips or removes items,
  and refuses a partial grant when there is insufficient stash space.
- **Grant Crowns** adds the selected amount exactly once for a button press.
- **Generate Selected Normal Contract** invokes the game’s own normal faction
  action, so it cannot fabricate arena, crisis, legendary-hunt, or boss
  contracts. It keeps all existing offers and changes only the created offer’s
  skull before it is displayed.

See `README.md` for the user instructions and `docs/compatibility.md` for the
normal-contract allow-list and exclusions.

## Build output

Running `modbb` from the mod directory creates the local release archive in
`dist/mod_alternate_difficulties.zip` before attempting deployment to the
game's `data` folder.
