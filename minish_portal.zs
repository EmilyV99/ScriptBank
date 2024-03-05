#option SHORT_CIRCUIT on
#option HEADER_GUARD on
#include "std.zh"

typedef const int CONFIG;
typedef const bool CONFIGB;
typedef const int DEFINE;
typedef const bool DEFINEB;

namespace minishPortals
{
	CONFIG ITEM_MINISH = -1; //The item ID to enable the portals
	CONFIG SFX_ENTER_SCREEN = 0;
	CONFIG SFX_SPARKLE = 0; //An SFX to play when the sparkle is visible
	CONFIG SFX_MINISH_WARP = 0; //The warp SFX for the warp after shrinking
	CONFIG SFX_SHRINK = 0; //Shrink animation sfx
	CONFIG SFX_GROW = 0; //Grow animation sfx
	CONFIG SPARKLE_RADIUS = 60; //How close you have to be to see sparkles
	CONFIG BUTTONPROMPT_COMBO = 0; //Combo to display for the button prompt
	CONFIG BUTTONPROMPT_RADIUS = 60; //How close you have to be to
		//see the button prompt
	CONFIGB BUTTONPROMPT_RELATIVE_TO_HERO = true;
	CONFIG BUTTONPROMPT_X = 6;
	CONFIG BUTTONPROMPT_Y = -8;
	CONFIG BUTTONPROMPT_LAYER = 7;
	CONFIG CB_SHRINK = CB_R;
	
	CONFIG SHRINK_COMBO = 0; //Shrinking animation!
	CONFIG GROW_COMBO = 0; //Growing animation!
	
	//Don't change 'DEFINE' constants!
	DEFINEB BUTTONPROMPT_ANYWHERE = BUTTONPROMPT_RADIUS < 1 || BUTTONPROMPT_RADIUS > 288;
	DEFINEB SPARKLE_ANYWHERE = SPARKLE_RADIUS < 1 || SPARKLE_RADIUS > 288;
	DEFINEB SKIP_DIST = BUTTONPROMPT_ANYWHERE && SPARKLE_ANYWHERE;
	CONST_ASSERT(ITEM_MINISH > -1, "Must set 'ITEM_MINISH' to a valid item ID!");
	CONST_ASSERT(SHRINK_COMBO && GROW_COMBO, "Must set SHRINK_COMBO and GROW_COMBO!");
	
	bool doGrow;
	
	void reset_combo_anim(combodata cd)
	{
		cd->Frame = 0;
		cd->Tile = cd->OriginalTile;
		cd->AClk = 0;
		unless(cd->Frames) cd->Frames = 1;
	}
	
	void run_hero_anim(int cmb)
	{
		combodata cd = Game->LoadComboData(cmb);
		int scrtl = Hero->ScriptTile;
		reset_combo_anim(cd);
		int frames = (cd->ASpeed+1) * cd->Frames;
		Hero->Stun = frames;
		Hero->CollDetection = false;
		do
		{
			Hero->ScriptTile = cd->Tile;
			WaitNoAction();
		}
		while(--frames);
		Hero->ScriptTile = scrtl;
		Hero->Stun = 0;
		Hero->CollDetection = true;
	}
	
