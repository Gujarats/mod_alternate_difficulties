# Legends Deployed-Roster Scaling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Legends compatibility mod that replaces day- and equipment-value-based enemy scaling with scaling based only on brothers eligible for deployment, while making contract skulls clear risk-and-reward choices.

**Architecture:** The mod will load after Legends and hook Legends' contract and dynamic-spawn APIs without editing the Legends mod. One shared service calculates a bounded roster multiplier from the brothers that can actually deploy. Contract hooks use that multiplier for encounter resources and payment, and the dynamic troop hook removes the day-based `MinR` exception.

**Tech Stack:** Battle Brothers Squirrel scripts, Modern Hooks, MSU, `modbb`.

## Global Constraints

- Do not edit `data_001`, `mod_legends`, `mod_reforged`, `mod_witcher`, or any other reference/community mod.
- The package is `mod_alternate_difficulties`; the final mod ID and display name require user review before source files are created.
- The mod must require and load after `mod_legends` and `mod_msu`.
- The mod disregards the campaign combat-difficulty setting for the normal-contract scaling path and uses its own configurable custom multiplier instead.
- Enemy scaling must never read campaign day, player-party strength, item value, named-item value, or reserve-only brothers.
- Roster strength considers only brothers who can deploy into the next battle: non-reserve brothers, capped at `World.Assets.getBrothersMaxInCombat()`.
- Roster strength uses only deployable-brother count and average level.
- Debug logging is programmatic and enabled by default; it writes enough values to explain every final scaling calculation in `log.html`.
- Developer test tools are disabled by default, operate only after an explicit in-game action, and are for disposable test saves only.
- The Developer Test Lab may create only normal contract types that the current settlement can legally offer. It must not create legendary hunts, crisis contracts, or contracts whose normal world requirements are absent.
- Build only with `modbb`, with the default output under `mod_alternate_difficulties/build`.

## Locked Design Values

### Deployed roster multiplier

```
countScore = deployedCount / 6.0
levelScore = averageLevel / 6.0
rosterMultiplier = clamp(0.75, 1.40, 0.50 * countScore + 0.50 * levelScore)
customDifficultyMultiplier = ModSettings.CustomDifficultyMultiplier
finalEncounterMultiplier = rosterMultiplier * customDifficultyMultiplier
```

The 6-brother, average-level-6 roster is the `1.00` roster baseline. `CustomDifficultyMultiplier` defaults to `1.10`, between Legends Normal (`1.00`) and Expert (`1.15`), and is configurable from `0.85` through `2.00` in `0.01` steps. `1.15` is Legends' highest native numeric enemy-budget multiplier. Values above it intentionally increase only this mod's encounter resources; they do not enable the separate Legendary enemy perks, stat changes, poison effects, or AI behavior. The low clamp protects a new campaign from an excessively small encounter; the high clamp prevents a large, high-level deployment from reaching Legends' existing five-times maximum scaling. A changed setting applies to encounters calculated after the change; it does not change an enemy party already spawned on the world map.

### Fixed contract skull offers

| Skull | `DifficultyMult` | Encounter multiplier | Payment multiplier |
| --- | ---: | ---: | ---: |
| 1 | `0.85` | `0.85` | `0.85` |
| 2 | `1.00` | `1.00` | `1.00` |
| 3 | `1.25` | `1.25` | `1.35` |
| 4 | `1.50` | `1.50` | `1.80` |

Skulls remain visible before the player accepts a contract. The mod assigns a fixed value from this table when a normal contract is created; it does not negotiate or reroll the offer. Special contracts that deliberately assign their own difficulty are left unchanged in the first release and must be listed in the compatibility documentation.

---

### Task 1: Establish the standalone mod package and user-facing documentation

**Files:**
- Create: `mod_alternate_difficulties/scripts/!mods_preload/mod_alternate_difficulties_loader.nut`
- Create: `mod_alternate_difficulties/scripts/mods/alternate_difficulties/settings.nut`
- Create: `mod_alternate_difficulties/README.md`
- Modify: `mod_alternate_difficulties/readme.md`

**Interfaces:**
- Produces global namespace `::AlternateDifficulties` with `ID`, `Name`, `Version`, `HookMod`, `Mod`, and `Debug` fields.
- Produces `::AlternateDifficulties.Settings.register()` and `::AlternateDifficulties.Settings.isDebugEnabled()`.

