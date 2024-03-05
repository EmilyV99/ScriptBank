#include "std.zh"

CONFIG I_TRACT_BOOTS_1 = -1; //Item ID that will cause ice to be half as slippery.
CONFIG I_TRACT_BOOTS_2 = -1; //Item ID that will cause ice to not be slippery.

CONFIG CT_ICE = 146;//Combo type used for ice, default 'Script 5'

//Max speed on ice in pixels per frame, including Link's base walking speed.
CONFIG ICE_MAX = 2.5;
CONFIG ICE_MAX_TRACT = 1.5; //...with I_TRACT_BOOTS_1

// In pixels per frame, a minimum used to make sure you don't move TOO slowly from a stop
CONFIG ICE_MIN_ACCEL = 1;

CONST_ASSERT(ICE_MIN_ACCEL > 0, "ICE_MIN_ACCEL must be >0!");
CONST_ASSERT(I_TRACT_BOOTS_1 >= -1 && I_TRACT_BOOTS_1 <= MAX_ITEMDATA, "I_TRACT_BOOTS_1 must be '-1' or a valid item ID");
CONST_ASSERT(I_TRACT_BOOTS_2 >= -1 && I_TRACT_BOOTS_2 <= MAX_ITEMDATA, "I_TRACT_BOOTS_2 must be '-1' or a valid item ID");
CONST_ASSERT(ICE_MAX > 0, "ICE_MAX must be > 0");
CONST_ASSERT(ICE_MAX_TRACT > 0, "ICE_MAX_TRACT must be > 0");
CONST_ASSERT(CT_ICE > 0, "CT_ICE must be a valid non-None combo type!");

//Assign the script to a slot, and set it to 'Run from Start' in Init Data
@InitD0("Accel Rate"), @InitDHelp0("The fraction of your current speed that you accelerate by. Default '0.015'. Must be above 0."),
@InitD0("Decel Rate"), @InitDHelp0("The fraction of your current speed that you decelerate by. Default '0.010'. Must be between 0 and 1.")
generic script icePhysics
{
	int old_step;
	bool was_onice = false;
	bool isOnIce()
	{
		int poses[] = {
			ComboAt(Hero->X, Hero->Y),
			ComboAt(Hero->X+15, Hero->Y),
			ComboAt(Hero->X, Hero->Y+15),
			ComboAt(Hero->X+15, Hero->Y+15)
			};
		for(int q = 0; q < 7; ++q)
		{
			mapdata md = Game->LoadTempScreen(q);
			for(pos : poses)
				if(md->ComboT[pos] == CT_ICE)
					return true;
		}
		return false;
	}

	void run(int accel, int decel)
	{
		if(accel <= 0)
			accel = 0.015;
		if(decel <= 0 || decel >= 1)
			decel = 0.010;
		int xaccel, yaccel, xdecel, ydecel;
		int Vx, Vy;
		bool onIce, noTract = true;
		int scrn;
		float upmult = 1, downmult = 1, leftmult = 1, rightmult = 1;
		int max = ICE_MAX;
		while(true)
		{
			while(Screen->ShowingMessage || Game->Scrolling[SCROLL_DIR] > -1)
				Waitframe();
			unless(I_TRACT_BOOTS_2 >= 0 && Hero->Item[I_TRACT_BOOTS_2])
			{
				if(I_TRACT_BOOTS_1 >= 0)
				{
					if(noTract && Hero->Item[I_TRACT_BOOTS_1])
					{
						CONFIG TRACT_SPEEDUP = 4, TRACT_SLOWDOWN = 1/TRACT_SPEEDUP;
						rightmult = (Vx < 1.5) ? TRACT_SPEEDUP : TRACT_SLOWDOWN;
						leftmult = (Vx > -1.5) ? TRACT_SPEEDUP : TRACT_SLOWDOWN;
						downmult = (Vy < 1.5) ? TRACT_SPEEDUP : TRACT_SLOWDOWN;
						upmult = (Vy > -1.5) ? TRACT_SPEEDUP : TRACT_SLOWDOWN;
						max = ICE_MAX_TRACT;
						noTract = false;
					}
					else if(!noTract && !Hero->Item[I_TRACT_BOOTS_1])
					{
						upmult = downmult = leftmult = rightmult = 1;
						max = ICE_MAX;
						noTract = true;
					}
				}
				unless(onIce)
				{
					Vx = 0;
					Vy = 0;
				}
				if(!onIce && isOnIce()) //Link has just stepped onto ice
				{
					if(Hero->InputDown)
						Vy += Hero->Step/100;
					if(Hero->InputUp)
						Vy -= Hero->Step/100;
					if(Hero->InputRight)
						Vx += Hero->Step/100;
					if(Hero->InputLeft)
						Vx -= Hero->Step/100;
					if(Vx && Vy)
					{
						Vx /= 4;
						Vy /= 4;
					}
					else
					{
						Vx /= 2;
						Vy /= 2;
					}
					was_onice = true;
					old_step = Hero->Step;
					Hero->Step = 0;
				}
				else if(onIce)
				{
					int xm = Max(ICE_MIN_ACCEL,Abs(Vx));
					int ym = Max(ICE_MIN_ACCEL,Abs(Vy));
					xaccel = accel * xm;
					xdecel = decel * xm;
					yaccel = accel * ym;
					ydecel = decel * ym;
					if(Abs(Vy)<max)
					{
						if(Hero->InputDown)
							Vy += yaccel*downmult;
						if(Hero->InputUp)
							Vy -= yaccel*upmult;
					}
					if(Abs(Vx)<max)
					{
						if(Hero->InputRight)
							Vx += xaccel*rightmult;
						if(Hero->InputLeft)
							Vx -= xaccel*leftmult;
					}
					Vx = Clamp(Vx, -max, max);
					Vy = Clamp(Vy, -max, max);
					Hero->MoveXY(Vx,Vy);
					if(Vx > 0 && !Hero->InputRight)
						Vx -= xdecel;
					if(Vx < 0 && !Hero->InputLeft)
						Vx += xdecel;
					if(Vy > 0 && !Hero->InputDown)
						Vy -= ydecel;
					if(Vy < 0 && !Hero->InputUp)
						Vy += ydecel;
				}
				if(Abs(Vy) < 0.01) Vy=0;
				if(Abs(Vx) < 0.01) Vx=0;
				onIce = isOnIce();
			}
			else onIce = false;
			if(was_onice && !onIce)
			{
				Hero->Step = old_step;
				was_onice = false;
			}
			Waitframe();
		}
	}
}

