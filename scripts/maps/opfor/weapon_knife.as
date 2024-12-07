// weapon_knife Version 1.3
// Custom knife weapon from Opposing Force- created using weapon_hlcrowbar and weapon_csknife from the Counter Strike Weapons Pack by KernCore
// Usage: Primary attack - Normal operation similar to crowbar
// 		  Secondary attack - Stab, does 3.5x the damage as primary but much slower. It can be delayed to time stabs
//		  Tertiary attack - Throws knife
namespace WEAPON_KNIFE
{

enum knife_e
{
	KNIFE_IDLE = 0,
	KNIFE_DRAW,
	KNIFE_HOLSTER,
	KNIFE_ATTACK1,
	KNIFE_ATTACK1MISS,
	KNIFE_ATTACK2,
	KNIFE_ATTACK2HIT,
	KNIFE_ATTACK3,
	KNIFE_ATTACK3HIT,
	KNIFE_IDLE2,
	KNIFE_IDLE3,
	KNIFE_CHARGE,
	KNIFE_STAB
};

const array<string> 
	STR_MDLS =
	{
		"models/opfor/v_knife.mdl",
		"models/opfor/w_knife.mdl",
		"models/opfor/p_knife.mdl",
		"sprites/opfor/weapon_knife.spr"
	},
	STR_SNDS =
	{
		"weapons/knife1.wav",
		"weapons/knife2.wav",
		"weapons/knife3.wav",
		"weapons/knife_hit_wall1.wav",
		"weapons/knife_hit_wall2.wav",
		"weapons/knife_hit_flesh1.wav",
		"weapons/knife_hit_flesh2.wav",
		"weapons/cbar_miss1.wav",
		"weapons/cbe/cbe_idle1.wav",
		"weapons/cbe/cbe_hit1.wav",
		"weapons/cbe/cbe_hit2.wav",
		"weapons/cbe/cbe_hitbod1.wav",
		"weapons/cbe/cbe_hitbod2.wav",
		"weapons/cbe/cbe_hitbod3.wav",
		"weapons/cbe/cbe_miss1.wav",
		"weapons/cbe/cbe_miss2.wav",
		"weapons/cbe/cbe_off.wav",
		"weapons/cbe/cbe_on.wav"
	};

float 
	flDmg = 17,
	flDmg_Sub = 10,
	flDmg_Heavy = 30,
	flDmg_Throw = 30;

array<ItemMapping@> IM_SWAP_KNIFE = 
{ 
	ItemMapping( "weapon_crowbar", "weapon_knife" ),
	ItemMapping( "weapon_hlcrowbar", "weapon_knife" )
};

class weapon_knife : ScriptBasePlayerWeaponEntity
{
	private float m_flBigSwingStart;
	private int m_iSwingMode = 0;
	private bool isPullingBack;
	int m_iSwing;
	TraceResult m_trHit;

	private CBasePlayer@ m_pPlayer
	{
		get const 	{ return cast<CBasePlayer@>( self.m_hPlayer.GetEntity() ); }
		set       	{ self.m_hPlayer = EHandle( @value ); }
	}

	void Spawn()
	{
		if( self.pev.dmg <= 0 )
			self.pev.dmg = flDmg;

		if( self.pev.fuser1 <= 0 )
			self.pev.fuser1 = flDmg_Sub;

		if( self.pev.fuser2 <= 0 )
			self.pev.fuser2 = flDmg_Heavy;

		if( self.pev.fuser3 <= 0 )
			self.pev.fuser3 = flDmg_Throw;

		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( "models/opfor/w_knife.mdl" ) );
		self.m_iClip			= -1;
		self.m_flCustomDmg		= self.pev.dmg;

		self.FallInit();// get ready to fall down.
	}