- [ ] Create the loader with the reviewed mod ID/display name and dependencies `mod_msu` and `mod_legends`.
- [ ] Create the MSU settings page with a `DebugLogging` Boolean setting whose default is `true`.
- [ ] Add a General-page range setting named **Custom Enemy Difficulty** with ID `CustomDifficultyMultiplier`, default `1.10`, minimum `0.85`, maximum `2.00`, and step `0.01`. Its tooltip must state: `1.15 is Legends' highest native enemy-budget multiplier (Expert). Higher values increase only this mod's encounter budget; they do not enable Legendary enemy stats, perks, poison effects, or AI. Changes affect newly calculated encounters only; existing enemy parties do not resize.`
- [ ] Register a debug logger that prefixes every line with `[AlternateDifficulties]` and honours the setting after it changes.
- [ ] Write the README with the exact formula, the skull table, load-order requirement, excluded inputs, special-contract limitation, logging path, and `modbb` build command.
- [ ] Replace the short draft in `readme.md` with a link to `README.md` so there is one maintained user-facing source of truth.
- [ ] Start the game with Legends and this package enabled; verify the loader logs its initialized message to `C:\\Users\\gujar\\Documents\\Battle Brothers\\log.html`.
- [ ] Build with `modbb` and verify `mod_alternate_difficulties/build` contains the produced archive.

### Task 2: Implement and verify deployable-roster sampling

**Files:**
- Create: `mod_alternate_difficulties/scripts/mods/alternate_difficulties/deployed_roster_scaling.nut`
- Create: `mod_alternate_difficulties/tools/test_deployed_roster_scaling_contract.ps1`

**Interfaces:**
- Produces `::AlternateDifficulties.RosterScaling.getSnapshot()` returning `{ deployedCount, averageLevel, rosterMultiplier }`.
- Produces `::AlternateDifficulties.RosterScaling.getMultiplier()` returning the `rosterMultiplier` from a new snapshot.

- [ ] Write a static contract test that requires `getSnapshot()` to call `World.Assets.getBrothersMaxInCombat()`, inspect `World.getPlayerRoster().getAll()`, reject `bro.isInReserves()`, read a brother's level, and contain neither `getStrength` nor `getValue` nor `World.getTime().Days`.
- [ ] Run the test and confirm it fails because the service does not yet exist.
- [ ] Implement `getSnapshot()` to examine roster brothers in roster order, skip reserves, stop after the deployment limit, and calculate the mean level; return `0` average level for an empty deployment.
- [ ] Implement the locked formula using `Math.maxf`/`Math.minf` to clamp it from `0.75` through `1.40`.
- [ ] Make an empty deployment use the lower clamp rather than dividing by zero.
- [ ] Write one default-enabled debug line containing deployed count, average level, and final roster multiplier.
- [ ] Run the static contract test and confirm it passes.

### Task 3: Replace Legends' contract scaling without equipment or day scaling

**Files:**
- Create: `mod_alternate_difficulties/scripts/mods/alternate_difficulties/compatibility/legends_contract_patch.nut`
- Modify: `mod_alternate_difficulties/scripts/!mods_preload/mod_alternate_difficulties_loader.nut`
- Create: `mod_alternate_difficulties/tools/test_legends_contract_patch_contract.ps1`

**Interfaces:**
- Consumes `::AlternateDifficulties.RosterScaling.getMultiplier()`.
- Produces a replacement `contracts/contract.getScaledDifficultyMult()` that returns `rosterMultiplier * ModSettings.CustomDifficultyMultiplier`.

- [ ] Write a static test that asserts the hook targets `contracts/contract`, overrides `getScaledDifficultyMult`, calls `RosterScaling.getMultiplier`, reads `CustomDifficultyMultiplier`, and does not reference `getPlayer().getStrength`, item `getValue`, `World.getTime().Days`, or `getCombatDifficulty`.
- [ ] Run the test and confirm it fails before the hook exists.
- [ ] Hook `contracts/contract` after Legends has loaded and replace `getScaledDifficultyMult()` with the stated interface. Do not call `Const.Difficulty.EnemyMult` or `World.Assets.getCombatDifficulty()` from this replacement.
- [ ] Log the roster multiplier, the configured custom difficulty multiplier, and their final product once per scaling call.
- [ ] Run the static test and confirm it passes.
- [ ] In a disposable save, compare two otherwise identical contracts while changing only stored equipment; verify their logged scaled-difficulty multiplier is unchanged.
- [ ] In a disposable save, compare the same deployment on two campaign days; verify their logged scaled-difficulty multiplier is unchanged.
- [ ] In a disposable save, change **Custom Enemy Difficulty** from `1.10` to `1.00`, then to `2.00`, generating a new normal contract after each change. Verify the logged multiplier changes accordingly and confirm an already spawned party keeps its existing composition.

### Task 4: Remove the dynamic troop selector's day bypass

**Files:**
- Create: `mod_alternate_difficulties/scripts/mods/alternate_difficulties/compatibility/legends_dynamic_troop_patch.nut`
- Modify: `mod_alternate_difficulties/scripts/!mods_preload/mod_alternate_difficulties_loader.nut`
- Create: `mod_alternate_difficulties/tools/test_legends_dynamic_troop_patch_contract.ps1`