	@Author("EmilyV")
	combodata script minishPortal
	{
		/**
		 * Setup: Set the 'CONFIG' values above, and:
		 * Set the 'NEXT' combo to the 'new appearance' of the combo
		 * Set in the combo editor for the script combo...
		 *     InitD[0] = Tile warp index to use (0=A,1=B,...)
		 *     InitD[1] = a COMBO ID for the sparkle animation
		 *
		 * Notes:
		 * The drawn combo effects (sparkles, new appearance, button prompt)
		 *     will be drawn in the CSet the combo is placed in.
		 */
		void run(int warp_ind, int sparkle_cmb)
		{
			if(doGrow)
			{
				doGrow = false;
				if(SFX_GROW) Audio->PlaySound(SFX_GROW);
				run_hero_anim(GROW_COMBO);
			}
			until(Hero->Item[ITEM_MINISH])
				Waitframe();
			if(SFX_ENTER_SCREEN)
				Audio->PlaySound(SFX_ENTER_SCREEN);
			mapdata scr = Game->LoadTempScreen(this->Layer);
			int dist;
			while(true)
			{
				unless(SKIP_DIST)
					dist = Distance(Hero->X, Hero->Y, this->X, this->Y);
				Screen->FastCombo(this->Layer, this->X, this->Y,
					this->ID+1, scr->ComboC[this->Pos], OP_OPAQUE);
				if(SPARKLE_ANYWHERE || dist < SPARKLE_RADIUS)
				{
					if(sparkle_cmb)
						Screen->FastCombo(this->Layer, this->X, this->Y,
							sparkle_cmb, scr->ComboC[this->Pos], OP_OPAQUE);
					if(SFX_SPARKLE)
						Audio->PlaySound(SFX_SPARKLE);
				}
				if(BUTTONPROMPT_ANYWHERE || dist < BUTTONPROMPT_RADIUS)
				{
					if(BUTTONPROMPT_COMBO)
						Screen->FastCombo(BUTTONPROMPT_LAYER,
							BUTTONPROMPT_X + (BUTTONPROMPT_RELATIVE_TO_HERO ? Hero->X : 0),
							BUTTONPROMPT_Y + (BUTTONPROMPT_RELATIVE_TO_HERO ? Hero->Y : 0),
							BUTTONPROMPT_COMBO, scr->ComboC[this->Pos], OP_OPAQUE);
					if(Input->Press[CB_SHRINK])
					{
						if(SFX_SHRINK) Audio->PlaySound(SFX_SHRINK);
						run_hero_anim(SHRINK_COMBO);
						
						Hero->WarpEx({Screen->TileWarpType[warp_ind],
							Screen->TileWarpDMap[warp_ind], Screen->TileWarpScreen[warp_ind],
							-1, Screen->TileWarpReturnSquare[warp_ind], WARPEFFECT_NONE,
							SFX_MINISH_WARP, 0});
					}
				}
				Waitframe();
			}
		}
	}
	
	@Author("EmilyV")
	combodata script minishGrowPortal
	{
		/**
		 * Setup: Set the 'CONFIG' values above, and:
		 * Set in the combo editor for the script combo...
		 *     InitD[0] = Tile warp index to use (0=A,1=B,...)
		 *     InitD[1] = a COMBO ID for the sparkle animation
		 *
		 * Notes:
		 * The drawn combo effects (sparkles, button prompt)
		 *     will be drawn in the CSet the combo is placed in.
		 */
		void run(int warp_ind, int sparkle_cmb)
		{
			mapdata scr = Game->LoadTempScreen(this->Layer);
			int dist;
			while(true)
			{
				unless(SKIP_DIST)
					dist = Distance(Hero->X, Hero->Y, this->X, this->Y);
				if(SPARKLE_ANYWHERE || dist < SPARKLE_RADIUS)
				{
					if(sparkle_cmb)
						Screen->FastCombo(this->Layer, this->X, this->Y,
							sparkle_cmb, scr->ComboC[this->Pos], OP_OPAQUE);
					if(SFX_SPARKLE)
						Audio->PlaySound(SFX_SPARKLE);
				}
				if(BUTTONPROMPT_ANYWHERE || dist < BUTTONPROMPT_RADIUS)
				{
					if(BUTTONPROMPT_COMBO)
						Screen->FastCombo(BUTTONPROMPT_LAYER,
							BUTTONPROMPT_X + (BUTTONPROMPT_RELATIVE_TO_HERO ? Hero->X : 0),
							BUTTONPROMPT_Y + (BUTTONPROMPT_RELATIVE_TO_HERO ? Hero->Y : 0),
							BUTTONPROMPT_COMBO, scr->ComboC[this->Pos], OP_OPAQUE);
					if(Input->Press[CB_SHRINK])
					{
						doGrow = true;
						
						Hero->WarpEx({Screen->TileWarpType[warp_ind],
							Screen->TileWarpDMap[warp_ind], Screen->TileWarpScreen[warp_ind],
							-1, Screen->TileWarpReturnSquare[warp_ind], WARPEFFECT_NONE,
							SFX_MINISH_WARP, 0});
					}
				}
				Waitframe();
			}
		}
	}
}
