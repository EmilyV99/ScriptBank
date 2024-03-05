////////////////////////
//    Ice Physics     //
//     ForceSlide     //
//       2.55         //
//       V1.1         //
////////////////////////
#option SHORT_CIRCUIT on
#option HEADER_GUARD on
#include "std.zh"
#include "LinkMovement.zh"

namespace ForceSlideIce
{
	untyped icePhysicsData[ICE_MAX];
	enum
	{
		ICE_MOVESPEED,
		ICE_COMBO_TYPE,
		ICE_ITEMCLASS,
		ICE_COMBOGRIDLOCK, //Value of 0 is "no lock", 1 is "half-grid", 2 is "whole-grid"
		ICE_SLIDEDIR,
		ICE_MAX
	};
	enum GridLock
	{
		GRID_NONE,
		GRID_HALF,
		GRID_FULL
	};

	void doIcePhysics()
	{
		if(Hero->Action == LA_SCROLLING) return;
		if(icePhysicsData[ICE_ITEMCLASS] > 0)
		{
			int tractbootsID = GetHighestLevelItemOwned(icePhysicsData[ICE_ITEMCLASS]);
			if(tractbootsID>=0)
			{
				return;
			}
		}
		for(int q = Screen->NumLWeapons(); q >= MIN_LWEAPON; --q)
		{
			lweapon l = Screen->LoadLWeapon(q);
			if(l->ID == LW_HOOKSHOT)
				return;
		}
		bool onIce = false;
		for(int dir = DIR_UP; !onIce && (dir < 4); ++dir)
		{
			int gridlockedX = Hero->X;
			int gridlockedY = Hero->Y;
			//
			if(icePhysicsData[ICE_SLIDEDIR]==-1)
			{
				switch(dir)
				{
					case DIR_UP: unless(Input->Button[CB_UP]) continue; else break;
					case DIR_DOWN: unless(Input->Button[CB_DOWN]) continue; else break;
					case DIR_LEFT: unless(Input->Button[CB_LEFT]) continue; else break;
					case DIR_RIGHT: unless(Input->Button[CB_RIGHT]) continue; else break;
				}
				switch(icePhysicsData[ICE_COMBOGRIDLOCK])
				{
					case GRID_HALF:
					{
						if(dir==DIR_UP || dir==DIR_DOWN) gridlockedX = ((Hero->X+4) >> 3) << 3;
						else if(dir==DIR_RIGHT || dir==DIR_LEFT) gridlockedY = ((Hero->Y+4) >> 3) << 3;
						break;
					}
					case GRID_FULL:
					{
						if(dir==DIR_UP || dir==DIR_DOWN) gridlockedX = ((Hero->X+8) >> 4) << 4;
						else if(dir==DIR_RIGHT || dir==DIR_LEFT) gridlockedY = ((Hero->Y+8) >> 4) << 4;
						break;
					}
				}
			}
			for(int layer = 0; layer < 3; ++layer)
			{
				if(layer > 0) if(Screen->LayerMap(layer) == -1) continue; //Skip nonexistant layers
				if(Hero->BigHitbox)
				{
					if(GetLayerComboT(layer, ComboAt(gridlockedX, gridlockedY)) == icePhysicsData[ICE_COMBO_TYPE])
					{
						onIce = true;
						break;
					}
					if(GetLayerComboT(layer, ComboAt(gridlockedX+15, gridlockedY)) == icePhysicsData[ICE_COMBO_TYPE])
					{
						onIce = true;
						break;
					}
				}
				if(GetLayerComboT(layer, ComboAt(gridlockedX, gridlockedY+8)) == icePhysicsData[ICE_COMBO_TYPE])
				{
					onIce = true;
					break;
				}
				if(GetLayerComboT(layer, ComboAt(gridlockedX+15, gridlockedY+8)) == icePhysicsData[ICE_COMBO_TYPE])
				{
					onIce = true;
					break;
				}
				if(GetLayerComboT(layer, ComboAt(gridlockedX, gridlockedY+15)) == icePhysicsData[ICE_COMBO_TYPE])
				{
					onIce = true;
					break;
				}
				if(GetLayerComboT(layer, ComboAt(gridlockedX+15, gridlockedY+15)) == icePhysicsData[ICE_COMBO_TYPE])
				{
					onIce = true;
					break;
				}
			}
			if(icePhysicsData[ICE_SLIDEDIR]==-1 && onIce)
			{
				icePhysicsData[ICE_SLIDEDIR] = dir;
				Hero->X = gridlockedX;
				Hero->Y = gridlockedY;
				Hero->Dir = dir;
			}
		}

		unless(onIce)
		{
			icePhysicsData[ICE_SLIDEDIR] = -1;
			return;
		}
		int spd = icePhysicsData[ICE_MOVESPEED];
		int dir = icePhysicsData[ICE_SLIDEDIR];
		unless(CanWalk(Hero->X, Hero->Y, icePhysicsData[ICE_SLIDEDIR], spd, Hero->BigHitbox))
		{
			do
			{
				int screen = Game->GetCurScreen();
				if(dir==DIR_RIGHT && Hero->X+spd>=240 && ((screen&0x0F) != 0x0F)) break;
				if(dir==DIR_LEFT && Hero->X-spd<=0 && ((screen&0x0F) != 0x00)) break;
				if(dir==DIR_UP && Hero->Y-spd<=0 && ((screen-(screen&0x0F)) != 0x00)) break;
				if(dir==DIR_DOWN && Hero->Y+spd>=160 && ((screen-(screen&0x0F)) != 0x70)) break;
				icePhysicsData[ICE_SLIDEDIR] = -1;
				return;
			} while(false);
		}
		//
		switch(dir)
		{
			case DIR_UP:
			{
				LinkMovement_PushNoEdge(0, -spd);
				break;
			}
			case DIR_DOWN:
			{
				LinkMovement_PushNoEdge(0, spd);
				break;
			}
			case DIR_LEFT:
			{
				LinkMovement_PushNoEdge(-spd, 0);
				break;
			}
			case DIR_RIGHT:
			{
				LinkMovement_PushNoEdge(spd, 0);
				break;
			}
		}
	}

