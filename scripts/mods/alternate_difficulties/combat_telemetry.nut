if (!("CombatTelemetry" in ::AlternateDifficulties))
{
	::AlternateDifficulties.CombatTelemetry <- {};
}

// Read-only diagnostics for checking how a roster and a spawned combat relate.
// These functions never change a roster, contract, party, or tactical actor.
::AlternateDifficulties.CombatTelemetry.getActorScript <- function( _actor )
{
	return "ClassNameHash" in _actor ? ::IO.scriptFilenameByHash(_actor.ClassNameHash) : "unknown";
}

::AlternateDifficulties.CombatTelemetry.logRoster <- function( _reason, _snapshot, _customMultiplier )
{
	local reserveCount = 0;
	local brotherCount = 0;
	local combatDifficulty = "unknown";
	local economicDifficulty = "unknown";

	if (::World != null && ::World.Assets != null)
	{
		combatDifficulty = ::World.Assets.getCombatDifficulty();
		economicDifficulty = ::World.Assets.getEconomicDifficulty();
	}

	if (::World != null && ::World.getPlayerRoster() != null)
	{
		foreach (bro in ::World.getPlayerRoster().getAll())
		{
			local isReserve = bro.isInReserves();
			brotherCount = ++brotherCount;
			if (isReserve)
			{
				reserveCount = ++reserveCount;
			}

			::AlternateDifficulties.Mod.Debug.printLog(
				"[AlternateDifficulties][Telemetry][Brother] reason=" + _reason
				+ " name=" + bro.getName()
				+ " level=" + bro.getLevel()
				+ " reserve=" + isReserve
			);
		}
	}

	local finalMultiplier = _snapshot.rosterMultiplier * _customMultiplier;
	local shopCost = ::AlternateDifficulties.DifficultyPolicy.getEconomyValue("EconomyShopCostMultiplier");
	local sellLoot = ::AlternateDifficulties.DifficultyPolicy.getEconomyValue("EconomySellLootMultiplier");
	local contractPayment = ::AlternateDifficulties.DifficultyPolicy.getEconomyValue("EconomyContractPaymentMultiplier");
	local recovery = ::AlternateDifficulties.DifficultyPolicy.getEconomyValue("EconomyRecoveryMultiplier");
	::AlternateDifficulties.Mod.Debug.printLog(
		"[AlternateDifficulties][Telemetry][Roster] reason=" + _reason
		+ " brothers=" + brotherCount
		+ " reserves=" + reserveCount
		+ " deployed=" + _snapshot.deployedCount
		+ " averageLevel=" + _snapshot.averageLevel
		+ " rosterMultiplier=" + _snapshot.rosterMultiplier
		+ " customMultiplier=" + _customMultiplier
		+ " finalMultiplier=" + finalMultiplier
		+ " effectiveCombatDifficulty=" + combatDifficulty
		+ " effectiveEconomicDifficulty=" + economicDifficulty
		+ " policyShopCost=" + shopCost
		+ " policySellLoot=" + sellLoot
		+ " policyContractPayment=" + contractPayment
		+ " policyRecovery=" + recovery
	);
}

::AlternateDifficulties.CombatTelemetry.logContract <- function( _contract )
{
	local paymentMultiplier = ::AlternateDifficulties.ContractOffers.getPaymentMultiplier(_contract.m.DifficultyMult);
	::AlternateDifficulties.Mod.Debug.printLog(
		"[AlternateDifficulties][Telemetry][Contract] type=" + _contract.getType()
		+ " skullMultiplier=" + _contract.m.DifficultyMult
		+ " skullPaymentMultiplier=" + paymentMultiplier
		+ " economyPaymentMultiplier=" + ::AlternateDifficulties.DifficultyPolicy.getEconomyValue("EconomyContractPaymentMultiplier")
	);
}

::AlternateDifficulties.CombatTelemetry.logCombatSnapshot <- function()
{
	if (!("Tactical" in getroottable()) || ::Tactical.Entities == null)
	{
		return;
	}

	local snapshot = ::AlternateDifficulties.RosterScaling.getSnapshot();
	local customMultiplier = ::AlternateDifficulties.Mod.ModSettings
		.getSetting("CustomDifficultyMultiplier")
		.getValue();
	::AlternateDifficulties.CombatTelemetry.logRoster("combat-start", snapshot, customMultiplier);

	local playerCount = 0;
	local alliedCount = 0;
	local enemyCount = 0;
	local neutralCount = 0;
	local types = {};

	foreach (factionActors in ::Tactical.Entities.getAllInstances())
	{
		foreach (actor in factionActors)
		{
			if (!("getFaction" in actor) || !("getHitpoints" in actor))
			{
				continue;
			}

			local relationship = "enemy";
			if (actor.isPlayerControlled())
			{
				relationship = "player";
				playerCount = ++playerCount;
			}
			else if (actor.isAlliedWithPlayer())
			{
				relationship = "ally";
				alliedCount = ++alliedCount;
			}
			else if (actor.getFaction() == ::Const.Faction.Neutral)
			{
				relationship = "neutral";
				neutralCount = ++neutralCount;
			}
			else
			{
				enemyCount = ++enemyCount;
			}

			if (relationship == "player")
			{
				continue;
			}

			local actorScript = ::AlternateDifficulties.CombatTelemetry.getActorScript(actor);
			if (!(actorScript in types))
			{
				types[actorScript] <- 0;
			}
			types[actorScript] = ++types[actorScript];

			local miniboss = actor.m.IsMiniboss;
			::AlternateDifficulties.Mod.Debug.printLog(
				"[AlternateDifficulties][Telemetry][Actor] relationship=" + relationship
				+ " script=" + actorScript
				+ " name=" + actor.getName()
				+ " faction=" + actor.getFaction()
				+ " level=" + actor.getLevel()
				+ " hitpoints=" + actor.getHitpoints() + "/" + actor.getHitpointsMax()
				+ " bodyArmor=" + actor.getArmor(::Const.BodyPart.Body) + "/" + actor.getArmorMax(::Const.BodyPart.Body)
				+ " headArmor=" + actor.getArmor(::Const.BodyPart.Head) + "/" + actor.getArmorMax(::Const.BodyPart.Head)
				+ " miniboss=" + miniboss
			);
		}
	}

	::AlternateDifficulties.Mod.Debug.printLog(
		"[AlternateDifficulties][Telemetry][Combat] player=" + playerCount
		+ " allies=" + alliedCount
		+ " enemies=" + enemyCount
		+ " neutral=" + neutralCount
	);

	foreach (actorScript, count in types)
	{
		::AlternateDifficulties.Mod.Debug.printLog(
			"[AlternateDifficulties][Telemetry][Type] script=" + actorScript + " count=" + count
		);
	}
}

::AlternateDifficulties.CombatTelemetry.registerHooks <- function( _mod )
{
	_mod.hook("scripts/states/tactical_state", function(q)
	{
		q.init = @(__original) function()
		{
			__original();
			::AlternateDifficulties.CombatTelemetry.logCombatSnapshot();
		}
	});
}
