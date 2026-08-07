# Combat Telemetry Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Log the exact roster inputs and spawned combat composition needed to audit Alternate Difficulties scaling.

**Architecture:** A read-only `CombatTelemetry` service owns all formatting and collection. The existing contract hook supplies roster and contract context; a post-original `tactical_state.init()` hook logs the actual spawned tactical actors once per battle.

**Tech Stack:** Battle Brothers Squirrel, Modern Hooks, MSU debug logger.

## Global Constraints

- Telemetry must never create, remove, equip, reroll, or otherwise modify gameplay state.
- Telemetry must not read player strength, item values, or campaign day to calculate scaling.
- Combat actor capture must run after the original `tactical_state.init()` so `Tactical.Entities` contains spawned actors.
- Do not create or modify `.ps1` files.

---

### Task 1: Add the telemetry service and loader registration

**Files:**
- Create: `scripts/mods/alternate_difficulties/combat_telemetry.nut`
- Modify: `scripts/!mods_preload/mod_alternate_difficulties_loader.nut`

**Interfaces:**
- Produces `::AlternateDifficulties.CombatTelemetry.logRoster(_reason, _snapshot, _customMultiplier)`.
- Produces `::AlternateDifficulties.CombatTelemetry.logCombatSnapshot()`.
- Produces `::AlternateDifficulties.CombatTelemetry.registerHooks(_mod)`.

- [ ] Write an inline static assertion that fails while `combat_telemetry.nut`, `logRoster`, `logCombatSnapshot`, and loader inclusion are absent.
- [ ] Run the assertion and verify its expected failure.
- [ ] Implement `logRoster` to enumerate player-roster brothers, include reserves, and log name, level, reserve state, deployed count, average level, roster multiplier, custom multiplier, and final multiplier.
- [ ] Implement `logCombatSnapshot` to read `Tactical.Entities.getAllInstances()`, classify player/allied/enemy/neutral actors, log a total summary, a script-type summary, and one details line per non-player actor.
- [ ] Hook `scripts/states/tactical_state.init` and call the snapshot only after the original initializer returns.
- [ ] Include the new service before the compatibility hook registration, then run the static assertion and verify it passes.

### Task 2: Connect contract context and document use

**Files:**
- Modify: `scripts/mods/alternate_difficulties/compatibility/legends_contract_patch.nut`
- Modify: `README.md`

**Interfaces:**
- Consumes `CombatTelemetry.logRoster` from Task 1.

- [ ] Write an inline static assertion that fails while the contract scaling replacement does not call `CombatTelemetry.logRoster`.
- [ ] Run the assertion and verify its expected failure.
- [ ] Call `logRoster("contract-scaling", snapshot, customDifficultyMultiplier)` immediately before returning the final contract multiplier.
- [ ] Add README instructions identifying `[Telemetry][Roster]`, `[Telemetry][Combat]`, `[Telemetry][Type]`, and `[Telemetry][Actor]` log records.
- [ ] Run the static assertion, existing non-stale source checks, and `git diff --check`.

### Task 3: Package and live verification checklist

**Files:**
- Modify: generated `dist/mod_alternate_difficulties.zip`

- [ ] Run `modbb --config .\\mod_config.json` from the mod directory; confirm the local archive is generated even if deployment to Steam data requires user permission.
- [ ] Verify the archive contains `combat_telemetry.nut`.
- [ ] In game, enter one battle and inspect `log.html` for exactly one combat summary, one or more type summaries, and one actor record per non-player actor.
