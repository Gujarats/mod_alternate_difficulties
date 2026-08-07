# Menu Difficulty Replacement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ignore both game-menu difficulty choices in new and existing campaigns, while applying roster-based enemy budgets and independently configurable economy overrides.

**Architecture:** A `DifficultyPolicy` module normalizes stored/reporting difficulty values to Normal and owns all economy values. It updates the Normal entries of vanilla and Legends difficulty tables. Dedicated faction-action hooks replace generic world-party budget helpers, keeping caller-authored skull, distance, crisis, and settlement modifiers.

**Tech Stack:** Squirrel (`.nut`), Modern Hooks/MSU, Battle Brothers/Legends scripts, inline PowerShell source assertions.

## Global Constraints

- Require Modern Hooks, MSU 1.9.0+, and Legends; queue after `mod_msu` and `mod_legends`.
- Do not edit vanilla, Legends, or third-party-mod source files.
- Do not build/deploy an archive or create `.ps1` files.
- Support both new campaigns and existing saves.
- Never delete resources or stash items if an option lowers a capacity.
- Do not retroactively resize world parties or tactical enemies.

---

## File Structure

| File | Responsibility |
| --- | --- |
| `scripts/mods/alternate_difficulties/difficulty_policy.nut` | Normalization, economy table values, safe stash reconciliation, logs. |
| `scripts/mods/alternate_difficulties/settings.nut` | Economy Overrides range settings and callbacks. |
| `scripts/mods/alternate_difficulties/compatibility/asset_manager_patch.nut` | New-campaign/save-load/getter hooks. |
| `scripts/mods/alternate_difficulties/compatibility/faction_action_patch.nut` | World-party budget replacements. |
| `scripts/!mods_preload/mod_alternate_difficulties_loader.nut` | Includes/registration. |
| `readme.md`, `summary.md`, `docs/compatibility.md` | User behavior and verification instructions. |

### Task 1: Create the central difficulty policy

**Files:**
- Create: `scripts/mods/alternate_difficulties/difficulty_policy.nut`
- Modify: `scripts/!mods_preload/mod_alternate_difficulties_loader.nut`
- Test: inline PowerShell source assertions

**Interfaces:**
- Produces `DifficultyPolicy.getCombatMultiplier() -> float`.
- Produces `DifficultyPolicy.normalizeAssets(_assets) -> void`.
- Produces `DifficultyPolicy.applyEconomyOverrides(_reason) -> void`.
- Produces `DifficultyPolicy.reconcileStashCapacity() -> void`.

- [ ] **Step 1: Establish the failing seam**

Run: `if (Test-Path 'scripts/mods/alternate_difficulties/difficulty_policy.nut') { throw 'Policy unexpectedly exists' }`

Expected: the command completes before the module exists.

- [ ] **Step 2: Write the policy API**

Create `DifficultyPolicy` with `Normal = ::Const.Difficulty.Normal` and:

```nut
function getCombatMultiplier()
{
    return ::AlternateDifficulties.Mod.ModSettings
        .getSetting("CustomDifficultyMultiplier").getValue();
}

function normalizeAssets( _assets )
{
    _assets.m.CombatDifficulty = this.Normal;
    _assets.m.EconomicDifficulty = this.Normal;
}
```

- [ ] **Step 3: Apply economy values centrally**

Implement `applyEconomyOverrides(_reason)` to write only Normal indexes of:
`Const.Difficulty.BuyPriceMult`, `SellPriceMult`, `PaymentMult`,
`MinPayments`, `MinHeadPayments`, `HealMult`, `RepairMult`, and
`MaxResources`, plus `Const.LegendMod.MaxResources`. Read the setting IDs
defined in Task 2. Log `_reason` and each active value.

- [ ] **Step 4: Implement non-destructive stash resizing**

Implement `reconcileStashCapacity()` only when `World`, `World.Assets`, and
the player roster exist. Set `World.Flags[Legends.Stash.Flags.StartingSize]`
directly; never call `Legends.Stash.setStartingSize()` because it resets cart
flags. Obtain the requested effective size with `Legends.Stash.getSize()`. If
it is at least the filled-slot count, resize; otherwise keep the current size
and log a deferred reduction. This preserves origin, brother, follower, hand
cart, and cart/wagon additions.

- [ ] **Step 5: Add the loader include**

