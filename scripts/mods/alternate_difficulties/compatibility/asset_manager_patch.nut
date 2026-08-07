if (!("Compatibility" in ::AlternateDifficulties))
{
	::AlternateDifficulties.Compatibility <- {};
}

::AlternateDifficulties.Compatibility.AssetManager <- {
	function registerHooks( _mod )
	{
		_mod.hook("scripts/states/world/asset_manager", function(q)
		{
			// Keep supplies already held when an existing campaign lowers a capacity.
			// The configured capacity becomes active again after the player spends below it.
			q.getMaxAmmo = @(__original) function()
			{
				return this.Math.max(__original(), this.m.Ammo);
			}

			q.getMaxArmorParts = @(__original) function()
			{
				return this.Math.max(__original(), this.m.ArmorParts);
			}

			q.getMaxMedicine = @(__original) function()
			{
				return this.Math.max(__original(), this.m.Medicine);
			}

			q.setCampaignSettings = @(__original) function( _settings )
			{
				local selectedCombatDifficulty = _settings.Difficulty;
				local selectedEconomicDifficulty = _settings.EconomicDifficulty;
				_settings.Difficulty = ::Const.Difficulty.Normal;
				_settings.EconomicDifficulty = ::Const.Difficulty.Normal;
				__original(_settings);
				::AlternateDifficulties.DifficultyPolicy.normalizeAssets(this);
				::AlternateDifficulties.DifficultyPolicy.applyEconomyOverrides("new-campaign");
				::AlternateDifficulties.Mod.Debug.printLog(
					"[AlternateDifficulties][DifficultyPolicy] normalized new campaign"
					+ " selectedCombat=" + selectedCombatDifficulty
					+ " selectedEconomy=" + selectedEconomicDifficulty
					+ " effective=" + ::Const.Difficulty.Normal
				);
			}

			q.onDeserialize = @(__original) function( _in )
			{
				__original(_in);
				local savedCombatDifficulty = this.m.CombatDifficulty;
				local savedEconomicDifficulty = this.m.EconomicDifficulty;
				::AlternateDifficulties.DifficultyPolicy.normalizeAssets(this);
				::AlternateDifficulties.DifficultyPolicy.applyEconomyOverrides("save-load");
				::AlternateDifficulties.Mod.Debug.printLog(
					"[AlternateDifficulties][DifficultyPolicy] normalized existing save"
					+ " savedCombat=" + savedCombatDifficulty
					+ " savedEconomy=" + savedEconomicDifficulty
					+ " effective=" + ::Const.Difficulty.Normal
				);
			}

			q.getCombatDifficulty = @(__original) function()
			{
				return ::Const.Difficulty.Normal;
			}

			q.getEconomicDifficulty = @(__original) function()
			{
				return ::Const.Difficulty.Normal;
			}

			q.getDifficulty = @(__original) function()
			{
				return ::Const.Difficulty.Normal;
			}

			q.update = @(__original) function( _worldState )
			{
				__original(_worldState);
				::AlternateDifficulties.DifficultyPolicy.reconcileStashCapacity();
			}
		});
	}
};
