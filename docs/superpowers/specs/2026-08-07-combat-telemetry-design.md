# Combat Telemetry Design

## Goal

Make `log.html` explain the roster-based multiplier and the real enemy
composition for each battle without changing encounter generation.

## Design

Add a focused `CombatTelemetry` service and register hooks after Legends.
The service writes structured `[AlternateDifficulties][Telemetry]` lines only
at meaningful boundaries, never during every dynamic troop-candidate check.

### Roster snapshot

When normal-contract scaling is calculated, log the deployed count, reserve
count, every brother's name/level/reserve state, average level, roster
multiplier, configured custom multiplier, and final multiplier. This is the
exact input used by the mod's normal-contract scaling path.

### Combat snapshot

After tactical entities have spawned, log one encounter summary: player,
allied, enemy, and neutral actor counts. Then log a type-count summary and one
detail line for every non-player actor. Detail lines include entity script,
name, faction, level when available, current/max hitpoints, body armor,
head armor, and miniboss/champion status.

### Contract context

When a normal contract is created or its payment/scaling is calculated, log
its type, skull multiplier, skull payment multiplier, and the roster snapshot
used for the calculation. Economy difficulty remains untouched and is logged
as context, not modified.

### Noise control

The existing `DynamicTroops` per-candidate exclusion log is retained only for
the existing Debug Logging setting. Combat Telemetry adds at most one summary
plus one line per actor for a battle, so it can be correlated with the actual
encounter rather than hundreds of selection attempts.

## Safety and verification

Telemetry is read-only: it does not create, remove, equip, alter, or reroll
anything. Static source checks will verify the service is loaded, uses the
tactical entity collection only after combat setup, and does not read player
strength or item value for scaling. A live battle is verified by checking for
one roster line, one encounter summary, and actor-detail lines in `log.html`.