**Interfaces:**
- Hooks `Const.World.Common.dynamicSelectTroop` after Legends defines it.
- Produces the same candidate-selection behavior as Legends except a troop with `MinR` lower than its resource requirement is always excluded; campaign day never overrides `MinR`.

- [ ] Copy Legends' current `dynamicSelectTroop` algorithm into the compatibility hook, retaining `MaxR`, fixed-weight, random-weight, guard, credit, and party-size behavior exactly.
- [ ] Remove the `dateToSkip` calculation and replace the `MinR` condition with unconditional resource gating: if `_resources < minr`, skip the troop.
- [ ] Write a static test requiring the replacement to keep `MaxR` and `MinR` gates and rejecting `World.getTime().Days`, `dateToSkip`, and `DynamicDayToSkip`.
- [ ] Run the test and confirm it passes.
- [ ] Add a debug line when a `MinR` candidate is excluded, including its resource threshold and current encounter resources.
- [ ] Manually start comparable battles before and after day 90 with the same deployment and resources; confirm later days do not unlock an under-budget `MinR` troop.

### Task 5: Implement fixed visible skull offers and reward linkage

**Files:**
- Create: `mod_alternate_difficulties/scripts/mods/alternate_difficulties/contract_skull_offers.nut`
- Modify: `mod_alternate_difficulties/scripts/mods/alternate_difficulties/compatibility/legends_contract_patch.nut`
- Create: `mod_alternate_difficulties/tools/test_contract_skull_offer_contract.ps1`

**Interfaces:**
- Produces `::AlternateDifficulties.ContractOffers.applyNormalContractOffer(_contract)`.
- Produces `::AlternateDifficulties.ContractOffers.getPaymentMultiplier(_difficultyMult)` returning the table value for `0.85`, `1.00`, `1.25`, or `1.50`.

- [ ] Write a static test that requires all four locked `DifficultyMult` values and all four locked payment values.
- [ ] Run the test and confirm it fails before the offer service exists.
- [ ] Hook normal contract creation, choose one of the four table rows, and set `m.DifficultyMult` to its fixed value before the offer can be displayed.
- [ ] Override only the roster-derived portion of payment calculation so the skull payment table is applied once and the normal barter, economic difficulty, and reputation multipliers remain intact.
- [ ] Do not hook contracts whose scripts explicitly set a special `DifficultyMult`; log that they are intentionally left on their authored behavior.
- [ ] Log contract ID, assigned skull multiplier, encounter multiplier, and payment multiplier.
- [ ] Run the static test and confirm it passes.
- [ ] In a disposable save, inspect one offer at each skull level and confirm skull display, encounter resource multiplier, and payment direction match the table.

### Task 6: Add the disabled-by-default Developer Test Lab

**Files:**
- Create: `mod_alternate_difficulties/scripts/mods/alternate_difficulties/developer_test_lab.nut`
- Modify: `mod_alternate_difficulties/scripts/mods/alternate_difficulties/settings.nut`
- Modify: `mod_alternate_difficulties/scripts/!mods_preload/mod_alternate_difficulties_loader.nut`
- Modify: `mod_alternate_difficulties/README.md`
- Create: `mod_alternate_difficulties/tools/test_developer_test_lab_contract.ps1`

**Interfaces:**
- Produces `::AlternateDifficulties.DeveloperTestLab.applyRosterLevel()`.
- Produces `::AlternateDifficulties.DeveloperTestLab.grantMidTierLoadout()`.
- Produces `::AlternateDifficulties.DeveloperTestLab.grantCrowns()`.
- Produces `::AlternateDifficulties.DeveloperTestLab.generateSelectedNormalContract()`.

**Approved behavior:** The Test Lab is a deterministic contract generator. The player selects one normal contract type and one skull value, then explicitly triggers generation at the current city or village. It never floods the contract UI with every contract at once.

**Settings to create (all names and IDs are subject to the user naming review before implementation):**

| ID | Default | Purpose |
| --- | --- | --- |
| `EnableDeveloperTestLab` | `false` | Enables all test actions; without it, actions do nothing. |
| `TestRosterLevel` | `6` | Desired level for every current roster brother. |
| `TestCrownsAmount` | `5000` | Crowns granted by the explicit grant action. |
| `TestContractType` | first legal normal type | Selected normal contract type to generate. |
| `TestContractSkull` | `2` | Selected fixed offer skull, from 1 through 4. |
| `ApplyTestRosterLevel` | `false` | One-shot action that applies `TestRosterLevel`. |
| `GrantMidTierLoadout` | `false` | One-shot action that grants the predefined test armory: armor, helmets, and weapons. |
| `GrantTestCrowns` | `false` | One-shot action that grants `TestCrownsAmount`. |
| `GenerateSelectedTestContract` | `false` | One-shot action that creates the selected legal normal contract at the current settlement. |

