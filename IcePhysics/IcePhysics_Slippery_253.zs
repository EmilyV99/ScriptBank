////////////////////////
//    Ice Physics     //
//     Slippery       //
//       2.53         //
//       V1.1         //
////////////////////////
//Dependencies: "LinkMovement.zh"

int icePhysicsData[8];

const int ICE_ACCEL_RATE = 0;
const int ICE_DECEL_RATE = 1;
const int ICE_MAX_SPEED = 2;
const int ICE_COMBO_TYPE = 3;
const int ICE_VX = 4;
const int ICE_VY = 5;
const int ICE_ITEMCLASS = 6;
const int ICE_FULLTILE_LINK = 7;

void doIcePhysics()
{
	if(Link->Action == LA_SCROLLING) return;
	if(icePhysicsData[ICE_MAX_SPEED] <= 0) return;
	for(int q = Screen->NumLWeapons(); q >= MIN_LWEAPON; --q)
	{
		lweapon l = Screen->LoadLWeapon(q);
		if(l->ID == LW_HOOKSHOT)
			return;
	}
	int accel = icePhysicsData[ICE_ACCEL_RATE];
	int decel = icePhysicsData[ICE_DECEL_RATE];
	if(icePhysicsData[ICE_ITEMCLASS] > 0)
	{
		int tractbootsID = GetHighestLevelItemOwned(icePhysicsData[ICE_ITEMCLASS]);
		if(tractbootsID>=0)
		{
			itemdata tractboots = Game->LoadItemData(tractbootsID);
			if(tractboots->Level > 1)
			{
				icePhysicsData[ICE_VX] = 0;
				icePhysicsData[ICE_VY] = 0;
				return;
			}
			else if(tractboots->Level > 0)
			{
				accel /= 2;
				decel *= 2;
			}
		}
	}
	bool onIce = false;
	for(int layer = 0; layer < 3; ++layer)
	{
		if(layer > 0) if(Screen->LayerMap(layer) == -1) continue; //Skip nonexistant layers
		if(icePhysicsData[ICE_FULLTILE_LINK])
		{
			if(GetLayerComboT(layer, ComboAt(Link->X, Link->Y)) == icePhysicsData[ICE_COMBO_TYPE])
			{
				onIce = true;
				break;
			}
			if(GetLayerComboT(layer, ComboAt(Link->X+15, Link->Y)) == icePhysicsData[ICE_COMBO_TYPE])
			{
				onIce = true;
				break;
			}
		}
		if(GetLayerComboT(layer, ComboAt(Link->X, Link->Y+8)) == icePhysicsData[ICE_COMBO_TYPE])
		{
			onIce = true;
			break;
		}
		if(GetLayerComboT(layer, ComboAt(Link->X+15, Link->Y+8)) == icePhysicsData[ICE_COMBO_TYPE])
		{
			onIce = true;
			break;
		}
		if(GetLayerComboT(layer, ComboAt(Link->X, Link->Y+15)) == icePhysicsData[ICE_COMBO_TYPE])
		{
			onIce = true;
			break;
		}
		if(GetLayerComboT(layer, ComboAt(Link->X+15, Link->Y+15)) == icePhysicsData[ICE_COMBO_TYPE])
		{
			onIce = true;
			break;
		}
	}
	if(!onIce)
	{
		icePhysicsData[ICE_VX] = 0;
		icePhysicsData[ICE_VY] = 0;
		return;
	}
	//Accel/Decel
	if(Link->InputUp) icePhysicsData[ICE_VY] -= accel;
	else if(icePhysicsData[ICE_VY] < 0) icePhysicsData[ICE_VY] = Min(icePhysicsData[ICE_VY] + decel, 0);
	if(Link->InputDown) icePhysicsData[ICE_VY] += accel;
	else if(icePhysicsData[ICE_VY] > 0) icePhysicsData[ICE_VY] = Max(icePhysicsData[ICE_VY] - decel, 0);
	if(Link->InputLeft) icePhysicsData[ICE_VX] -= accel;
	else if(icePhysicsData[ICE_VX] < 0) icePhysicsData[ICE_VX] = Min(icePhysicsData[ICE_VX] + decel, 0);
	if(Link->InputRight) icePhysicsData[ICE_VX] += accel;
	else if(icePhysicsData[ICE_VX] > 0) icePhysicsData[ICE_VX] = Max(icePhysicsData[ICE_VX] - decel, 0);
	//Max speed bounding
	if(icePhysicsData[ICE_VY] > icePhysicsData[ICE_MAX_SPEED]) icePhysicsData[ICE_VY] = icePhysicsData[ICE_MAX_SPEED];
	else if(icePhysicsData[ICE_VY] < -icePhysicsData[ICE_MAX_SPEED]) icePhysicsData[ICE_VY] = -icePhysicsData[ICE_MAX_SPEED];
	if(icePhysicsData[ICE_VX] > icePhysicsData[ICE_MAX_SPEED]) icePhysicsData[ICE_VX] = icePhysicsData[ICE_MAX_SPEED];
	else if(icePhysicsData[ICE_VX] < -icePhysicsData[ICE_MAX_SPEED]) icePhysicsData[ICE_VX] = -icePhysicsData[ICE_MAX_SPEED];
	//
	LinkMovement_PushNoEdge(icePhysicsData[ICE_VX], icePhysicsData[ICE_VY]);
}

//This function sets all the variables at once
//You can set them individually using the 'ICE_' constants to access the 'icePhysicsData' array.
//Accel: Rate of acceleration per frame. Recommended: 0.1
//Decel: Rate of deceleration per frame. Recommended: 0.025
//maxspd: Highest pixels per frame the ice will slide the player (in ADDITION to the 1.5 pixels per frame he moves normally)
//combotype: The combo type representing ice
//itemClass: The item class for Traction Boots. A level 2 of this item will halve the speed, a level 3 will negate ice entirely. (L1 is ignored)
//biglink: If the full 16x16 hitbox should be used for ice, instead of just the bottom 8 pixels
void setIcePhysics(int accel, int decel, int maxspd, int combotype, int itemClass)
{
	setIcePhysics(accel, decel, maxspd, combotype, itemClass, false);
}
void setIcePhysics(int accel, int decel, int maxspd, int combotype, int itemClass, bool biglink)
{
	icePhysicsData[ICE_ACCEL_RATE] = accel;
	icePhysicsData[ICE_DECEL_RATE] = decel;
	icePhysicsData[ICE_MAX_SPEED] = maxspd;
	icePhysicsData[ICE_COMBO_TYPE] = combotype;
	icePhysicsData[ICE_ITEMCLASS] = itemClass;
	icePhysicsData[ICE_FULLTILE_LINK] = Cond(biglink, 1, 0);
}

global script SlipperyIceExample
{
	void run()
	{
		LinkMovement_Init();
		setIcePhysics(0.1, 0.025, (3-(1.5)), CT_SCRIPT5, IC_CUSTOM20, false);
		while(true)
		{
			doIcePhysics();
			LinkMovement_Update1();
			Waitdraw();
			LinkMovement_Update2();
			Waitframe();
		}
	}
}