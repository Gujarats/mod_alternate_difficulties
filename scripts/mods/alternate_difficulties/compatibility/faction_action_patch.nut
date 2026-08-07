if (!("Compatibility" in ::AlternateDifficulties))
{
	::AlternateDifficulties.Compatibility <- {};
}

::AlternateDifficulties.Compatibility.FactionAction <- {
	function registerHooks( _mod )
	{
		_mod.hook("scripts/factions/faction_action", function(q)
		{
			q.getScaledDifficultyMult = @(__original) function()
			{
				local snapshot = ::AlternateDifficulties.RosterScaling.getSnapshot();
				local customMultiplier = ::AlternateDifficulties.DifficultyPolicy.getCombatMultiplier();
				local finalMultiplier = snapshot.rosterMultiplier * customMultiplier;
				::AlternateDifficulties.Mod.Debug.printLog(
					"[AlternateDifficulties][FactionActionScaling] helper=getScaledDifficultyMult"
					+ " deployed=" + snapshot.deployedCount
					+ " averageLevel=" + snapshot.averageLevel
					+ " rosterMultiplier=" + snapshot.rosterMultiplier
					+ " customMultiplier=" + customMultiplier
					+ " finalMultiplier=" + finalMultiplier
				);
				return finalMultiplier;
			}

			q.getReputationToDifficultyLightMult = @(__original) function()
			{
				local snapshot = ::AlternateDifficulties.RosterScaling.getSnapshot();
				local customMultiplier = ::AlternateDifficulties.DifficultyPolicy.getCombatMultiplier();
				local finalMultiplier = snapshot.rosterMultiplier * customMultiplier;
				::AlternateDifficulties.Mod.Debug.printLog(
					"[AlternateDifficulties][FactionActionScaling] helper=getReputationToDifficultyLightMult"
					+ " deployed=" + snapshot.deployedCount
					+ " averageLevel=" + snapshot.averageLevel
					+ " rosterMultiplier=" + snapshot.rosterMultiplier
					+ " customMultiplier=" + customMultiplier
					+ " finalMultiplier=" + finalMultiplier
				);
				return finalMultiplier;
			}
		});
	}
};
