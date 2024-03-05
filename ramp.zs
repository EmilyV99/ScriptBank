// TheBlueTophat
// Credits to EmilyV for helping improve the code.

const int CT_TRI = CT_SCRIPT1;

const int BITFLAG_TRI_BL = 1b;

const int MOUSE_COMBO = 4;

int mouse_cset = 11;

const long FLAG_ON_RAMP = 01Lb;
const long FLAG_IGNORE_RAMP = 10Lb;
const long FLAG_ABOVE_0_JUMP = 100Lb;

const int MISC_RAMP = 0;

global script GLOBAL//start	
{
	void run()
	{
		bool onRamp = false;
		bool checkRamp = false;
		
		Game->Cheat = 4;
		
		while(true)
		{
			updateMouse();
			
			Waitdraw();
			//printf("Before: Flags: %X\n", Hero->Misc[MISC_RAMP] / 1L);
			printf("Before: _ON_RAMP: %d, _IGNORE_RAMP: %d, _ABOVE_0_JUMP: %d\n", (Hero->Misc[MISC_RAMP] & FLAG_ON_RAMP) != 0,  (Hero->Misc[MISC_RAMP] & FLAG_IGNORE_RAMP) != 0, (Hero->Misc[MISC_RAMP] & FLAG_ABOVE_0_JUMP) != 0);
			handleRamps();
			printf("After:  _ON_RAMP: %d, _IGNORE_RAMP: %d, _ABOVE_0_JUMP: %d\n", (Hero->Misc[MISC_RAMP] & FLAG_ON_RAMP) != 0,  (Hero->Misc[MISC_RAMP] & FLAG_IGNORE_RAMP) != 0, (Hero->Misc[MISC_RAMP] & FLAG_ABOVE_0_JUMP) != 0);
			
			if(Hero->PressL)
			{
				Hero->Jump = 3;
				Game->PlaySound(SFX_JUMP);
			}
			
			
			
			mouse_cset = 11;
			
			Waitframe();
		}
	}
} //end

void updateMouse()
{
	Screen->FastCombo(7, Hero->InputMouseX, Hero->InputMouseY, MOUSE_COMBO, mouse_cset, OP_OPAQUE);
}

