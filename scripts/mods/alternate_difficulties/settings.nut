if (!("Settings" in ::AlternateDifficulties))
{
	::AlternateDifficulties.Settings <- {};
}

::AlternateDifficulties.Settings.register <- function()
{
	local general = ::AlternateDifficulties.Mod.ModSettings.addPage("General");
	local developer = ::AlternateDifficulties.Mod.ModSettings.addPage("Developer Options");

	general.addRangeSetting(
		"CustomDifficultyMultiplier", 1.10, 0.85, 2.00, 0.01,
		"Custom Enemy Difficulty",
		"1.15 is Legends' highest native enemy-budget multiplier (Expert). Higher values increase only this mod's encounter budget; they do not enable Legendary enemy stats, perks, poison effects, or AI. Changes affect newly calculated encounters only; existing enemy parties do not resize."
	);

	local debugLogging = developer.addBooleanSetting(
		"DebugLogging", true,
		"Debug Logging",
		"Write Alternate Difficulties diagnostic lines to log.html."
	);

	debugLogging.addCallback(function(_data = null)
	{
		::AlternateDifficulties.Settings.configureDebugLogging();
	});

	::AlternateDifficulties.Settings.configureDebugLogging();
}

::AlternateDifficulties.Settings.isDebugEnabled <- function()
{
	return ::AlternateDifficulties.Mod.ModSettings.getSetting("DebugLogging").getValue();
}

::AlternateDifficulties.Settings.configureDebugLogging <- function()
{
	local enabled = ::AlternateDifficulties.Settings.isDebugEnabled();
	::AlternateDifficulties.Mod.Debug.setFlag("default", enabled);

	if (enabled)
	{
		::AlternateDifficulties.Mod.Debug.printLog("[AlternateDifficulties] debug logging enabled");
	}
}
