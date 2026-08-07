if (!("DeveloperTestLab" in ::AlternateDifficulties))
{
	::AlternateDifficulties.DeveloperTestLab <- {};
}

// The listed actions are ordinary settlement contracts. The Test Lab calls the
// game's own action only after the action says it is currently legal, then changes
// the just-created offer to the explicitly selected skull.
::AlternateDifficulties.DeveloperTestLab.ContractActions <- [
	{ Label = "Drive Off Brigands", ActionID = "drive_away_bandits_action" },
	{ Label = "Investigate Cemetery", ActionID = "investigate_cemetery_action" },
	{ Label = "Hunt Webknechts", ActionID = "hunting_webknechts_action" },
	{ Label = "Hunt Unholds", ActionID = "hunting_unholds_action" },
	{ Label = "Drive Off Nomads", ActionID = "drive_away_nomads_action" }
];

::AlternateDifficulties.DeveloperTestLab.MidTierItems <- [
	"scripts/items/armor/mail_hauberk",
	"scripts/items/helmets/nasal_helmet_with_mail",
	"scripts/items/weapons/hand_axe",
	"scripts/items/weapons/warhammer",
	"scripts/items/weapons/arming_sword",
	"scripts/items/weapons/flail",
	"scripts/items/weapons/billhook"
];

::AlternateDifficulties.DeveloperTestLab.isEnabled <- function()
{
	return ::AlternateDifficulties.Mod.ModSettings.getSetting("EnableDeveloperTestLab").getValue();
}

::AlternateDifficulties.DeveloperTestLab.logWarning <- function( _message )
{
	local message = "[AlternateDifficulties][TestLab] " + _message;
	::logWarning(message);
	::AlternateDifficulties.Mod.Debug.printLog(message);
}

::AlternateDifficulties.DeveloperTestLab.getSelectedActionID <- function()
{
	local selectedLabel = ::AlternateDifficulties.Mod.ModSettings.getSetting("TestContractType").getValue();

	foreach (entry in ::AlternateDifficulties.DeveloperTestLab.ContractActions)
	{
		if (entry.Label == selectedLabel)
		{
			return entry.ActionID;
		}
	}

	return null;
}

::AlternateDifficulties.DeveloperTestLab.findAction <- function( _faction, _actionID )
{
	foreach (action in _faction.m.Deck)
	{
		if (action.getID() == _actionID)
		{
			return action;
		}
	}

	return null;
}

::AlternateDifficulties.DeveloperTestLab.applyRosterLevel <- function()
{
	if (!::AlternateDifficulties.DeveloperTestLab.isEnabled())
	{
		::AlternateDifficulties.DeveloperTestLab.logWarning("Set roster level ignored because the Test Lab is disabled.");
		return;
	}

	local targetLevel = ::AlternateDifficulties.Mod.ModSettings.getSetting("TestRosterLevel").getValue();
	targetLevel = ::Math.max(1, ::Math.min(targetLevel, ::Const.LevelXP.len()));
	local changedCount = 0;

	foreach (bro in ::World.getPlayerRoster().getAll())
	{
		if (bro.getLevel() >= targetLevel)
		{
			continue;
		}

		bro.addXP(::Const.LevelXP[targetLevel - 1] - bro.m.XP, false);
		bro.updateLevel();
		bro.getSkills().update();
		changedCount = ++changedCount;
	}

	::AlternateDifficulties.Mod.Debug.printLog(
		"[AlternateDifficulties][TestLab] raised " + changedCount + " brothers to level " + targetLevel
	);
}

::AlternateDifficulties.DeveloperTestLab.grantMidTierLoadout <- function()
{
	if (!::AlternateDifficulties.DeveloperTestLab.isEnabled())
	{
		::AlternateDifficulties.DeveloperTestLab.logWarning("Grant loadout ignored because the Test Lab is disabled.");
		return;
	}

	local brotherCount = ::World.getPlayerRoster().getAll().len();
	local stash = ::World.Assets.getStash();
	local requiredSlots = brotherCount * ::AlternateDifficulties.DeveloperTestLab.MidTierItems.len();

	if (stash.getNumberOfEmptySlots() < requiredSlots)
	{
		::AlternateDifficulties.DeveloperTestLab.logWarning(
			"Grant loadout ignored because the stash needs " + requiredSlots + " empty slots."
		);
		return;
	}

	foreach (itemScript in ::AlternateDifficulties.DeveloperTestLab.MidTierItems)
	{
		for (local i = 0; i < brotherCount; i = ++i)
		{
			stash.add(::new(itemScript));
		}

		::AlternateDifficulties.Mod.Debug.printLog(
			"[AlternateDifficulties][TestLab] granted item=" + itemScript + " count=" + brotherCount
		);
	}
}

