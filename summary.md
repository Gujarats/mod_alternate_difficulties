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
value, or Legends' combat-difficulty setting. It currently calculates:

```text
final encounter multiplier = deployed-roster multiplier × Custom Enemy Difficulty
```

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
That value is used for skull display and payment scaling, not for the
replacement contract encounter multiplier.

Relevant functions:

- `ContractOffers.applyNormalContractOffer()` assigns the contract's skull.
- `ContractOffers.getPaymentMultiplier()` maps a skull value to payment.
- `q.create()` calls `applyNormalContractOffer()` after a contract is created.
- `q.getPaymentMult()` applies the skull's payment multiplier.

If contract skull and payment difficulty should also be disregarded, remove the
contract-offer system and the custom `getPaymentMult()` override.
