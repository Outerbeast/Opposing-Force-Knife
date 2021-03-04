#include "opfor/weapon_knife"

array<ItemMapping@> g_CrowbarToKnife = { ItemMapping( "weapon_crowbar", "weapon_knife" ) };

void MapInit()
{
	EnableKnife();
}

void EnableKnife()
{
	RegisterKnife();
	g_ClassicMode.SetItemMappings( @g_CrowbarToKnife );
    g_ClassicMode.ForceItemRemap( true );
	
	g_Hooks.RegisterHook( Hooks::PickupObject::Materialize, @ItemSpawned );
}

HookReturnCode ItemSpawned( CBaseEntity@ pOldItem ) 
{
	for( uint w = 0; w < g_CrowbarToKnife.length(); ++w )
	{
		if( pOldItem.GetClassname() == g_CrowbarToKnife[w].get_From() )
		{
			CBaseEntity@ pNewItem = g_EntityFuncs.Create( g_CrowbarToKnife[w].get_To(), pOldItem.GetOrigin(), pOldItem.pev.angles, false );
			if( pNewItem is null ) 
				return HOOK_CONTINUE;

			pNewItem.pev.movetype = pOldItem.pev.movetype;

			if( pOldItem.GetTargetname() != "" )
				g_EntityFuncs.DispatchKeyValue( pNewItem.edict(), "targetname", pOldItem.GetTargetname() );

			if( pOldItem.pev.target != "" )
				g_EntityFuncs.DispatchKeyValue( pNewItem.edict(), "target", pOldItem.pev.target );

			if( pOldItem.pev.netname != "" )
				g_EntityFuncs.DispatchKeyValue( pNewItem.edict(), "netname", pOldItem.pev.netname );
			
			g_EntityFuncs.Remove( pOldItem );
		}
	}
	return HOOK_HANDLED;
}
