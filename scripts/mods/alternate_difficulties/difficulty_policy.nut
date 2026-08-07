if (!("DifficultyPolicy" in ::AlternateDifficulties))
{
	::AlternateDifficulties.DifficultyPolicy <- {};
}

::AlternateDifficulties.DifficultyPolicy.Normal <- ::Const.Difficulty.Normal;
::AlternateDifficulties.DifficultyPolicy.LastDeferredStashCapacity <- null;

::AlternateDifficulties.DifficultyPolicy.getCombatMultiplier <- function()
{
	return ::AlternateDifficulties.Mod.ModSettings
		.getSetting("CustomDifficultyMultiplier")
		.getValue();
}

::AlternateDifficulties.DifficultyPolicy.getEconomyValue <- function( _id )
{
	return ::AlternateDifficulties.Mod.ModSettings.getSetting(_id).getValue();
}

// Battle Brothers represents difficulty as a small integer index (Easy = 0,
// Normal = 1, Hard = 2, Legendary = 3), not as a free-form multiplier.
//
// The game and Legends use that index in arrays and switches, for example:
// Const.Difficulty.SellPriceMult[World.Assets.getEconomicDifficulty()]. A
// custom value such as 0.925 cannot be returned from that getter because it
// would be used as an invalid array index.
//
// Alternate Difficulties therefore uses Normal as a safe engine-facing slot,
// then writes this mod's slider values into that slot. This function also sets
// the stored fields because some Legends code reads m.CombatDifficulty or
// m.EconomicDifficulty directly instead of using the getters. The result is
// that the original menu choices are ignored for both new games and saves,
// while the actual behavior comes from the mod's policy settings.
::AlternateDifficulties.DifficultyPolicy.normalizeAssets <- function( _assets )
{
	if (_assets == null)
	{
		return;
	}

	_assets.m.CombatDifficulty = this.Normal;
	_assets.m.EconomicDifficulty = this.Normal;
}

::AlternateDifficulties.DifficultyPolicy.getOriginStashModifier <- function()
{
	if (!("World" in getroottable())
		|| ::World == null
		|| ::World.Assets == null
		|| ::World.Assets.getOrigin() == null)
	{
		return 0;
	}

	return ::World.Assets.getOrigin().getStashModifier();
}

::AlternateDifficulties.DifficultyPolicy.applyEconomyOverrides <- function( _reason )
{
	local normal = this.Normal;
	local shopCost = this.getEconomyValue("EconomyShopCostMultiplier");
	local sellLoot = this.getEconomyValue("EconomySellLootMultiplier");
	local contractPayment = this.getEconomyValue("EconomyContractPaymentMultiplier");
	local minimumPayment = this.getEconomyValue("EconomyMinimumPayment");
	local minimumPerHeadPayment = this.getEconomyValue("EconomyMinimumPerHeadPayment");
	local recovery = this.getEconomyValue("EconomyRecoveryMultiplier");
	local ammo = this.getEconomyValue("EconomyAmmoCapacity");
	local medicine = this.getEconomyValue("EconomyMedicineCapacity");
	local tools = this.getEconomyValue("EconomyToolsCapacity");
	local stash = this.getEconomyValue("EconomyStashCapacity");

	::Const.Difficulty.BuyPriceMult[normal] = shopCost;
	::Const.Difficulty.SellPriceMult[normal] = sellLoot;
	::Const.Difficulty.PaymentMult[normal] = contractPayment;
	::Const.Difficulty.MinPayments[normal] = minimumPayment;
	::Const.Difficulty.MinHeadPayments[normal] = minimumPerHeadPayment;
	::Const.Difficulty.HealMult[normal] = recovery;
	::Const.Difficulty.RepairMult[normal] = recovery;
	::Const.Difficulty.MaxResources[normal].Ammo = ammo;
	::Const.Difficulty.MaxResources[normal].Medicine = medicine;
	::Const.Difficulty.MaxResources[normal].ArmorParts = tools;
	::Const.LegendMod.MaxResources[normal].Ammo = ammo;
	::Const.LegendMod.MaxResources[normal].Medicine = medicine;
	::Const.LegendMod.MaxResources[normal].ArmorParts = tools;
	::Const.LegendMod.MaxResources[normal].Stash = stash;

	this.reconcileStashCapacity();

	::AlternateDifficulties.Mod.Debug.printLog(
		"[AlternateDifficulties][EconomyPolicy] reason=" + _reason
		+ " shopCost=" + shopCost
		+ " sellLoot=" + sellLoot
		+ " contractPayment=" + contractPayment
		+ " minimumPayment=" + minimumPayment
		+ " minimumPerHeadPayment=" + minimumPerHeadPayment
		+ " recovery=" + recovery
		+ " ammo=" + ammo
		+ " medicine=" + medicine
		+ " tools=" + tools
		+ " stash=" + stash
	);
}

::AlternateDifficulties.DifficultyPolicy.reconcileStashCapacity <- function()
{
	if (!("World" in getroottable())
		|| ::World == null
		|| ::World.Assets == null
		|| ::World.getPlayerRoster() == null
		|| !("Legends" in getroottable())
		|| !("Stash" in ::Legends))
	{
		return;
	}

	local stash = ::World.Assets.getStash();
	if (stash == null)
	{
		return;
	}

	local baseCapacity = this.getEconomyValue("EconomyStashCapacity") + this.getOriginStashModifier();
	::World.Flags.set(::Legends.Stash.Flags.StartingSize, baseCapacity);

	local requestedCapacity = ::Legends.Stash.getSize();
	local currentCapacity = stash.getCapacity();
	local filledSlots = stash.getNumberOfFilledSlots();

	if (requestedCapacity >= currentCapacity)
	{
		stash.resize(requestedCapacity);
		this.LastDeferredStashCapacity = null;
		return;
	}

	if (filledSlots > requestedCapacity)
	{
		if (this.LastDeferredStashCapacity != requestedCapacity)
		{
			::AlternateDifficulties.Mod.Debug.printLog(
				"[AlternateDifficulties][EconomyPolicy] deferred stash reduction requested=" + requestedCapacity
				+ " current=" + currentCapacity
				+ " filled=" + filledSlots
			);
			this.LastDeferredStashCapacity = requestedCapacity;
		}
		return;
	}

	stash.sort();
	stash.resize(requestedCapacity);
	this.LastDeferredStashCapacity = null;
}