Add `::include("scripts/mods/alternate_difficulties/difficulty_policy");`
before the compatibility module includes.

- [ ] **Step 6: Verify and commit**

Run: `$t = Get-Content -Raw 'scripts/mods/alternate_difficulties/difficulty_policy.nut'; @('getCombatMultiplier','normalizeAssets','applyEconomyOverrides','reconcileStashCapacity','LegendMod.MaxResources') | % { if (-not $t.Contains($_)) { throw "Missing $_" } }`

Expected: PASS.

Commit: `git add scripts/mods/alternate_difficulties/difficulty_policy.nut scripts/!mods_preload/mod_alternate_difficulties_loader.nut; git commit -m "feat: add central difficulty policy"`.

### Task 2: Add adjustable Economy Overrides

**Files:**
- Modify: `scripts/mods/alternate_difficulties/settings.nut`
- Modify: `scripts/mods/alternate_difficulties/difficulty_policy.nut`
- Test: inline PowerShell source assertions

**Interfaces:**
- Consumes `DifficultyPolicy.applyEconomyOverrides(_reason)`.
- Produces the ten settings IDs listed below.

- [ ] **Step 1: Establish the failing seam**

Run: `$t = Get-Content -Raw 'scripts/mods/alternate_difficulties/settings.nut'; if ($t.Contains('EconomyShopCostMultiplier')) { throw 'Economy settings unexpectedly exist' }`

Expected: the command completes before settings are added.

- [ ] **Step 2: Create the Economy Overrides page and exact settings**

Use `addRangeSetting` to add:

| ID | Default | Min | Max | Step |
| --- | ---: | ---: | ---: | ---: |
| `EconomyShopCostMultiplier` | 1.09 | 0.50 | 2.00 | 0.01 |
| `EconomySellLootMultiplier` | 0.925 | 0.10 | 2.00 | 0.005 |
| `EconomyContractPaymentMultiplier` | 0.90 | 0.10 | 2.00 | 0.01 |
| `EconomyMinimumPayment` | 10 | 0 | 1000 | 1 |
| `EconomyMinimumPerHeadPayment` | 1 | 0 | 100 | 1 |
| `EconomyRecoveryMultiplier` | 0.275 | 0.05 | 2.00 | 0.005 |
| `EconomyAmmoCapacity` | 75 | 1 | 1000 | 1 |
| `EconomyMedicineCapacity` | 38 | 1 | 1000 | 1 |
| `EconomyToolsCapacity` | 38 | 1 | 1000 | 1 |
| `EconomyStashCapacity` | 21 | 1 | 500 | 1 |

Descriptions must say menu Economy Difficulty is ignored and reductions do not
delete owned assets.

- [ ] **Step 3: Connect live callbacks**

Every setting callback calls:

```nut
::AlternateDifficulties.DifficultyPolicy.applyEconomyOverrides("setting-change");
```

Replace all Task 1 temporary values with reads of these settings.

- [ ] **Step 4: Verify and commit**

Run: `$t = Get-Content -Raw 'scripts/mods/alternate_difficulties/settings.nut'; @('EconomyShopCostMultiplier','EconomySellLootMultiplier','EconomyContractPaymentMultiplier','EconomyMinimumPayment','EconomyMinimumPerHeadPayment','EconomyRecoveryMultiplier','EconomyAmmoCapacity','EconomyMedicineCapacity','EconomyToolsCapacity','EconomyStashCapacity') | % { if (-not $t.Contains($_)) { throw "Missing $_" } }; if (($t | Select-String -AllMatches 'applyEconomyOverrides').Matches.Count -lt 10) { throw 'Missing callbacks' }`

Expected: PASS.

Commit: `git add scripts/mods/alternate_difficulties/settings.nut scripts/mods/alternate_difficulties/difficulty_policy.nut; git commit -m "feat: add configurable economy overrides"`.

### Task 3: Normalize difficulty values for new and existing saves

**Files:**
- Create: `scripts/mods/alternate_difficulties/compatibility/asset_manager_patch.nut`
- Modify: `scripts/!mods_preload/mod_alternate_difficulties_loader.nut`
- Test: inline PowerShell source assertions

**Interfaces:**
- Consumes all four Task 1 policy methods.
- Produces `Compatibility.AssetManager.registerHooks(_mod) -> void`.