::AlternateDifficulties.DeveloperTestLab.grantCrowns <- function()
{
	if (!::AlternateDifficulties.DeveloperTestLab.isEnabled())
	{
		::AlternateDifficulties.DeveloperTestLab.logWarning("Grant crowns ignored because the Test Lab is disabled.");
		return;
	}

	local crowns = ::AlternateDifficulties.Mod.ModSettings.getSetting("TestCrownsAmount").getValue();
	::World.Assets.addMoney(crowns);
	::World.State.updateTopbarAssets();
	::AlternateDifficulties.Mod.Debug.printLog(
		"[AlternateDifficulties][TestLab] granted crowns=" + crowns
	);
}

// This intentionally changes only the calendar value for a disposable test
// campaign. Battle Brothers does not expose a way for a mod to replay every
// skipped daily world update, so wages, healing, events, and similar systems
// are not processed once per jumped day.
// NOTES : DOES NOT WORK!!!!
::AlternateDifficulties.DeveloperTestLab.advanceCampaignDays <- function()
{
	if (!::AlternateDifficulties.DeveloperTestLab.isEnabled())
	{
		::AlternateDifficulties.DeveloperTestLab.logWarning("Advance campaign days ignored because the Test Lab is disabled.");
		return;
	}

	if (::World == null || ::World.State == null || ("Tactical" in getroottable() && "State" in ::Tactical && ::Tactical.State != null))
	{
		::AlternateDifficulties.DeveloperTestLab.logWarning("Advance campaign days requires the world map outside tactical combat.");
		return;
	}

	local days = ::AlternateDifficulties.Mod.ModSettings.getSetting("TestDaysToAdvance").getValue();
	local startingDay = ::World.getTime().Days;
	::Time.setVirtualTime(::Time.getVirtualTimeF() + days * ::World.getTime().SecondsPerDay);
	::World.State.updateDayTime();
	local finalDay = ::World.getTime().Days;

	::AlternateDifficulties.Mod.Debug.printLog(
		"[AlternateDifficulties][TestLab] advanced campaign days startingDay=" + startingDay
		+ " requestedDays=" + days
		+ " finalDay=" + finalDay
		+ " (calendar jump; daily processing was not replayed)"
	);
}

::AlternateDifficulties.DeveloperTestLab.generateSelectedNormalContract <- function()
{
	if (!::AlternateDifficulties.DeveloperTestLab.isEnabled())
	{
		::AlternateDifficulties.DeveloperTestLab.logWarning("Generate contract ignored because the Test Lab is disabled.");
		return;
	}

	local town = ::World.State.getCurrentTown();
	if (town == null)
	{
		::AlternateDifficulties.DeveloperTestLab.logWarning("Generate contract requires the player to be inside a settlement.");
		return;
	}

	local actionID = ::AlternateDifficulties.DeveloperTestLab.getSelectedActionID();
	if (actionID == null)
	{
		::AlternateDifficulties.DeveloperTestLab.logWarning("The selected Test Lab contract type is not supported.");
		return;
	}

	local action = null;
	local faction = null;
	foreach (factionID in town.getFactions())
	{
		local candidateFaction = ::World.FactionManager.getFaction(factionID);
		if (candidateFaction == null || candidateFaction.getSettlements().len() == 0
			|| candidateFaction.getSettlements()[0].getID() != town.getID())
		{
			continue;
		}

		local candidateAction = ::AlternateDifficulties.DeveloperTestLab.findAction(candidateFaction, actionID);
		if (candidateAction != null)
		{
			action = candidateAction;
			faction = candidateFaction;
			break;
		}
	}

	if (action == null)
	{
		::AlternateDifficulties.DeveloperTestLab.logWarning(
			"The selected contract is not legal for " + town.getName() + "."
		);
		return;
	}

	// update() runs the action's native legality checks without creating a contract.
	action.update();
	if (action.getScore() <= 0)
	{
		::AlternateDifficulties.DeveloperTestLab.logWarning(
			"The selected contract's world requirements are not currently met at " + town.getName() + "."
		);
		return;
	}

	local existingCount = ::World.Contracts.getOpenContracts().len();
	action.execute();
	local openContracts = ::World.Contracts.getOpenContracts();
	if (openContracts.len() != existingCount + 1)
	{
		::AlternateDifficulties.DeveloperTestLab.logWarning("The native contract action did not create an offer.");
		return;
	}

	local contract = openContracts[openContracts.len() - 1];
	if (!::AlternateDifficulties.ContractOffers.isNormalContract(contract))
	{
		::AlternateDifficulties.DeveloperTestLab.logWarning("The native action created a non-normal contract; its authored difficulty was kept.");
		return;
	}

	local skull = ::AlternateDifficulties.Mod.ModSettings.getSetting("TestContractSkull").getValue();
	local offer = ::AlternateDifficulties.ContractOffers.getOfferForSkull(skull);
	if (offer == null)
	{
		::AlternateDifficulties.DeveloperTestLab.logWarning("The selected Test Lab skull is invalid.");
		return;
	}

	contract.m.DifficultyMult = offer.DifficultyMult;
	::AlternateDifficulties.Mod.Debug.printLog(
		"[AlternateDifficulties][TestLab] generated settlement=" + town.getName()
		+ " contract=" + contract.getType()
		+ " skull=" + skull
		+ " difficultyMultiplier=" + offer.DifficultyMult
	);
}
