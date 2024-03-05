///////////////////////////////////
//        BetterConveyors        //
//            Emily              //
//        Version: 1.00          //
//           21 Aug 19           //
///////////////////////////////////
#option SHORT_CIRCUIT on
#option HEADER_GUARD on
#include "std.zh"
#include "LinkMovement.zh"

namespace BetterConveyors
{
	typedef const int DEFINE;
	typedef const int CONFIG;
	
	CONFIG COMBOTYPE = CT_SCRIPT1;
	CONFIG UPFLAG    = CF_SCRIPT1;
	CONFIG DOWNFLAG	 = CF_SCRIPT2;
	CONFIG LEFTFLAG	 = CF_SCRIPT3;
	CONFIG RIGHTFLAG = CF_SCRIPT4;
	CONFIG ULFLAG    = CF_SCRIPT5;
	CONFIG URFLAG    = CF_SCRIPT6;
	CONFIG DLFLAG    = CF_SCRIPT7;
	CONFIG DRFLAG    = CF_SCRIPT8;
	
	DEFINE UBIT = (1<<DIR_UP);
	DEFINE DBIT = (1<<DIR_DOWN);
	DEFINE LBIT = (1<<DIR_LEFT);
	DEFINE RBIT = (1<<DIR_RIGHT);
	
	/**
	 * Runs conveyor combos.
	 * Will only affect entities specified; player, enemies, and items as bool parameters. If true, they will be affected.
	 * Note: 'spd' is the distance, in pixels, to move each entity per frame. Decimal values will ONLY affect the PLAYER.
	 *       Enemies and items will truncate the value.
	 */
	void runConveyors(int spd, bool plyr, bool enemy, bool itm)
	{
		if(plyr)
		{
			int flags = checkConveyor(Hero->X, Hero->Y + (Hero->BigHitbox ? 0 : 8), 16, (Hero->BigHitbox ? 16 : 8));
			if(flags&UBIT) LinkMovement_Push(0, -spd);
			if(flags&DBIT) LinkMovement_Push(0, spd);
			if(flags&LBIT) LinkMovement_Push(-spd, 0);
			if(flags&RBIT) LinkMovement_Push(spd, 0);
		}
		spd = Floor(spd);
		if(enemy)
		{
			DEFINE NUMNPC = Screen->NumNPCs();
			for(int q = 1; q <= NUMNPC; ++q)
			{
				npc n = Screen->LoadNPC(q);
				int flags = checkConveyor(n->X, n->Y, n->HitWidth, n->HitHeight);
				int dx = ((flags&LBIT) ? -spd : 0) + ((flags&RBIT) ? spd : 0);
				int dy = ((flags&UBIT) ? -spd : 0) + ((flags&DBIT) ? spd : 0);
				if(dx>0)
				{
					while(dx > 0 && _CanWalk(n->X, n->Y, n->HitWidth, n->HitHeight, DIR_RIGHT, 1))
					{
						++n->X;
						--dx;
					}
				}
				else if(dx<0)
				{
					while(dx < 0 && _CanWalk(n->X, n->Y, n->HitWidth, n->HitHeight, DIR_LEFT, 1))
					{
						--n->X;
						++dx;
					}
				}
				if(dy>0)
				{
					while(dy > 0 && _CanWalk(n->X, n->Y, n->HitWidth, n->HitHeight, DIR_DOWN, 1))
					{
						++n->Y;
						--dy;
					}
				}
				else if(dy<0)
				{
					while(dy < 0 && _CanWalk(n->X, n->Y, n->HitWidth, n->HitHeight, DIR_UP, 1))
					{
						--n->Y;
						++dy;
					}
				}
			}
		}
		if(itm)
		{
			DEFINE NUMITEM = Screen->NumItems();
			for(int q = 1; q <= NUMITEM; ++q)
			{
				item it = Screen->LoadItem(q);
				int flags = checkConveyor(it->X, it->Y, it->HitWidth, it->HitHeight);
				int dx = ((flags&LBIT) ? -spd : 0) + ((flags&RBIT) ? spd : 0);
				int dy = ((flags&UBIT) ? -spd : 0) + ((flags&DBIT) ? spd : 0);
				if(dx>0)
				{
					while(dx > 0 && _CanWalk(it->X, it->Y, it->HitWidth, it->HitHeight, DIR_RIGHT, 1))
					{
						++it->X;
						--dx;
					}
				}
				else if(dx<0)
				{
					while(dx < 0 && _CanWalk(it->X, it->Y, it->HitWidth, it->HitHeight, DIR_LEFT, 1))
					{
						--it->X;
						++dx;
					}
				}
				if(dy>0)
				{
					while(dy > 0 && _CanWalk(it->X, it->Y, it->HitWidth, it->HitHeight, DIR_DOWN, 1))
					{
						++it->Y;
						--dy;
					}
				}
				else if(dy<0)
				{
					while(dy < 0 && _CanWalk(it->X, it->Y, it->HitWidth, it->HitHeight, DIR_UP, 1))
					{
						--it->Y;
						++dy;
					}
				}
			}
		}
	}
	