- [ ] **Step 1: Establish the failing seam**

Run: `if (Test-Path 'scripts/mods/alternate_difficulties/compatibility/asset_manager_patch.nut') { throw 'Patch unexpectedly exists' }`

Expected: the command completes before the patch exists.

- [ ] **Step 2: Hook asset manager lifecycle and accessors**

Hook `scripts/states/world/asset_manager` through Modern Hooks. In
`setCampaignSettings(_settings)`, replace both incoming menu fields with
`Const.Difficulty.Normal` before `__original(_settings)`, then call
`normalizeAssets` and `applyEconomyOverrides("new-campaign")`. In
`onDeserialize(_in)`, call `__original(_in)` first, then call `normalizeAssets`
and `applyEconomyOverrides("save-load")`.

Replace the three getters with:

```nut
q.getCombatDifficulty = @(__original) function() { return ::Const.Difficulty.Normal; }
q.getEconomicDifficulty = @(__original) function() { return ::Const.Difficulty.Normal; }
q.getDifficulty = @(__original) function() { return ::Const.Difficulty.Normal; }
```

Wrap `update(_worldState)` to run the original and then reconcile the stash
cap, allowing deferred reductions once enough slots are free.

- [ ] **Step 3: Register the patch**

Include `compatibility/asset_manager_patch`; register it before contract and
telemetry hooks in the post-Legends queue. Call
`DifficultyPolicy.applyEconomyOverrides("mod-initialization")` after settings
registration.

- [ ] **Step 4: Verify and commit**

Run: `$t = Get-Content -Raw 'scripts/mods/alternate_difficulties/compatibility/asset_manager_patch.nut'; @('setCampaignSettings','onDeserialize','getCombatDifficulty','getEconomicDifficulty','getDifficulty','reconcileStashCapacity') | % { if (-not $t.Contains($_)) { throw "Missing $_" } }`

Expected: PASS.

Commit: `git add scripts/mods/alternate_difficulties/compatibility/asset_manager_patch.nut scripts/!mods_preload/mod_alternate_difficulties_loader.nut; git commit -m "feat: normalize menu difficulties in saved campaigns"`.

### Task 4: Replace faction-action world-party scaling

**Files:**
- Create: `scripts/mods/alternate_difficulties/compatibility/faction_action_patch.nut`
- Modify: `scripts/!mods_preload/mod_alternate_difficulties_loader.nut`
- Test: inline PowerShell source assertions

**Interfaces:**
- Consumes `RosterScaling.getSnapshot()` and `DifficultyPolicy.getCombatMultiplier()`.
- Produces `Compatibility.FactionAction.registerHooks(_mod) -> void`.

- [ ] **Step 1: Establish the failing seam**

Run: `if (Test-Path 'scripts/mods/alternate_difficulties/compatibility/faction_action_patch.nut') { throw 'Patch unexpectedly exists' }`

Expected: the command completes before the patch exists.

- [ ] **Step 2: Replace both generic budget helpers**

Hook `scripts/factions/faction_action`. Replace
`getScaledDifficultyMult()` and `getReputationToDifficultyLightMult()` without
calling their originals. Each returns:

```nut
local snapshot = ::AlternateDifficulties.RosterScaling.getSnapshot();
return snapshot.rosterMultiplier * ::AlternateDifficulties.DifficultyPolicy.getCombatMultiplier();
```

Log helper name, deployed count, average level, roster multiplier, custom
multiplier, and final multiplier. Do not modify individual faction actions.

- [ ] **Step 3: Register, verify, and commit**

Include/register the patch after AssetManager. Run: `$t = Get-Content -Raw 'scripts/mods/alternate_difficulties/compatibility/faction_action_patch.nut'; @('getScaledDifficultyMult','getReputationToDifficultyLightMult','RosterScaling.getSnapshot','DifficultyPolicy.getCombatMultiplier') | % { if (-not $t.Contains($_)) { throw "Missing $_" } }`

Expected: PASS.

Commit: `git add scripts/mods/alternate_difficulties/compatibility/faction_action_patch.nut scripts/!mods_preload/mod_alternate_difficulties_loader.nut; git commit -m "feat: scale world parties from roster policy"`.

### Task 5: Apply payments, diagnostics, and documentation