	void Precache()
	{
		for( uint i = 0; i < STR_MDLS.length(); i++ )
			g_Game.PrecacheModel( STR_MDLS[i] );
		
		g_Game.PrecacheGeneric( "sprites/opfor/weapon_knife.spr" );
		g_Game.PrecacheGeneric( "sprites/opfor/weapon_knife.txt" );
		
		for( uint i = 0; i < STR_SNDS.length(); i++ )
			g_SoundSystem.PrecacheSound( STR_SNDS[i] );

		self.PrecacheCustomModels();
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= -1;
		info.iAmmo1Drop	= -1;
		info.iMaxAmmo2 	= -1;
		info.iAmmo2Drop	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot  	= 0;
		info.iPosition 	= 5;
		info.iId     	= g_ItemRegistry.GetIdForName( self.GetClassname() );
		info.iFlags 	= 0;
		info.iWeight 	= 0;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;

		@m_pPlayer = pPlayer;

		SetThink( null );

		NetworkMessage weapon( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			weapon.WriteLong( self.m_iId );
		weapon.End();

		return true;
	}

	float WeaponTimeBase()
    {
        return g_Engine.time;
    }

	bool Deploy()
	{
		const bool blDeployed = self.DefaultDeploy( self.GetV_Model( "models/opfor/v_knife.mdl" ), self.GetP_Model( "models/opfor/p_knife.mdl" ), KNIFE_DRAW, "crowbar" );
		return blDeployed;
	}

	void Holster( int skipLocal = 0 )
	{
		m_iSwing = 0;
		m_pPlayer.pev.viewmodel = string_t();
		SetThink( null );

		self.m_fInReload = false;
		BaseClass.Holster( skipLocal );
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_iSwingMode > 0 )
		{
			if( m_iSwingMode == 1 )
			{
				HeavySmack();
				m_iSwingMode = 2;
				m_flBigSwingStart = 0;
				isPullingBack = false;
			}
			else
				m_iSwingMode = 0;
		}

		if( m_iSwingMode == 0 )
		{
			m_pPlayer.m_szAnimExtension = "crowbar";
			switch( Math.RandomLong( 0, 2 ) )
			{
				case 0:
					self.SendWeaponAnim( KNIFE_IDLE, 0, 0 );
					self.m_flTimeWeaponIdle = g_Engine.time + 2.69f;
					break;
				case 1:
					self.SendWeaponAnim( KNIFE_IDLE2, 0, 0 );
					self.m_flTimeWeaponIdle = g_Engine.time + 5.33f;
					break;
				case 2:
					self.SendWeaponAnim( KNIFE_IDLE3, 0, 0 );
					self.m_flTimeWeaponIdle = g_Engine.time + 5.33f;
					break;
			}
		}
	}
	
