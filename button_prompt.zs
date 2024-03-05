#option SHORT_CIRCUIT on
#option HEADER_GUARD on
#include "std.zh"

typedef const int CONFIG;
typedef const bool CONFIGB;
typedef const int DEFINE;
typedef const bool DEFINEB;

@Author("EmilyV")
combodata script buttonPrompt
{
	CONFIG HXOFS = 6;
	CONFIG HYOFS = -8;
	/** Setup:
	 * Set 'InitD[0]' to the combo to draw for the button prompt
	 * Set the constants above to the X/Y offset from the Hero's position to display the prompt
	 */
	void run(int prompt_combo)
	{
		unless(prompt_combo) return;
		int dirflag = 1111b;
		int btnflags;
		
		switch(this->Type)
		{
			case CT_CHEST:
			case CT_SIGNPOST:
				btnflags = this->Attribytes[2];
				if(this->Flags[8])
					dirflag ~= (1b<<DIR_UP);
				if(this->Flags[9])
					dirflag ~= (1b<<DIR_DOWN);
				if(this->Flags[10])
					dirflag ~= (1b<<DIR_LEFT);
				if(this->Flags[11])
					dirflag ~= (1b<<DIR_RIGHT);
				break;
			default:
				bool found = false;
				for(int q = 0; q < 8; ++q)
				{
					if(this->TriggerButton[q])
					{
						found = true;
						break;
					}
				}
				unless(found) break;
				btnflags = 0;
				for(int q = 0; q < 8; ++q)
				{
					if(this->TriggerButton[q])
						btnflags |= 1b << q;
				}
				dirflag = 0;
				for(int q = 0; q < 4; ++q)
				{
					if(this->TrigFlags[q+TRIGFLAG_BTN_TOP])
						dirflag |= 1b << q;
				}
				break;
		}
		int dir;
		while(true)
		{
			Waitframe();
			if(Screen->ShowingMessage)
				continue;
			switch(Hero->Action)
			{
				case LA_NONE:
				case LA_WALKING:
					break;
				default: continue;
			}
			if(Hero->Z > 0)
				continue;
			dir = Hero->Dir^1b;
			if(dirflag & (1b << dir))
			{ //If the direction is valid
				bool doPrompt = false;
				switch(dir)
				{
					case DIR_UP: //Top
						int xdiff = Hero->X - this->X;
						if(xdiff >= -12 && xdiff < 12)
						{
							int ydiff = this->Y - Hero->Y;
							if(ydiff > 0 && ydiff <= 17)
							{
								doPrompt = true;
							}
						}
						break;
					case DIR_DOWN: //Bottom
						int xdiff = Hero->X - this->X;
						if(xdiff >= -12 && xdiff < 12)
						{
							int ydiff = (Hero->Y + (Hero->BigHitbox ? 0 : 8)) - this->Y;
							if(ydiff > 0 && ydiff <= 17)
							{
								doPrompt = true;
							}
						}
						break;
					case DIR_LEFT: //Left
						int ydiff = Hero->Y - this->Y;
						if((ydiff < (Hero->BigHitbox ? 16 : 8) && ydiff >= -8))
						{
							int xdiff = this->X - Hero->X;
							if(xdiff > 0 && xdiff <= 17)
							{
								doPrompt = true;
							}
						}
						break;
					case DIR_RIGHT: //Right
						int ydiff = Hero->Y - this->Y;
						if((ydiff < (Hero->BigHitbox ? 16 : 8) && ydiff >= -8))
						{
							int xdiff = Hero->X - this->X;
							if(xdiff > 0 && xdiff <= 17)
							{
								doPrompt = true;
							}
						}
						break;
				}
				unless(doPrompt)
					continue;
				if(btnflags)
				{
					if(
						((btnflags & BIT_INTBTN_A) && Input->Press[CB_A])
						|| ((btnflags & BIT_INTBTN_B) && Input->Press[CB_B])
						|| ((btnflags & BIT_INTBTN_L) && Input->Press[CB_L])
						|| ((btnflags & BIT_INTBTN_R) && Input->Press[CB_R])
						|| ((btnflags & BIT_INTBTN_EX1) && Input->Press[CB_EX1])
						|| ((btnflags & BIT_INTBTN_EX2) && Input->Press[CB_EX2])
						|| ((btnflags & BIT_INTBTN_EX3) && Input->Press[CB_EX3])
						|| ((btnflags & BIT_INTBTN_EX4) && Input->Press[CB_EX4])
						)
					{
						continue;
					}
				}
				Screen->FastCombo(7, Hero->X + HXOFS, Hero->Y + HYOFS, prompt_combo, 0, OP_OPAQUE);
			}
		}
	}
}
