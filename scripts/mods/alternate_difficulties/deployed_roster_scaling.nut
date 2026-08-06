if (!("RosterScaling" in ::AlternateDifficulties))
{
	::AlternateDifficulties.RosterScaling <- {};
}

::AlternateDifficulties.RosterScaling.getSnapshot <- function()
{
	local deployedCount = 0;
	local totalLevel = 0.0;
	local deploymentLimit = 0;

	if (!("World" in getroottable())
		|| ::World == null
		|| ::World.Assets == null
		|| ::World.getPlayerRoster() == null)
	{
		return {
			deployedCount = 0,
			averageLevel = 0.0,
			rosterMultiplier = 0.75
		};
	}

	deploymentLimit = ::World.Assets.getBrothersMaxInCombat();
	foreach (bro in ::World.getPlayerRoster().getAll())
	{
		if (bro == null || bro.isInReserves())
		{
			continue;
		}

		if (deployedCount >= deploymentLimit)
		{
			break;
		}

		deployedCount++;
		totalLevel += bro.getLevel();
	}

	local averageLevel = deployedCount == 0 ? 0.0 : totalLevel / deployedCount;
	local countScore = deployedCount / 6.0;
	local levelScore = averageLevel / 6.0;
	local rosterMultiplier = this.Math.minf(1.40, this.Math.maxf(0.75, 0.50 * countScore + 0.50 * levelScore));

	::AlternateDifficulties.Mod.Debug.printLog(
		"[AlternateDifficulties][Roster] deployed=" + deployedCount
		+ " averageLevel=" + averageLevel
		+ " multiplier=" + rosterMultiplier
	);

	return {
		deployedCount = deployedCount,
		averageLevel = averageLevel,
		rosterMultiplier = rosterMultiplier
	};
}

::AlternateDifficulties.RosterScaling.getMultiplier <- function()
{
	return ::AlternateDifficulties.RosterScaling.getSnapshot().rosterMultiplier;
}
