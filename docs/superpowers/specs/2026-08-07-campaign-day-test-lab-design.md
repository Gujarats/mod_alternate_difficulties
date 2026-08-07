# Campaign-Day Test Lab Design

## Goal

Provide a deliberate way to advance a disposable test campaign by a
configurable number of days, while documenting the safer isolated test for the
Legends dynamic-troop day bypass.

## Test Lab action

The **Developer Test Lab** gains a `Test days to advance` range setting. It
defaults to 100 and accepts values from 1 through 365. Its **Advance Campaign
Days** button does nothing unless the Test Lab is enabled, a world campaign is
loaded, and tactical combat is not active.

The action advances the engine's virtual campaign-time counter by the selected
number of full days. It does not directly assign `World.getTime().Days`, which
is a derived value. Battle Brothers does not expose a mod-callable routine for
processing one complete normal campaign day, so this is intentionally a
test-only calendar jump: it does not replay wages, healing, settlement
updates, contracts, events, or other daily systems once per skipped day.

Before and after advancing, the Test Lab writes a single diagnostic entry with
the starting day, requested amount, and final day. The button description warns
that the action permanently changes the disposable campaign and skips ordinary
per-day processing for the skipped period.

## Safer isolated test

`summary.md` documents that setting Legends' **Dynamic Day To Skip** to `1`
is the safer test for this mod's `MinR` protection. On day 2, unmodified
Legends would stop applying the `MinR` budget gate; Alternate Difficulties
continues to log the troop as excluded. This isolates the precise condition
without advancing the campaign or triggering unrelated day-based systems.

Advancing 100 days remains useful for broader compatibility testing, but it is
not needed to validate the `dynamicSelectTroop` day-bypass removal.

## Error handling and verification

The button logs a warning and makes no changes when disabled, outside a world
campaign, or during tactical combat. Source checks will verify the setting,
guard clauses, virtual-time increment, and start/end diagnostic line. A live
test will confirm the day increases by the configured amount and that the log
records the same values.
