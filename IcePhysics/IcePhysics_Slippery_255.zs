////////////////////////
//    Ice Physics     //
//     Slippery       //
//       2.55         //
//       V1.1         //
////////////////////////
#option SHORT_CIRCUIT on
#option HEADER_GUARD on
#include "std.zh"
#include "LinkMovement.zh"

namespace SlipperyIce
{
	untyped icePhysicsData[ICE_MAX];
	enum
	{
		ICE_ACCEL_RATE,
		ICE_DECEL_RATE,
		ICE_MAX_SPEED,
		ICE_COMBO_TYPE,
		ICE_VX,
		ICE_VY,
		ICE_ITEMCLASS,
		ICE_MAX
	};

	void doIcePhysics()
	{
		if(Hero->Action == LA_SCROLLING) return;
		if(icePhysicsData[ICE_MAX_SPEED] <= 0) return;
		for(int q = Screen->NumLWeapons(); q >= MIN_LWEAPON; --q)
		{
			lweapon l = Screen->LoadLWeapon(q);
			if(l->ID == LW_HOOKSHOT)
				return;
		}
		//Accel/Decel
		int accel = icePhysicsData[ICE_ACCEL_RATE];
		int decel = icePhysicsData[ICE_DECEL_RATE];
		if(icePhysicsData[ICE_ITEMCLASS] > 0)
		{
			int tractbootsID = GetHighestLevelItemOwned(icePhysicsData[ICE_ITEMCLASS]);
			if(tractbootsID>=0)
			{
				switch(Game->LoadItemData(tractbootsID)->Level)
				{
					case 0: //0... shouldn't be a thing? But whatever.
					case 1: //Level 1 is ignored by this script, in case you combine it with my other script on the same itemclass.
						break;
					case 2:
					{
						accel /= 2;
						decel *= 2;
						break;
					}
					default:
					{
						icePhysicsData[ICE_VX] = 0;
						icePhysicsData[ICE_VY] = 0;
						return;
					}
				}
			}
		}
		bool onIce = false;
		for(int layer = 0; layer < 3; ++layer)
		{
			if(layer > 0) if(Screen->LayerMap(layer) == -1) continue; //Skip nonexistant layers
			if(Hero->BigHitbox)
			{
				if(GetLayerComboT(layer, ComboAt(Hero->X, Hero->Y)) == icePhysicsData[ICE_COMBO_TYPE])
				{
					onIce = true;
					break;
				}
				if(GetLayerComboT(layer, ComboAt(Hero->X+15, Hero->Y)) == icePhysicsData[ICE_COMBO_TYPE])
				{
					onIce = true;
					break;
				}
			}
			if(GetLayerComboT(layer, ComboAt(Hero->X, Hero->Y+8)) == icePhysicsData[ICE_COMBO_TYPE])
			{
				onIce = true;
				break;
			}
			if(GetLayerComboT(layer, ComboAt(Hero->X+15, Hero->Y+8)) == icePhysicsData[ICE_COMBO_TYPE])
			{
				onIce = true;
				break;
			}
			if(GetLayerComboT(layer, ComboAt(Hero->X, Hero->Y+15)) == icePhysicsData[ICE_COMBO_TYPE])
			{
				onIce = true;
				break;
			}
			if(GetLayerComboT(layer, ComboAt(Hero->X+15, Hero->Y+15)) == icePhysicsData[ICE_COMBO_TYPE])
			{
				onIce = true;
				break;
			}
		}
		unless(onIce)
		{
			icePhysicsData[ICE_VX] = 0;
			icePhysicsData[ICE_VY] = 0;
			return;
		}
		//Handle accel
		if(Hero->InputUp) icePhysicsData[ICE_VY] -= accel;
		else if(icePhysicsData[ICE_VY] < 0) icePhysicsData[ICE_VY] = Min(icePhysicsData[ICE_VY] + decel, 0);
		if(Hero->InputDown) icePhysicsData[ICE_VY] += accel;
		else if(icePhysicsData[ICE_VY] > 0) icePhysicsData[ICE_VY] = Max(icePhysicsData[ICE_VY] - decel, 0);
		if(Hero->InputLeft) icePhysicsData[ICE_VX] -= accel;
		else if(icePhysicsData[ICE_VX] < 0) icePhysicsData[ICE_VX] = Min(icePhysicsData[ICE_VX] + decel, 0);
		if(Hero->InputRight) icePhysicsData[ICE_VX] += accel;
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
	void setIcePhysics(int accel, int decel, int maxspd, int combotype, int itemClass)
	{
		icePhysicsData[ICE_ACCEL_RATE] = accel;
		icePhysicsData[ICE_DECEL_RATE] = decel;
		icePhysicsData[ICE_MAX_SPEED] = maxspd;
		icePhysicsData[ICE_COMBO_TYPE] = combotype;
		icePhysicsData[ICE_ITEMCLASS] = itemClass;
	}
}

global script SlipperyIceExample
{
	void run()
	{
		LinkMovement_Init();
		SlipperyIce::setIcePhysics(0.1, 0.025, (3-(1.5)), CT_SCRIPT5, IC_CUSTOM20);
		while(true)
		{
			SlipperyIce::doIcePhysics();
			LinkMovement_Update1();
			Waitdraw();
			LinkMovement_Update2();
			Waitframe();
		}
	}
}