	void PrimaryAttack()
	{
		if( !Swing( 1 ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}

	bool Swing( int fFirst )
	{
		bool fDidHit = false;

		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 32;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if ( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if ( tr.flFraction < 1.0 )
			{
				// Calculate the point of intersection of the line (or hull) and the object we hit
				// This is and approximation of the "best" intersection
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if ( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
				vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
			}
		}

		if ( tr.flFraction >= 1.0 )
		{
			if( fFirst != 0 )
			{
				// miss
				switch( ( m_iSwing++ ) % 3 )
				{
					case 0:
						self.SendWeaponAnim( KNIFE_ATTACK1MISS ); break;
					case 1:
						self.SendWeaponAnim( KNIFE_ATTACK2 ); break;
					case 2:
						self.SendWeaponAnim( KNIFE_ATTACK3 ); break;
				}
				self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
				// play wiff or swish sound
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife3.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

				// player "shoot" animation
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
			}
		}
		else
		{
			// hit
			fDidHit = true;
			
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			switch( ( ( m_iSwing++ ) % 2 ) + 1 )
			{
				case 0:
					self.SendWeaponAnim( KNIFE_ATTACK1 ); break;
				case 1:
					self.SendWeaponAnim( KNIFE_ATTACK2HIT ); break;
				case 2:
					self.SendWeaponAnim( KNIFE_ATTACK3HIT ); break;
			}

			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 

			// AdamR: Custom damage option
			float flDamage = 10;
			if ( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;
			// AdamR: End

			g_WeaponFuncs.ClearMultiDamage();
			if ( self.m_flNextPrimaryAttack + 1 < g_Engine.time )
			{
				// first swing does full damage
				pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB );  
			}
			else
			{
				// subsequent swings do 50% (Changed -Sniper) (Half)
				pEntity.TraceAttack( m_pPlayer.pev, self.pev.fuser1, g_Engine.v_forward, tr, DMG_CLUB );  
			}	
			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			//m_flNextPrimaryAttack = gpGlobals->time + 0.30; //0.25

			// play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				self.m_flNextPrimaryAttack = g_Engine.time + 0.30; //0.25

				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
	// aone
					if( pEntity.IsPlayer() )		// lets pull them
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}
	// end aone
					// play thwack or smack sound
					switch( Math.RandomLong( 0, 2 ) )
					{
						case 0:
							g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_flesh1.wav", 1, ATTN_NORM ); break;
						case 1:
							g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_flesh2.wav", 1, ATTN_NORM ); break;
						case 2:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_flesh1.wav", 1, ATTN_NORM ); break;
					}
					m_pPlayer.m_iWeaponVolume = 128; 
					if( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			// play texture hit sound
			// UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
				
				self.m_flNextPrimaryAttack = g_Engine.time + 0.25; //0.25
				
				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.

				fvolbar = 1;

				// also play knife strike
				switch( Math.RandomLong( 0, 1 ) )
				{
					case 0:
						g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_wall1.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
						break;
					case 1:
						g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_wall2.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
						break;
				}
			}

			// delay the decal a bit
			m_trHit = tr;
			SetThink( ThinkFunction( this.Smack ) );
			self.pev.nextthink = g_Engine.time + 0.2;

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}
		return fDidHit;
	}

	void SecondaryAttack()
	{
		if( m_iSwingMode != 1 )
		{
			self.SendWeaponAnim( KNIFE_CHARGE, 0, 0 );
			m_flBigSwingStart = g_Engine.time;
			self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.7;
			m_iSwingMode = 1;
			isPullingBack = true;
		}
		if( isPullingBack == true && self.m_flTimeWeaponIdle <= g_Engine.time )
		{
			// Manually set wrench windup loop animation
			m_pPlayer.m_Activity = ACT_RELOAD;
			m_pPlayer.pev.frame = 0;
			m_pPlayer.pev.sequence = 26;
			m_pPlayer.ResetSequenceInfo();
			self.m_flNextSecondaryAttack = g_Engine.time + 2.0f;
		}

		m_iSwingMode = 1;
	}
	
	void Smack()
	{
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}

	void SwingAgain()
	{
		Swing( 0 );
	}
	// My humble thanks to KernCore for the secondary attack functions from weapon_csknife code- used in the CS weapons pack :D
	bool HeavySmack()
	{
		bool fDidHit = false;

		TraceResult tr;
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 35;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		if( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if( tr.flFraction < 1.0 )
			{
				EHandle hHit = g_EntityFuncs.Instance( tr.pHit );
				if( hHit.GetEntity() is null || hHit.GetEntity().IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );

				vecEnd = tr.vecEndPos;
			}
		}
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife1.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
		m_pPlayer.m_szAnimExtension = "wrench";
		if( tr.flFraction >= 1.0 )
		{
			self.SendWeaponAnim( KNIFE_STAB, 0, 0 );
			self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.7;
			//Miss
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		}
		else
		{
			//Hit
			fDidHit = true;
			self.SendWeaponAnim( KNIFE_STAB, 0, 0 );
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			EHandle hEntity = g_EntityFuncs.Instance( tr.pHit );

			if( hEntity.GetEntity() !is null )
			{
				g_WeaponFuncs.ClearMultiDamage();
				float flDamage = 35;
				if( self.m_flNextSecondaryAttack + 1 < g_Engine.time )
				{
					hEntity.GetEntity().TraceAttack( m_pPlayer.pev, self.pev.fuser2, g_Engine.v_forward, tr, DMG_CLUB | DMG_NEVERGIB );
				}
				else
				{
					hEntity.GetEntity().TraceAttack( m_pPlayer.pev, self.pev.fuser2 / 2, g_Engine.v_forward, tr, DMG_CLUB | DMG_NEVERGIB );
				}
				g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
			}

			// play thwack, smack, or dong sound
			float flVol = 1.0;
			bool fHitWorld = true;
			if( hEntity.GetEntity() !is null )
			{
				self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.64;
				if( hEntity.GetEntity().Classify() != CLASS_NONE && hEntity.GetEntity().Classify() != CLASS_MACHINE && hEntity.GetEntity().BloodColor() != DONT_BLEED )
				{
					if( hEntity.GetEntity().IsPlayer() ) // lets pull them
					{
						hEntity.GetEntity().pev.velocity = hEntity.GetEntity().pev.velocity + ( self.pev.origin - hEntity.GetEntity().pev.origin ).Normalize() * 120;
					}

					// play thwack or smack sound
					switch( Math.RandomLong( 0, 1 ) )
					{
						case 0:
							g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_flesh1.wav", 1, ATTN_NORM );
							break;
						case 1:
							g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_flesh2.wav", 1, ATTN_NORM ); 
							break;
					}

					m_pPlayer.m_iWeaponVolume = 128;
					if( !hEntity.GetEntity().IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + (vecEnd - vecSrc) * 2, BULLET_PLAYER_CROWBAR );

				// override the volume here, cause we don't play texture sounds in multiplayer, 
				// and fvolbar is going to be 0 from the above call.
				fvolbar = 1;
				// also play crowbar strike
				switch( Math.RandomLong( 0, 1 ) )
				{
					case 0:
						g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_wall1.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
						break;
					case 1:
						g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/knife_hit_wall2.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
						break;
				}
			}
		}

		g_WeaponFuncs.DecalGunshot( g_Utility.GetGlobalTrace(), BULLET_PLAYER_CROWBAR );
		return fDidHit;
	}

	void TertiaryAttack()
	{
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		m_pPlayer.pev.punchangle.x = -2.0f;

		Math.MakeVectors( m_pPlayer.pev.v_angle );

		CBaseEntity@ pTKnife = g_EntityFuncs.Create( "knife_throw", m_pPlayer.pev.origin + g_Engine.v_forward * 16 + g_Engine.v_up * 24, m_pPlayer.pev.v_angle, false, m_pPlayer.edict() );
		if( pTKnife !is null )
		{
			pTKnife.pev.velocity = g_Engine.v_forward * 1024;
			pTKnife.pev.fuser3 = self.pev.fuser3; // damage
			pTKnife.pev.angles = Math.VecToAngles( pTKnife.pev.velocity );
			pTKnife.pev.avelocity.z = 10;

			knife_throw@ pKnife = cast<knife_throw@>(CastToScriptClass(pTKnife));
			pKnife.SetThink( ThinkFunction( pKnife.Think ) );
			pKnife.pev.nextthink = g_Engine.time + 0.1;

			self.m_flNextPrimaryAttack = g_Engine.time + 1.0;
			self.m_flNextSecondaryAttack = g_Engine.time + 1.0;
			self.m_flNextTertiaryAttack = g_Engine.time + 1.0;
			self.m_flTimeWeaponIdle = g_Engine.time + 1.0;

			CBasePlayerItem@ pItem = m_pPlayer.HasNamedPlayerItem( "weapon_knife" );
			if( pItem !is null )
			{
				m_pPlayer.RemovePlayerItem( pItem );
				m_pPlayer.SetItemPickupTimes( 0.0 );
				g_EntityFuncs.Remove( self );
			}
		}
	}

	void DestroyThink()
	{
		g_EntityFuncs.Remove( self );
	}

	void FadeOut()
	{
		pev.nextthink = g_Engine.time + 0.1;

		if( pev.rendermode == kRenderNormal )
		{
			pev.renderamt = 255;
			pev.rendermode = kRenderTransTexture;
		}

		if( pev.renderamt > 7 )
		{
			pev.renderamt -= 7;
		}
		else
		{
			pev.renderamt = 0;
			pev.nextthink = g_Engine.time + 0.1f;
			SetThink( ThinkFunction( this.DestroyThink ) );
			return;
		}
	}
}

class knife_throw : ScriptBaseEntity
{
	private string MODEL = STR_MDLS[2];

	private array<string> pHitSounds =
	{
		"weapons/knife_hit_flesh1.wav",
		"weapons/knife_hit_flesh2.wav"
	};

	private array<string> pHitMissSounds =
	{
		"weapons/knife_hit_wall1.wav",
		"weapons/knife_hit_wall2.wav"
	};

	void Spawn()
	{
		self.pev.movetype = MOVETYPE_BOUNCE;
		self.pev.solid = SOLID_BBOX;

		g_EntityFuncs.SetModel( self, MODEL );

		self.pev.animtime = g_Engine.time;
		self.pev.framerate = 1.0f;
		self.pev.frame = 0.0f;

		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		g_EntityFuncs.SetSize( self.pev, Vector(-3.0, -3.0, -3.0), Vector(3.0, 3.0, 3.0) );
	}

	void Think( void )
	{
		pev.nextthink = g_Engine.time + 0.1;

		if( pev.waterlevel != 0 )
			pev.velocity = pev.velocity * 0.5;

		Vector vecAngle;
		vecAngle = Math.VecToAngles( pev.velocity ); // Angle the knife depending on the velocity
		pev.angles.x = vecAngle.x;
		pev.angles.y = vecAngle.y;
		pev.angles.z += 2.0f;
	}

	void Touch( CBaseEntity@ pOther )
	{
		SetThink( null );
		SetTouch( null );

		if( pOther.pev.takedamage > DAMAGE_NO )
		{
			TraceResult tr = g_Utility.GetGlobalTrace( );

			g_WeaponFuncs.ClearMultiDamage();
			pOther.TraceAttack( pev.owner.vars, self.pev.fuser3, g_Engine.v_forward, tr, DMG_NEVERGIB );  
			g_WeaponFuncs.ApplyMultiDamage( self.pev, pev.owner.vars );

			pev.velocity = g_vecZero;

			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, pHitSounds[Math.RandomLong(0, pHitSounds.length()-1)], 1.0f, ATTN_NORM, 0, PITCH_NORM );
		}
		else
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, pHitMissSounds[Math.RandomLong(0, pHitMissSounds.length()-1)], 1.0f, ATTN_NORM, 0, PITCH_NORM );

			if( pOther.pev.ClassNameIs( "worldspawn" ) )
			{
				// if what we hit is static architecture, can stay around for a while.
				Vector vecDir = pev.velocity.Normalize();
				pev.origin = pev.origin - vecDir * 1;
				pev.solid = SOLID_NOT;
				pev.movetype = MOVETYPE_FLY;
				pev.velocity = g_vecZero;
				pev.avelocity.z = 0;
			}

			if( g_EngineFuncs.PointContents(self.pev.origin) != CONTENTS_WATER )
				g_Utility.Sparks( pev.origin );
		}

		CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity( "weapon_knife", null, false );
		if( pEntity !is null )
		{
			pEntity.pev.fuser3 = self.pev.fuser3;
			g_EntityFuncs.DispatchSpawn( pEntity.edict() );

			weapon_knife@ pKnife = cast<weapon_knife@>(CastToScriptClass(pEntity));
			g_EntityFuncs.SetOrigin( pEntity, self.pev.origin );
			pEntity.pev.spawnflags |= SF_NORESPAWN;

			pEntity.pev.angles.y = pev.angles.y;

			int iWeaponFade = int( g_EngineFuncs.CVarGetFloat( "mp_weaponfadedelay" ) );
			pKnife.SetThink( ThinkFunction( pKnife.FadeOut ) );
			pEntity.pev.nextthink = g_Engine.time + float( iWeaponFade );
		}

		g_EntityFuncs.Remove( self );
		pev.nextthink = g_Engine.time + 0.1;
	}
}

}

void RegisterKnife(bool blReplaceCrowbar = false)
{
	g_CustomEntityFuncs.RegisterCustomEntity( "WEAPON_KNIFE::weapon_knife", "weapon_knife" );
	g_CustomEntityFuncs.RegisterCustomEntity( "WEAPON_KNIFE::knife_throw", "knife_throw" );
	g_ItemRegistry.RegisterWeapon( "weapon_knife", "opfor" );

	if( blReplaceCrowbar )
	{
		g_ClassicMode.SetItemMappings( @WEAPON_KNIFE::IM_SWAP_KNIFE );
		g_ClassicMode.ForceItemRemap( true );
	}
}
// Credit to KernCore for secondary attack functions