- [ ] Inspect the current MSU settings API and a project reference for one-shot action controls; use a callback-backed Boolean setting that resets itself to `false` if there is no supported button setting.
- [ ] Write a static contract test that requires every test action to check `EnableDeveloperTestLab` before changing a save, and requires all one-shot action settings to reset to `false` after use.
- [ ] Run the test and confirm it fails before the Test Lab exists.
- [ ] Add a **Developer Test Lab** settings page. Give it the nine settings listed above, descriptive warnings that test saves are disposable, and tooltips that state each action is explicit rather than automatic.
- [ ] Implement `applyRosterLevel()` for every current roster brother, including reserves. Validate the chosen level against the game's supported level range, apply the corresponding experience/level update through the game's existing character-level API, and refresh dependent character state without granting items or money.
- [ ] Implement `grantMidTierLoadout()` as a single explicit armory grant. Add the documented, non-named mid-tier body armor, helmets, axes, hammers, swords, flails, and polearms to the player's stash. Give enough armor and helmets for every current roster brother, and add one of each listed weapon type per current roster brother so every weapon style can be tested immediately.
- [ ] Do not equip, replace, delete, or modify any equipped item. The player chooses the equipment manually from the stash. Add the exact vanilla/Legends-compatible item IDs, counts per brother, and no-named-item rule to the README before the implementation is considered complete.
- [ ] Implement `grantCrowns()` to add exactly `TestCrownsAmount` crowns once per explicit action. It must not run on save load, screen conversion, or settlement entry.
- [ ] Implement `generateSelectedNormalContract()` to validate that the player is at a city or village, enumerate normal contract types legal for that settlement, reject a selected type that is not in that legal set, and create exactly one selected contract with `DifficultyMult` from the approved 1-4 skull table.
- [ ] Do not delete, replace, or reroll existing settlement offers. If there is no legal selected contract or no current settlement, leave the world state unchanged and write a clear warning to the debug log.
- [ ] Log the affected brother count and target level, every granted item ID/count, exact crowns amount, settlement name, selected contract ID, and selected skull.
- [ ] Run the static contract test and confirm it passes.
- [ ] In a disposable save, test each action once with the Test Lab disabled and once enabled; verify disabled actions change nothing, enabled actions act exactly once, and a village/city can generate a legal normal selected contract without affecting its existing offers.

### Task 7: Regression checks, compatibility record, and release build

**Files:**
- Create: `mod_alternate_difficulties/docs/compatibility.md`
- Modify: `mod_alternate_difficulties/README.md`
- Modify: `mod_alternate_difficulties/tools/test_deployed_roster_scaling_contract.ps1`
- Modify: `mod_alternate_difficulties/tools/test_legends_contract_patch_contract.ps1`
- Modify: `mod_alternate_difficulties/tools/test_legends_dynamic_troop_patch_contract.ps1`
- Modify: `mod_alternate_difficulties/tools/test_contract_skull_offer_contract.ps1`

**Interfaces:**
- Produces a documented support boundary: normal Legends contracts use the fixed skull table; authored special contracts retain their authored difficulty until individually reviewed.

- [ ] Add static tests that scan this mod's scaling scripts and fail on `World.getTime().Days`, `getStrength`, and item `getValue` usage.
- [ ] Run all four PowerShell tests in one command and record the passing output in the implementation handoff.
- [ ] Document the Legends files and APIs depended on: `hooks/contracts/contract.nut`, `config/world_entity_common.nut`, `getBrothersMaxInCombat()`, and normal-contract `create()`.
- [ ] Document every excluded special contract discovered during testing, so a future patch can opt in deliberately rather than changing boss contracts by accident.
- [ ] Build with `modbb` and verify that the archive is produced under `mod_alternate_difficulties/build`.
- [ ] Test a new campaign and an existing save: confirm the mod loads, a full deployment scales from count and average level only, stored gear does not change the log values, and the game does not throw a script error while generating a contract or a dynamic enemy party.

## Scope Boundaries

- This release changes scaling used by normal contract encounters and Legends dynamic troop selection. It does not rebalance individual enemy stat scripts, legendary hunt contracts, named locations, crisis armies, or non-contract world parties that use separately authored difficulty logic.
- The custom **Custom Enemy Difficulty** setting replaces the campaign combat-difficulty multiplier only for the normal-contract scaling path owned by this mod. Legends' separate special-contract, arena, location, crisis, and world-party paths remain unchanged until individually patched. Economic difficulty and the normal economy multipliers remain respected.
- Adding manual skull selection, a UI redesign, or per-enemy stat modifiers is out of scope for this first release.

## Execution Order

Implement Tasks 1-4 first and test the roster-only encounter scaling before adding Task 5's skull/reward linkage. This keeps the core fairness change independently testable and prevents payment changes from hiding an encounter-scaling error.
