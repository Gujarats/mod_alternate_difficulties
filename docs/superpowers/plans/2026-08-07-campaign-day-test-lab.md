# Campaign-Day Test Lab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a guarded, configurable, test-only campaign-calendar jump and document the safer isolated MinR test.

**Architecture:** `settings.nut` provides a day increment and button. `DeveloperTestLab.advanceCampaignDays()` checks the Test Lab/world/combat state, increments virtual time by `days * SecondsPerDay`, refreshes the clock, and writes an exact diagnostic. It does not replay daily processing.

**Tech Stack:** Battle Brothers Squirrel, MSU ModSettings, PowerShell inline source-contract checks.

## Global Constraints

- Developer Test Lab only; default 100; range 1–365.
- Direct calendar jump for a disposable campaign; no per-day world processing is replayed.
- Do not create or edit `.ps1` files.

---

### Task 1: Calendar-jump service

**Files:**

- Modify: `scripts/mods/alternate_difficulties/developer_test_lab.nut`
- Test: inline PowerShell source-contract check

**Interfaces:**

- Produces: `::AlternateDifficulties.DeveloperTestLab.advanceCampaignDays()`.
- Consumes: `EnableDeveloperTestLab`, `TestDaysToAdvance`, `World.getTime()`, and `Time`.

- [ ] **Step 1: Write and run a failing source check**

Run this inline check before adding the function. Expected: `advanceCampaignDays is missing`.

```powershell
$s = Get-Content -Raw scripts/mods/alternate_difficulties/developer_test_lab.nut
if ($s -notmatch 'advanceCampaignDays') { throw 'advanceCampaignDays is missing' }
```

- [ ] **Step 2: Implement the smallest guarded method**

```nut
::AlternateDifficulties.DeveloperTestLab.advanceCampaignDays <- function()
{
	if (!::AlternateDifficulties.DeveloperTestLab.isEnabled())
	{
		::AlternateDifficulties.DeveloperTestLab.logWarning("Advance campaign days ignored because the Test Lab is disabled.");
		return;
	}

	if (::World == null || ::World.State == null || ("Tactical" in getroottable() && ::Tactical.State != null))
	{
		::AlternateDifficulties.DeveloperTestLab.logWarning("Advance campaign days requires the world map outside tactical combat.");
		return;
	}

	local days = ::AlternateDifficulties.Mod.ModSettings.getSetting("TestDaysToAdvance").getValue();
	local startingDay = ::World.getTime().Days;
	::Time.setVirtualTime(::Time.getVirtualTimeF() + days * ::World.getTime().SecondsPerDay);
	::World.State.updateDayTime();
	local finalDay = ::World.getTime().Days;
	::AlternateDifficulties.Mod.Debug.printLog("[AlternateDifficulties][TestLab] advanced campaign days startingDay=" + startingDay + " requestedDays=" + days + " finalDay=" + finalDay + " (calendar jump; daily processing was not replayed)");
}
```

- [ ] **Step 3: Run the source check again**

Extend the inline check to require `TestDaysToAdvance`, `SecondsPerDay`, `setVirtualTime`, `updateDayTime`, `startingDay`, and `finalDay`. Expected: PASS.

- [ ] **Step 4: Commit the service**

```powershell
git add scripts/mods/alternate_difficulties/developer_test_lab.nut
git commit -m "feat: add test campaign day jump"
```

### Task 2: Test Lab controls

**Files:**

- Modify: `scripts/mods/alternate_difficulties/settings.nut`
- Test: inline PowerShell source-contract check

**Interfaces:**

- Consumes: `DeveloperTestLab.advanceCampaignDays()`.
- Produces: `TestDaysToAdvance` and `AdvanceTestCampaignDays` settings.

- [ ] **Step 1: Write and run a failing setting check**

```powershell
$s = Get-Content -Raw scripts/mods/alternate_difficulties/settings.nut
if ($s -notmatch 'TestDaysToAdvance') { throw 'TestDaysToAdvance is missing' }
```

Expected: failure before implementing the controls.

- [ ] **Step 2: Add the range and button**

```nut
developerLab.addRangeSetting(
	"TestDaysToAdvance", 100, 1, 365, 1,
	"Test days to advance",
	"Calendar days added by the explicit button. This test-only jump does not replay wages, healing, events, contracts, or other daily processing for every skipped day."
);
developerLab.addButtonSetting(
	"AdvanceTestCampaignDays", null,
	"Advance Campaign Days",
	"Explicit action: permanently advances the disposable campaign calendar by Test days to advance. It only works outside tactical combat and skips ordinary per-day processing for the skipped period."
).addCallback(function(_data = null)
{
	::AlternateDifficulties.DeveloperTestLab.advanceCampaignDays();
});
```

- [ ] **Step 3: Re-run the setting check**

Require `"TestDaysToAdvance", 100, 1, 365, 1` and `advanceCampaignDays()`. Expected: PASS.

- [ ] **Step 4: Commit the controls**

```powershell
git add scripts/mods/alternate_difficulties/settings.nut
git commit -m "feat: expose campaign day test controls"
```

### Task 3: Documentation and verification

**Files:**

- Modify: `summary.md`
- Modify: `docs/superpowers/specs/2026-08-07-campaign-day-test-lab-design.md`
- Modify: `docs/superpowers/plans/2026-08-07-campaign-day-test-lab.md`

- [ ] **Step 1: Write and run a failing documentation check**

```powershell
$s = Get-Content -Raw summary.md
if ($s -notmatch 'Dynamic Day To Skip' -or $s -notmatch 'Advance Campaign Days') { throw 'campaign-day test guidance is missing' }
```

Expected: failure before the summary edit.

- [ ] **Step 2: Add the user guidance**

Add this content to `summary.md`:

```text
Advance Campaign Days moves the campaign calendar by the configured amount for a disposable test save. It does not replay one normal daily update per skipped day.

For this mod's MinR/day-bypass test, set Legends' Dynamic Day To Skip to 1 and test on day 2. This is safer because it changes only the condition under test; Alternate Difficulties must still log each under-budget MinR troop as excluded.
```

- [ ] **Step 3: Verify docs and package contracts**

Re-run the documentation check, `powershell -ExecutionPolicy Bypass -File tools/test_package_contract.ps1`, and `git diff --check`. Expected: all pass.

- [ ] **Step 4: Commit documentation and plan**

```powershell
git add summary.md docs/superpowers/specs/2026-08-07-campaign-day-test-lab-design.md docs/superpowers/plans/2026-08-07-campaign-day-test-lab.md
git commit -m "docs: explain campaign day testing"
```