bool checkRamps()
{
	if(Hero->Jump > 0) return false;

	int x1, x2, y1, y2, m, b, hx, hy, dy;

	int posbr = ComboAt(Hero->X+15, Hero->Y+15), posbl = ComboAt(Hero->X, Hero->Y+15);
	combodata br = Game->LoadComboData(Screen->ComboD[posbr]),
			  bl = Game->LoadComboData(Screen->ComboD[posbl]);

	int posbr2 = ComboAt(Hero->X+3, Hero->Y+18), posbl2 = ComboAt(Hero->X+12, Hero->Y+18);
	combodata br2 = Game->LoadComboData(Screen->ComboD[posbr2]),
			  bl2 = Game->LoadComboData(Screen->ComboD[posbl2]);
			  
	int posbr3 = ComboAt(Hero->X+16, Hero->Y+16), posbl3 = ComboAt(Hero->X -1, Hero->Y+16);
	combodata br3 = Game->LoadComboData(Screen->ComboD[posbr3]),
			  bl3 = Game->LoadComboData(Screen->ComboD[posbl3]);
	
	if(br->Type == CT_TRI && !(br->UserFlags & BITFLAG_TRI_BL))
	{
		x1 = ComboX(posbr);
		x2 = x1+15;
		y1 = ComboY(posbr)+15;
		y2 = y1-15;
		hx = Hero->X + 15 - x1;
	}
	else if(bl->Type == CT_TRI && (bl->UserFlags & BITFLAG_TRI_BL))
	{
		x1 = ComboX(posbl) + 15;
		x2 = x1-15;
		y1 = ComboY(posbl) + 15;
		y2 = y1-15;
		hx = Hero->X - x1;
	}
	else if(br2->Type == CT_TRI && !(br2->UserFlags & BITFLAG_TRI_BL))
	{
		if(br3->Type == CT_TRI && !(br3->UserFlags & BITFLAG_TRI_BL))
		{
			x1 = ComboX(posbr3);
			x2 = x1+15;
			y1 = ComboY(posbr3)+15;
			y2 = y1-15;
			hx = Hero->X + 15 - x1;
		}
		else
		{
			if(Hero->Misc[MISC_RAMP] & FLAG_IGNORE_RAMP) return false;
		
			unless(Hero->Jump && Hero->Y <= ComboY(posbr2))
			{
				Hero->Y = GridY(Hero->Y + 8);
			}
			
			return true;
		}
		
	}
	else if(bl2->Type == CT_TRI && (bl2->UserFlags & BITFLAG_TRI_BL))
	{
		if(bl3->Type == CT_TRI && (bl3->UserFlags & BITFLAG_TRI_BL))
		{
			x1 = ComboX(posbl3) + 15;
			x2 = x1-15;
			y1 = ComboY(posbl3) + 15;
			y2 = y1-15;
			//b = 16;
			hx = Hero->X - x1;
		}
		else
		{
			if(Hero->Misc[MISC_RAMP] & FLAG_IGNORE_RAMP) return false;
		
			unless(Hero->Jump && Hero->Y <= ComboY(posbl2))
			{
				Hero->Y = GridY(Hero->Y + 8);
			}
			
			return true;
		}
	}
	else 
	{
		unless(br->Type == CT_TRI || bl->Type == CT_TRI)
		{
			Hero->Misc[MISC_RAMP] ~= FLAG_IGNORE_RAMP;
		}
		
		return false;
	}
	
	hy = Floor(Hero->Y + 15 - (y1));
	
	m = (x2-x1)/(y2-y1);
	dy = m*hx + b;
	
	int diff = (dy - hy) - 1;
	
	if(Hero->Misc[MISC_RAMP] & FLAG_ABOVE_0_JUMP)
	{
		if(diff < 0)
		{
			Hero->Misc[MISC_RAMP] |= FLAG_IGNORE_RAMP;
		}
	}
	
	if(Hero->Misc[MISC_RAMP] & FLAG_IGNORE_RAMP )
	{
		if(diff >= 0)
		{
			Hero->Misc[MISC_RAMP] ~= FLAG_IGNORE_RAMP;
		}
		else return false;
	}
	
	unless(Hero->Misc[MISC_RAMP] & FLAG_IGNORE_RAMP)
	{
		unless(Hero->Jump && diff >= 0 )
		{
			Hero->Y = Floor(Hero->Y + diff);
			return true;
		}		
	}
	
	return false;
}

void checkBehindRamps()
{
	//return; // debug
	int posbr = ComboAt(Hero->X, Hero->Y+12), posbl = ComboAt(Hero->X + 15, Hero->Y+12);
	combodata br = Game->LoadComboData(Screen->ComboD[posbr]),
			  bl = Game->LoadComboData(Screen->ComboD[posbl]);
			  
	if(br->Type == CT_TRI && !(br->UserFlags & BITFLAG_TRI_BL))
	{
		Hero->Misc[MISC_RAMP] |= FLAG_IGNORE_RAMP;
	}
	else if(bl->Type == CT_TRI && (bl->UserFlags & BITFLAG_TRI_BL))
	{
		Hero->Misc[MISC_RAMP] |= FLAG_IGNORE_RAMP;
	}
}

void handleRamps()
{
	if(Hero->Jump > 0)
	{
		Hero->Misc[MISC_RAMP] |= FLAG_ABOVE_0_JUMP;
	}

	checkBehindRamps();
	
	bool checkRamp = checkRamps();
	
	if(checkRamp)
	{
		Hero->Misc[MISC_RAMP] |= FLAG_ON_RAMP;
	
		Hero->Gravity = false;
	}
	else if(Hero->Misc[MISC_RAMP] & FLAG_ON_RAMP)
	{
		unless(Hero->Jump > 0)
		{
			Hero->Y = GridY(Hero->Y + 8);
		}
		
		Hero->Misc[MISC_RAMP] ~= FLAG_ON_RAMP;
	}
	
	if(Hero->Jump > 0)
	{
		Hero->Misc[MISC_RAMP] ~= FLAG_ON_RAMP;
	}
	
	unless(Hero->Misc[MISC_RAMP] & FLAG_ON_RAMP)
	{
		Hero->Gravity = true;
	}
	else
	{
		Hero->JumpCount = -1;
	}
	
	unless(Hero->Jump > 0)
	{
		Hero->Misc[MISC_RAMP] ~= FLAG_ABOVE_0_JUMP;
	}
}

void PX(int x, int y, int color)
{
	Screen->PutPixel(7, x, y, color, 0, 0, 0, OP_OPAQUE);
}