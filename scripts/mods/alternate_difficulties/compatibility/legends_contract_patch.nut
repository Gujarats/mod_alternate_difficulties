if (!("Compatibility" in ::AlternateDifficulties))
{
	::AlternateDifficulties.Compatibility <- {};
}

::AlternateDifficulties.Compatibility.LegendsContract <- {
	function registerHooks( _mod )
	{
		_mod.hook("scripts/contracts/contract", function(q)
		{
			q.create = @(__original) function()
			{
				__original();
				::AlternateDifficulties.ContractOffers.applyNormalContractOffer(this);
			}

			q.getScaledDifficultyMult = function()
			{
				local snapshot = ::AlternateDifficulties.RosterScaling.getSnapshot();
				local customDifficultyMultiplier = ::AlternateDifficulties.Mod.ModSettings
					.getSetting("CustomDifficultyMultiplier")
					.getValue();
				local finalMultiplier = snapshot.rosterMultiplier * customDifficultyMultiplier;

				::AlternateDifficulties.Mod.Debug.printLog(
					"[AlternateDifficulties][ContractScaling] deployed=" + snapshot.deployedCount
					+ " averageLevel=" + snapshot.averageLevel
					+ " rosterMultiplier=" + snapshot.rosterMultiplier
					+ " customDifficultyMultiplier=" + customDifficultyMultiplier
					+ " finalMultiplier=" + finalMultiplier
				);

				return finalMultiplier;
			}

			q.getPaymentMult = function()
			{
				local repDiffMult = this.Math.pow(this.getScaledDifficultyMult(), 0.5);
				local broMult = this.World.State.getPlayer().getBarterMult();
				local paymentMultiplier = ::AlternateDifficulties.ContractOffers.getPaymentMultiplier(this.m.DifficultyMult);

				return (this.m.PaymentMult + broMult)
					* (paymentMultiplier * repDiffMult)
					* this.World.Assets.m.ContractPaymentMult;
			}
		});
	}
};
