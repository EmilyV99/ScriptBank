#include "std.zh"

CONFIG TILE_INVIS = 5;
CONST_ASSERT(TILE_INVIS > -1 && TILE_INVIS <= MAX_TILES);

//NOTES: QR "Scripts Draw During Warps" must be enabled

@InitD0("Pitfall ID"),
@InitDHelp0("The combo ID of the 'Pitfall' combo to use for the bottom of the screen")
screendata script SideviewPit
{
    void run(int pitcmb)
    {
		bool is_warp;
        if(pitcmb > -1 && pitcmb <= MAX_COMBOS)
        {
            combodata pit = Game->LoadComboData(pitcmb);
            if(pit->Type != CT_PITFALL)
            	pitcmb = -1;
			else
				is_warp = pit->Flags[0];
        }
        set_bottom_cancelwarp();
        while(true) //loop while onscreen
        {
            int fall;
            do //wait for player to fall
            {
                fall = -Hero->Jump;
                Waitframe();
            } while(Hero->Y < 160);
            int tile = Hero->Tile;
            int y = Hero->Y;
            Hero->Falling = 70;
			if(pitcmb > -1) Hero->FallCombo = pitcmb; //Use this pit combo's settings
            Hero->ScriptTile = TILE_INVIS; //invisible the player for a bit
            while(Hero->Falling > 0)
            {
				if(y < 176)
				{
                	y += fall;
                	Screen->FastTile(SPLAYER_PLAYER_DRAW, Hero->X, y, tile, 6);
				}
				if(is_warp && Hero->Falling == 1)
				{
					Hero->ScriptTile = -1; //restore before the warp
				}
				Waitframe();
            }
            Hero->ScriptTile = -1;
        }
    }
    void set_bottom_cancelwarp() //Sets a cancel warp to prevent down-scrolling
    {
        int oldid = Screen->SideWarpID[DIR_DOWN];
        if(oldid > -1 && Screen->SideWarpType[oldid] == WT_NOWARP)
            return; //already set
        bool used[4];
        for(int dir = 0; dir < 4; ++dir)
        {
			if(dir == DIR_DOWN) continue;
            int id = Screen->SideWarpID[dir];
            if(id > -1) used[id] = true;
        }
        for(int q = 3; q >= 0; --q)
        {
            unless(used[q])
            {
                Screen->SideWarpID[DIR_DOWN] = q;
                Screen->SideWarpType[q] = WT_NOWARP;
            }
        }
    }
}