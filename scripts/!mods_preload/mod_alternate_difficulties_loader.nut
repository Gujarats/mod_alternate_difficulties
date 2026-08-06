::AlternateDifficulties <- {
	ID = "mod_alternate_difficulties",
	Name = "Alternate Difficulties",
	Version = "0.1.0"
};

::AlternateDifficulties.HookMod <- ::Hooks.register(
	::AlternateDifficulties.ID,
	::AlternateDifficulties.Version,
	::AlternateDifficulties.Name
);
::AlternateDifficulties.HookMod.require("mod_msu >= 1.9.0");

::include("scripts/mods/alternate_difficulties/settings");
::include("scripts/mods/alternate_difficulties/deployed_roster_scaling");
::include("scripts/mods/alternate_difficulties/contract_skull_offers");
::include("scripts/mods/alternate_difficulties/developer_test_lab");
::include("scripts/mods/alternate_difficulties/compatibility/legends_contract_patch");
::include("scripts/mods/alternate_difficulties/compatibility/legends_dynamic_troop_patch");

::AlternateDifficulties.HookMod.queue(">mod_msu", ">mod_legends", function()
{
	::AlternateDifficulties.Mod <- ::MSU.Class.Mod(
		::AlternateDifficulties.ID,
		::AlternateDifficulties.Version,
		::AlternateDifficulties.Name
	);

	::AlternateDifficulties.Settings.register();
	::AlternateDifficulties.Compatibility.LegendsContract.registerHooks(::AlternateDifficulties.HookMod);
	::AlternateDifficulties.Compatibility.DynamicTroops.register();
	::AlternateDifficulties.Mod.Debug.printLog("[AlternateDifficulties] initialized after MSU and Legends");
});
