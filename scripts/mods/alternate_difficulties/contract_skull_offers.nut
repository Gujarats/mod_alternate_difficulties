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

// This allow-list is intentionally conservative. A contract outside it keeps the
// difficulty authored by its own script until it has been reviewed explicitly.
::AlternateDifficulties.ContractOffers.NormalContractTypes <- [
	"contract.destroy_goblin_camp",
	"contract.destroy_orc_camp",
	"contract.drive_away_bandits",
	"contract.drive_away_barbarians",
	"contract.drive_away_nomads",
	"contract.free_greenskin_prisoners",
	"contract.hunting_alps",
	"contract.hunting_hexen",
	"contract.hunting_sandgolems",
	"contract.hunting_schrats",
	"contract.hunting_serpents",
	"contract.hunting_unholds",
	"contract.hunting_webknechts",
	"contract.investigate_cemetery",
	"contract.return_item",
	"contract.roaming_beasts",
	"contract.roaming_beasts_desert"
];

::AlternateDifficulties.ContractOffers.isNormalContract <- function( _contract )
{
	local contractType = _contract.getType();

	foreach (normalType in ::AlternateDifficulties.ContractOffers.NormalContractTypes)
	{
		if (contractType == normalType)
		{
			return true;
		}
	}

	return false;
}

::AlternateDifficulties.ContractOffers.getOfferForSkull <- function( _skull )
{
	local index = _skull - 1;

	if (index < 0 || index >= ::AlternateDifficulties.ContractOffers.Offers.len())
	{
		return null;
	}

	return ::AlternateDifficulties.ContractOffers.Offers[index];
}

::AlternateDifficulties.ContractOffers.applyNormalContractOffer <- function( _contract )
{
	if (!::AlternateDifficulties.ContractOffers.isNormalContract(_contract))
	{
		::AlternateDifficulties.Mod.Debug.printLog(
			"[AlternateDifficulties][ContractOffer] keeping authored difficulty for " + _contract.getType()
		);
		return null;
	}

	local offer = ::AlternateDifficulties.ContractOffers.Offers[
		::Math.rand(0, ::AlternateDifficulties.ContractOffers.Offers.len() - 1)
	];
	_contract.m.DifficultyMult = offer.DifficultyMult;

	::AlternateDifficulties.Mod.Debug.printLog(
		"[AlternateDifficulties][ContractOffer] contract=" + _contract.getType()
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
