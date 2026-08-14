if (!("Settings" in ::AlternateDifficulties))
{
	::AlternateDifficulties.Settings <- {};
}

::AlternateDifficulties.Settings.register <- function()
{
	local general = ::AlternateDifficulties.Mod.ModSettings.addPage("General");
	local economy = ::AlternateDifficulties.Mod.ModSettings.addPage("Economy Overrides");
	local developer = ::AlternateDifficulties.Mod.ModSettings.addPage("Developer Options");
	local developerLab = ::AlternateDifficulties.Mod.ModSettings.addPage("Developer Test Lab");

	general.addRangeSetting(
		"CustomDifficultyMultiplier", 1.10, 0.85, 2.00, 0.01,
		"Custom Enemy Difficulty",
		"1.15 is Legends' highest native enemy-budget multiplier (Expert). Higher values increase only this mod's encounter budget; they do not enable Legendary enemy stats, perks, poison effects, or AI. Changes affect newly calculated encounters only; existing enemy parties do not resize."
	);

	local economyShopCost = economy.addRangeSetting(
		"EconomyShopCostMultiplier", 1.09, 0.50, 2.00, 0.01,
		"Shop Cost Multiplier",
		"Multiplier for shop purchase and service costs. The game-menu Economy Difficulty is ignored."
	);
	economyShopCost.addCallback(function(_data = null)
	{
		::AlternateDifficulties.DifficultyPolicy.applyEconomyOverrides("setting-change");
	});
	local economySellLoot = economy.addRangeSetting(
		"EconomySellLootMultiplier", 0.925, 0.10, 2.00, 0.005,
		"Sell and Loot Value Multiplier",
		"Multiplier for selling items and valuables. The game-menu Economy Difficulty is ignored."
	);
	economySellLoot.addCallback(function(_data = null)
	{
		::AlternateDifficulties.DifficultyPolicy.applyEconomyOverrides("setting-change");
	});
	local economyContractPayment = economy.addRangeSetting(
		"EconomyContractPaymentMultiplier", 0.90, 0.10, 2.00, 0.01,
		"Contract Payment Multiplier",
		"Multiplier for normal contract payments after skull and barter factors."
	);
	economyContractPayment.addCallback(function(_data = null)
	{
		::AlternateDifficulties.DifficultyPolicy.applyEconomyOverrides("setting-change");
	});
	local economyMinimumPayment = economy.addRangeSetting(
		"EconomyMinimumPayment", 10, 0, 1000, 1,
		"Minimum Contract Payment",
		"Minimum crowns for a contract completion payment."
	);
	economyMinimumPayment.addCallback(function(_data = null)
	{
		::AlternateDifficulties.DifficultyPolicy.applyEconomyOverrides("setting-change");
	});
	local economyMinimumPerHead = economy.addRangeSetting(
		"EconomyMinimumPerHeadPayment", 1, 0, 100, 1,
		"Minimum Per-head Contract Payment",
		"Minimum crowns paid per counted contract target."
	);
	economyMinimumPerHead.addCallback(function(_data = null)
	{
		::AlternateDifficulties.DifficultyPolicy.applyEconomyOverrides("setting-change");
	});
	local economyRecovery = economy.addRangeSetting(
		"EconomyRecoveryMultiplier", 0.275, 0.05, 2.00, 0.005,
		"Healing and Repair Speed Multiplier",
		"Multiplier for natural healing, camp healing, and repair speed."
	);
	economyRecovery.addCallback(function(_data = null)
	{
		::AlternateDifficulties.DifficultyPolicy.applyEconomyOverrides("setting-change");
	});
	local economyAmmo = economy.addRangeSetting(
		"EconomyAmmoCapacity", 75, 1, 1000, 1,
		"Ammo Capacity",
		"Base maximum ammunition. Lowering it never deletes ammunition already owned."
	);
	economyAmmo.addCallback(function(_data = null)
	{
		::AlternateDifficulties.DifficultyPolicy.applyEconomyOverrides("setting-change");
	});
	local economyMedicine = economy.addRangeSetting(
		"EconomyMedicineCapacity", 38, 1, 1000, 1,
		"Medicine Capacity",
		"Base maximum medical supplies. Lowering it never deletes supplies already owned."
	);
	economyMedicine.addCallback(function(_data = null)
	{
		::AlternateDifficulties.DifficultyPolicy.applyEconomyOverrides("setting-change");
	});
	local economyTools = economy.addRangeSetting(
		"EconomyToolsCapacity", 38, 1, 1000, 1,
		"Tools and Supplies Capacity",
		"Base maximum tools and supplies. Lowering it never deletes supplies already owned."
	);
	economyTools.addCallback(function(_data = null)
	{
		::AlternateDifficulties.DifficultyPolicy.applyEconomyOverrides("setting-change");
	});
	local economyStash = economy.addRangeSetting(
		"EconomyStashCapacity", 21, 1, 500, 1,
		"Stash Capacity",
		"Base stash slots before origin, brother, follower, hand-cart, and wagon bonuses. A lower value never deletes items."
	);
	economyStash.addCallback(function(_data = null)
	{
		::AlternateDifficulties.DifficultyPolicy.applyEconomyOverrides("setting-change");
	});

	local debugLogging = developer.addBooleanSetting(
		"DebugLogging", false,
		"Debug Logging",
		"Write Alternate Difficulties diagnostic lines to log.html."
	);

	debugLogging.addCallback(function(_data = null)
	{
		::AlternateDifficulties.Settings.configureDebugLogging();
	});

	developerLab.addBooleanSetting(
		"EnableDeveloperTestLab", false,
		"Enable Developer Test Lab",
		"Enables the explicit test buttons below. This is intended for a disposable new campaign and never runs automatically."
	);
	developerLab.addRangeSetting(
		"TestRosterLevel", 6, 1, 99, 1,
		"Test roster level",
		"Target level for the explicit Set All Roster Levels button. Brothers already at or above this level are not lowered."
	);
	developerLab.addRangeSetting(
		"TestCrownsAmount", 5000, 100, 50000, 100,
		"Test crowns amount",
		"Exact crowns granted by the explicit Grant Crowns button."
	);
	developerLab.addRangeSetting(
		"TestDaysToAdvance", 100, 1, 365, 1,
		"Test days to advance",
		"Calendar days added by the explicit button. This test-only jump does not replay wages, healing, events, contracts, or other daily processing for every skipped day."
	);
	developerLab.addEnumSetting(
		"TestContractType", "Drive Off Brigands",
		["Drive Off Brigands", "Investigate Cemetery", "Hunt Webknechts", "Hunt Unholds", "Drive Off Nomads"],
		"Test contract type",
		"A normal settlement contract to create through its native faction action when its normal world requirements are met."
	);
	developerLab.addEnumSetting(
		"TestContractSkull", 2, [1, 2, 3, 4],
		"Test contract skull",
		"The fixed 1-4 skull offer applied to the one normal contract generated by the explicit button."
	);
	developerLab.addButtonSetting(
		"ApplyTestRosterLevel", null,
		"Set All Roster Levels",
		"Explicit action: raises current roster brothers to Test roster level. It does not grant equipment or crowns."
	).addCallback(function(_data = null)
	{
		::AlternateDifficulties.DeveloperTestLab.applyRosterLevel();
	});
	developerLab.addButtonSetting(
		"GrantMidTierLoadout", null,
		"Grant Mid-tier Loadout",
		"Explicit action: adds a non-named armor, helmet, axe, hammer, sword, flail, and polearm per current brother to the stash."
	).addCallback(function(_data = null)
	{
		::AlternateDifficulties.DeveloperTestLab.grantMidTierLoadout();
	});
	developerLab.addButtonSetting(
		"GrantTestCrowns", null,
		"Grant Crowns",
		"Explicit action: grants Test crowns amount exactly once for this button press."
	).addCallback(function(_data = null)
	{
		::AlternateDifficulties.DeveloperTestLab.grantCrowns();
	});
	developerLab.addButtonSetting(
		"AdvanceTestCampaignDays", null,
		"Advance Campaign Days",
		"Explicit action: permanently advances the disposable campaign calendar by Test days to advance. It only works outside tactical combat and skips ordinary per-day processing for the skipped period."
	).addCallback(function(_data = null)
	{
		::AlternateDifficulties.DeveloperTestLab.advanceCampaignDays();
	});
	developerLab.addButtonSetting(
		"GenerateSelectedTestContract", null,
		"Generate Selected Normal Contract",
		"Explicit action: creates exactly one selected normal contract at the current settlement, only when the game's native action says it is currently legal."
	).addCallback(function(_data = null)
	{
		::AlternateDifficulties.DeveloperTestLab.generateSelectedNormalContract();
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