	//This function sets all the variables at once
	//You can set them individually using the 'ICE_' constants to access the 'icePhysicsData' array.
	//spd: Pixels per frame for sliding
	//combotype: The combo type representing ice
	//biglink: If the full 16x16 hitbox should be used for ice, instead of just the bottom 8 pixels
	//itemClass: The item class for Traction Boots. These negate ice completely.
	//combogrid: If 0, no grid-locking. If 1, half-grid locking. If 2, whole-grid locking. (any other value = no grid-locking)
	//		NOTE: I highly recommend at least half-grid lock if diagonal movement is enabled.
	void setIcePhysics(int spd, int combotype, int itemClass, int combogrid)
	{
		icePhysicsData[ICE_MOVESPEED] = spd;
		icePhysicsData[ICE_COMBO_TYPE] = combotype;
		icePhysicsData[ICE_ITEMCLASS] = itemClass;
		icePhysicsData[ICE_COMBOGRIDLOCK] = combogrid;
	}

	bool isSliding()
	{
		return icePhysicsData[ICE_SLIDEDIR] > -1;
	}
}

global script ForceSlideIceExample
{
	void run()
	{
		LinkMovement_Init();
		ForceSlideIce::setIcePhysics(1, CT_SCRIPT5, IC_CUSTOM20, ForceSlideIce::GRID_FULL);
		while(true)
		{
			ForceSlideIce::doIcePhysics();
			if(ForceSlideIce::isSliding())
			{
				NoDirs();
			}
			LinkMovement_Update1();
			Waitdraw();
			LinkMovement_Update2();
			Waitframe();
		}
	}
	
	void NoDirs()
	{
		Hero->InputUp = false;
		Hero->InputDown = false;
		Hero->InputRight = false;
		Hero->InputLeft = false;
		Hero->PressUp = false;
		Hero->PressDown = false;
		Hero->PressRight = false;
		Hero->PressLeft = false;
	}
}