**Files:**
- Modify: `scripts/mods/alternate_difficulties/compatibility/legends_contract_patch.nut`
- Modify: `scripts/mods/alternate_difficulties/combat_telemetry.nut`
- Modify: `readme.md`
- Modify: `summary.md`
- Modify: `docs/compatibility.md`
- Test: inline PowerShell source assertions and `git diff --check`

**Interfaces:**
- Contract payment uses `Const.Difficulty.PaymentMult[Const.Difficulty.Normal]` exactly once through the standard reputation-payment helper, in addition to its existing skull/barter terms.
- Telemetry reports normalized difficulty and policy values.

- [ ] **Step 1: Establish the failing seam**

Run: `$t = Get-Content -Raw 'readme.md'; if ($t.Contains('Economy Overrides')) { throw 'Documentation unexpectedly exists' }`

Expected: the command completes before docs are updated.

- [ ] **Step 2: Apply configured contract payment**

Keep the fixed skull payment table and roster/custom combat calculation. The
standard reputation-payment helper reads
`Const.Difficulty.PaymentMult[getEconomicDifficulty()]`; the asset-manager
override makes that index Normal, so the configured value is applied exactly
once. Do not additionally multiply it in `getPaymentMult`, do not read raw
asset `ContractPaymentMult` as the override, and do not change skull values.

- [ ] **Step 3: Extend logs and docs**

Telemetry logs the normalized effective combat/economy values and all policy
values. Documentation lists all ten settings/defaults, explains that menu
difficulties are ignored in new/existing saves, and states which effects are
immediate versus non-retroactive. Compatibility documentation adds faction
actions while retaining the authored special-contract boundary.

- [ ] **Step 4: Verify and commit**

Run: `$r = Get-Content -Raw 'readme.md'; @('Economy Overrides','1.09','0.925','0.90','0.275','existing saves','never deletes') | % { if (-not $r.Contains($_)) { throw "README missing $_" } }; $p = Get-Content -Raw 'scripts/mods/alternate_difficulties/difficulty_policy.nut'; if (-not $p.Contains('PaymentMult[normal] = contractPayment')) { throw 'Missing payment policy' }; $c = Get-Content -Raw 'scripts/mods/alternate_difficulties/compatibility/legends_contract_patch.nut'; if ($c.Contains('economyPaymentMultiplier')) { throw 'Payment policy would be applied twice' }; git diff --check`

Expected: PASS.

Commit: `git add scripts/mods/alternate_difficulties/compatibility/legends_contract_patch.nut scripts/mods/alternate_difficulties/combat_telemetry.nut readme.md summary.md docs/compatibility.md; git commit -m "docs: explain live menu difficulty overrides"`.

### Task 6: Complete source verification and manual test instructions

**Files:**
- Modify: `readme.md`
- Test: inline PowerShell source assertions, `git diff --check`, `git status --short`

- [ ] **Step 1: Add an in-game verification checklist**

Document two saves made with opposite menu selections, a live Economy Overrides
change, a shop/sell/payment/recovery check, a safe capacity reduction, and a
new patrol/roamer spawn. Require log records for initialization, save-load
normalization, economy setting changes, and faction-action scaling.

- [ ] **Step 2: Verify all integration points**

Run: `$l = Get-Content -Raw 'scripts/!mods_preload/mod_alternate_difficulties_loader.nut'; @('difficulty_policy','asset_manager_patch','faction_action_patch') | % { if (-not $l.Contains($_)) { throw "Loader missing $_" } }; $p = Get-Content -Raw 'scripts/mods/alternate_difficulties/difficulty_policy.nut'; @('BuyPriceMult','SellPriceMult','PaymentMult','MinPayments','MinHeadPayments','HealMult','RepairMult','MaxResources','LegendMod.MaxResources') | % { if (-not $p.Contains($_)) { throw "Policy missing $_" } }; git diff --check; git status --short`

Expected: all assertions pass; no unintended files appear.

- [ ] **Step 3: Commit**

Commit: `git add readme.md; git commit -m "docs: add difficulty override verification guide"`.

## Plan self-review

Tasks 1-3 cover centralized policy, settings, and both new/existing campaign
lifecycle paths. Task 4 covers patrol/roamer faction action budgets. Task 5
preserves skulls while applying payment policy and documenting behavior. Task
6 covers source integration and in-game verification. All symbols, values,
files, and verification commands are explicit and consistent.
