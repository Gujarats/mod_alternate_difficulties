if (!("ContractOffers" in ::AlternateDifficulties))
{
	::AlternateDifficulties.ContractOffers <- {};
}

::AlternateDifficulties.ContractOffers.Offers <- [
	{ DifficultyMult = 0.85, PaymentMultiplier = 0.85 },
	{ DifficultyMult = 1.00, PaymentMultiplier = 1.00 },
	{ DifficultyMult = 1.25, PaymentMultiplier = 1.35 },
	{ DifficultyMult = 1.50, PaymentMultiplier = 1.80 }
];

::AlternateDifficulties.ContractOffers.applyNormalContractOffer <- function( _contract )
{
	local offer = ::AlternateDifficulties.ContractOffers.Offers[
		::Math.rand(0, ::AlternateDifficulties.ContractOffers.Offers.len() - 1)
	];
	_contract.m.DifficultyMult = offer.DifficultyMult;

	local contractID = "unknown";
	if ("ID" in _contract.m)
	{
		contractID = _contract.m.ID;
	}

	::AlternateDifficulties.Mod.Debug.printLog(
		"[AlternateDifficulties][ContractOffer] contract=" + contractID
		+ " difficultyMultiplier=" + offer.DifficultyMult
		+ " paymentMultiplier=" + offer.PaymentMultiplier
	);

	return offer;
}

::AlternateDifficulties.ContractOffers.getPaymentMultiplier <- function( _difficultyMult )
{
	foreach (offer in ::AlternateDifficulties.ContractOffers.Offers)
	{
		if (offer.DifficultyMult == _difficultyMult)
		{
			return offer.PaymentMultiplier;
		}
	}

	return _difficultyMult;
}
