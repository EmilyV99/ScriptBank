////////////////////////
//    Ice Physics     //
//     ForceSlide     //
//       2.53         //
//       V1.1         //
////////////////////////
//Dependencies: "LinkMovement.zh"

int icePhysicsData[7];

const int ICE_MOVESPEED = 0;
const int ICE_COMBO_TYPE = 1;
const int ICE_ITEMCLASS = 2;
const int ICE_COMBOGRIDLOCK = 3; //Value of 0 is "no lock", 1 is "half-grid", 2 is "whole-grid"
const int ICE_SLIDEDIR = 4;
const int ICE_FULLTILE_LINK = 5;

const int GRID_NONE = 0;
const int GRID_HALF = 1;
const int GRID_FULL = 2;

void doIcePhysics()
{
	if(Link->Action == LA_SCROLLING) return;
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
		int gridlockedX = Link->X;
		int gridlockedY = Link->Y;
		//
		if(icePhysicsData[ICE_SLIDEDIR]==-1)
		{
			if(dir == DIR_UP && !Link->InputUp) continue;
			else if(dir == DIR_DOWN && !Link->InputDown) continue;
			else if(dir == DIR_LEFT && !Link->InputLeft) continue;
			else if(dir == DIR_RIGHT && !Link->InputRight) continue;
			if(icePhysicsData[ICE_COMBOGRIDLOCK] == 1)
			{
				if(dir==DIR_UP || dir==DIR_DOWN) gridlockedX = ((Link->X+4) >> 3) << 3;
				else if(dir==DIR_RIGHT || dir==DIR_LEFT) gridlockedY = ((Link->Y+4) >> 3) << 3;
			}
			else if(icePhysicsData[ICE_COMBOGRIDLOCK] == 2)
			{
				if(dir==DIR_UP || dir==DIR_DOWN) gridlockedX = ((Link->X+8) >> 4) << 4;
				else if(dir==DIR_RIGHT || dir==DIR_LEFT) gridlockedY = ((Link->Y+8) >> 4) << 4;
			}
		}
		for(int layer = 0; layer < 3; ++layer)
		{
			if(layer > 0) if(Screen->LayerMap(layer) == -1) continue; //Skip nonexistant layers
			if(icePhysicsData[ICE_FULLTILE_LINK])
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
			Link->X = gridlockedX;
			Link->Y = gridlockedY;
			Link->Dir = dir;
		}
	}

	if(!onIce)
	{
		icePhysicsData[ICE_SLIDEDIR] = -1;
		return;
	}
	int spd = icePhysicsData[ICE_MOVESPEED];
	int dir = icePhysicsData[ICE_SLIDEDIR];
	if(!CanWalk(Link->X, Link->Y, icePhysicsData[ICE_SLIDEDIR], spd, icePhysicsData[ICE_FULLTILE_LINK]))
	{
		do
		{
			int screen = Game->GetCurScreen();
			if(dir==DIR_RIGHT && Link->X+spd>=240 && ((screen&0x0F) != 0x0F)) break;
			if(dir==DIR_LEFT && Link->X-spd<=0 && ((screen&0x0F) != 0x00)) break;
			if(dir==DIR_UP && Link->Y-spd<=0 && ((screen-(screen&0x0F)) != 0x00)) break;
			if(dir==DIR_DOWN && Link->Y+spd>=160 && ((screen-(screen&0x0F)) != 0x70)) break;
			icePhysicsData[ICE_SLIDEDIR] = -1;
			return;
		} while(false);
	}
	//
	if(dir==DIR_RIGHT) LinkMovement_PushNoEdge(spd, 0);
	else if(dir==DIR_LEFT) LinkMovement_PushNoEdge(-spd, 0);
	else if(dir==DIR_UP) LinkMovement_PushNoEdge(0, -spd);
	else if(dir==DIR_DOWN) LinkMovement_PushNoEdge(0, spd);
}

//This function sets all the variables at once
//You can set them individually using the 'ICE_' constants to access the 'icePhysicsData' array.
//spd: Pixels per frame for sliding
//combotype: The combo type representing ice
//itemClass: The item class for Traction Boots. These negate ice completely.
//combogrid: If 0, no grid-locking. If 1, half-grid locking. If 2, whole-grid locking. (any other value = no grid-locking)
//		NOTE: I highly recommend at least half-grid lock if diagonal movement is enabled.
//biglink: If the full 16x16 hitbox should be used for ice, instead of just the bottom 8 pixels
void setIcePhysics(int spd, int combotype, int itemClass, int combogrid)
{
	setIcePhysics(spd, combotype, itemClass, combogrid, false);
}
void setIcePhysics(int spd, int combotype, int itemClass, int combogrid, bool biglink)
{
	icePhysicsData[ICE_MOVESPEED] = spd;
	icePhysicsData[ICE_COMBO_TYPE] = combotype;
	icePhysicsData[ICE_ITEMCLASS] = itemClass;
	icePhysicsData[ICE_COMBOGRIDLOCK] = combogrid;
	icePhysicsData[ICE_FULLTILE_LINK] = Cond(biglink, 1, 0);
}

bool isSliding()
{
	return icePhysicsData[ICE_SLIDEDIR] > -1;
}

global script ForceSlideIceExample
{
	void run()
	{
		LinkMovement_Init();
		setIcePhysics(1, CT_SCRIPT5, IC_CUSTOM20, GRID_FULL, false);
		while(true)
		{
			doIcePhysics();
			if(isSliding())
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
		Link->InputUp = false;
		Link->InputDown = false;
		Link->InputRight = false;
		Link->InputLeft = false;
		Link->PressUp = false;
		Link->PressDown = false;
		Link->PressRight = false;
		Link->PressLeft = false;
	}
}