	/**
	 * A version of CanWalk() that works with large enemies/items.
	 */
	bool _CanWalk(int x, int y, int wid, int hei, int dir, int step) 
	{
		int xx = x+wid;
		int yy = y+hei;
		switch(dir)
		{
			case DIR_UP: return !(y-step<0||Screen->isSolid(x,y-step)||Screen->isSolid(x+8,y-step)||Screen->isSolid(xx,y-step));
			case DIR_DOWN: return !(yy+step>=176||Screen->isSolid(x,yy+step)||Screen->isSolid(x+8,yy+step)||Screen->isSolid(xx,yy+step));
			case DIR_LEFT: return !(x-step<0||Screen->isSolid(x-step,y)||Screen->isSolid(x-step,y+7)||Screen->isSolid(x-step,yy));
			case DIR_RIGHT: return !(xx+step>=256||Screen->isSolid(xx+step,y)||Screen->isSolid(xx+step,y+7)||Screen->isSolid(xx+step,yy));
		}
	}
	
	/**
	 * Returns a flagset of which directions the object of given pos and size should be pushed.
	 * Use the *BIT constants to read from the return, using bitwise.
	 */
	int checkConveyor(const int x, const int y, const int wid, const int hei)
	{
		int combos[4] = {ComboAt(Hero->X, Hero->Y), ComboAt(Hero->X, Hero->Y + 15), ComboAt(Hero->X + 15, Hero->Y), ComboAt(Hero->X + 15, Hero->Y + 15)};
		int ret;
		mapdata m1, m2;
		if(Screen->LayerMap[1]) m1 = Game->LoadMapData(Screen->LayerMap[1], Screen->LayerScreen[1]);
		if(Screen->LayerMap[2]) m2 = Game->LoadMapData(Screen->LayerMap[2], Screen->LayerScreen[2]);
		
		for(int tx = x; tx < x+wid+15; tx+=16)
		{
			if(tx>=x+wid) tx = x+wid-1;
			for(int ty = y; ty < y+hei+15; ty+=16)
			{
				if(ty>=y+hei) ty = y+hei-1;
				int combo = ComboAt(tx,ty);
				if(Screen->ComboT[combo] != COMBOTYPE) continue;
				//start switches
				switch(Screen->ComboF[combo])
				{
					case UPFLAG:
						ret |= UBIT;
						break;
					case DOWNFLAG:
						ret |= DBIT;
						break;
					case LEFTFLAG:
						ret |= LBIT;
						break;
					case RIGHTFLAG:
						ret |= RBIT;
						break;
					case ULFLAG:
						ret |= UBIT;
						ret |= LBIT;
						break;
					case URFLAG:
						ret |= UBIT;
						ret |= RBIT;
						break;
					case DLFLAG:
						ret |= DBIT;
						ret |= LBIT;
						break;
					case DRFLAG:
						ret |= DBIT;
						ret |= RBIT;
						break;
				}
				switch(Screen->ComboI[combo])
				{
					case UPFLAG:
						ret |= UBIT;
						break;
					case DOWNFLAG:
						ret |= DBIT;
						break;
					case LEFTFLAG:
						ret |= LBIT;
						break;
					case RIGHTFLAG:
						ret |= RBIT;
						break;
					case ULFLAG:
						ret |= UBIT;
						ret |= LBIT;
						break;
					case URFLAG:
						ret |= UBIT;
						ret |= RBIT;
						break;
					case DLFLAG:
						ret |= DBIT;
						ret |= LBIT;
						break;
					case DRFLAG:
						ret |= DBIT;
						ret |= RBIT;
						break;
					
				}
				//end switches
			}
		}
		if(m1!=NULL)
		{
			for(int tx = x; tx < x+wid+15; tx+=16)
			{
				if(tx>=x+wid) tx = x+wid-1;
				for(int ty = y; ty < y+hei+15; ty+=16)
				{
					if(ty>=y+hei) ty = y+hei-1;
					int combo = ComboAt(tx,ty);
					if(m1->ComboT[combo] != COMBOTYPE) continue;
					//start switches
					switch(m1->ComboF[combo])
					{
						case UPFLAG:
							ret |= UBIT;
							break;
						case DOWNFLAG:
							ret |= DBIT;
							break;
						case LEFTFLAG:
							ret |= LBIT;
							break;
						case RIGHTFLAG:
							ret |= RBIT;
							break;
						case ULFLAG:
							ret |= UBIT;
							ret |= LBIT;
							break;
						case URFLAG:
							ret |= UBIT;
							ret |= RBIT;
							break;
						case DLFLAG:
							ret |= DBIT;
							ret |= LBIT;
							break;
						case DRFLAG:
							ret |= DBIT;
							ret |= RBIT;
							break;
					}
					switch(m1->ComboI[combo])
					{
						case UPFLAG:
							ret |= UBIT;
							break;
						case DOWNFLAG:
							ret |= DBIT;
							break;
						case LEFTFLAG:
							ret |= LBIT;
							break;
						case RIGHTFLAG:
							ret |= RBIT;
							break;
						case ULFLAG:
							ret |= UBIT;
							ret |= LBIT;
							break;
						case URFLAG:
							ret |= UBIT;
							ret |= RBIT;
							break;
						case DLFLAG:
							ret |= DBIT;
							ret |= LBIT;
							break;
						case DRFLAG:
							ret |= DBIT;
							ret |= RBIT;
							break;
						
					}
					//end switches
				}
			}
		}
		if(m2!=NULL)
		{
			for(int tx = x; tx < x+wid+15; tx+=16)
			{
				if(tx>=x+wid) tx = x+wid-1;
				for(int ty = y; ty < y+hei+15; ty+=16)
				{
					if(ty>=y+hei) ty = y+hei-1;
					int combo = ComboAt(tx,ty);
					if(m2->ComboT[combo] != COMBOTYPE) continue;
					//start switches
					switch(m2->ComboF[combo])
					{
						case UPFLAG:
							ret |= UBIT;
							break;
						case DOWNFLAG:
							ret |= DBIT;
							break;
						case LEFTFLAG:
							ret |= LBIT;
							break;
						case RIGHTFLAG:
							ret |= RBIT;
							break;
						case ULFLAG:
							ret |= UBIT;
							ret |= LBIT;
							break;
						case URFLAG:
							ret |= UBIT;
							ret |= RBIT;
							break;
						case DLFLAG:
							ret |= DBIT;
							ret |= LBIT;
							break;
						case DRFLAG:
							ret |= DBIT;
							ret |= RBIT;
							break;
					}
					switch(m2->ComboI[combo])
					{
						case UPFLAG:
							ret |= UBIT;
							break;
						case DOWNFLAG:
							ret |= DBIT;
							break;
						case LEFTFLAG:
							ret |= LBIT;
							break;
						case RIGHTFLAG:
							ret |= RBIT;
							break;
						case ULFLAG:
							ret |= UBIT;
							ret |= LBIT;
							break;
						case URFLAG:
							ret |= UBIT;
							ret |= RBIT;
							break;
						case DLFLAG:
							ret |= DBIT;
							ret |= LBIT;
							break;
						case DRFLAG:
							ret |= DBIT;
							ret |= RBIT;
							break;
						
					}
					//end switches
				}
			}
		}
		return ret;
	}
	
	//This will run conveyors constantly throughout the quest at the given settings
	global script BetterConveyorsGlobalExample
	{
		void run()
		{
			LinkMovement_Init();
			while(true)
			{
				runConveyors(1.5, true, true, true); //1.5 px per frame speed, affects player enemies and items.
				LinkMovement_Update1();
				Waitdraw();
				LinkMovement_Update2();
				Waitframe();
			}
		}
	}
	
	//This will run conveyors on the screen it is placed on, and can have different settings per-screen.
	ffc script BetterConveyorsFFC
	{
		void run(int spd, bool plyr, bool enemy, bool itm)
		{
			while(true)
			{
				runConveyors(spd, plyr, enemy, itm);
				Waitframe();
			}
		}
	}
}