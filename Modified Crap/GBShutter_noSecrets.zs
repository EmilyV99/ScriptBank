
ffc script GB_Shutter
{
	void run(int type, int perm)
	{
		int thisData = this->Data;
		int thisCSet = this->CSet;
		this->Data = FFCS_INVISIBLE_COMBO;
		int cp = ComboAt(this->X+8, this->Y+8);
		int underCombo = Screen->ComboD[cp];
		int underCSet = Screen->ComboC[cp];
		int LinkX = Link->X;
		if(perm&&dbit(1))
			Quit();
		if(LinkX<=0)
			LinkX = 240;
		else if(LinkX>=240)
			LinkX = 0;
		int LinkY = Link->Y;
		if(LinkY<=0)
			LinkY = 160;
		else if(LinkY>=160)
			LinkY = 0;
		int moveDir = Link->Dir;
		if(GB_Shutter_InShutter(this, LinkX, LinkY, 0))
		{
			if(LinkY==0)
				moveDir = DIR_DOWN;
			else if(LinkY==160)
				moveDir = DIR_UP;
			else if(LinkX==0)
				moveDir = DIR_RIGHT;
			else if(LinkX==240)
				moveDir = DIR_LEFT;
			Waitframe();
			while(GB_Shutter_InShutter(this, Link->X, Link->Y, 0)&&CanWalk(Link->X, Link->Y, moveDir, 1, false))
			{
				NoAction();
				if(moveDir==DIR_UP)
					Link->InputUp = true;
				else if(moveDir==DIR_DOWN)
					Link->InputDown = true;
				else if(moveDir==DIR_LEFT)
					Link->InputLeft = true;
				else if(moveDir==DIR_RIGHT)
					Link->InputRight = true;
				Waitframe();
			}
			//MooshPit_ResetEntry();
			Game->PlaySound(SFX_SHUTTER);
			Screen->ComboD[cp] = underCombo;
			Screen->ComboC[cp] = underCSet;
			this->Data = thisData+1;
			this->CSet = thisCSet;
			for(int i=0; i<4; i++)
			{
				if(moveDir==DIR_UP)
					Link->Y = Min(Link->Y, 144);
				else if(moveDir==DIR_DOWN)
					Link->Y = Max(Link->Y, 8);
				else if(moveDir==DIR_LEFT)
					Link->X = Min(Link->X, 224);
				else if(moveDir==DIR_RIGHT)
					Link->X = Max(Link->X, 16);
				Waitframe();
			}
			this->Data = FFCS_INVISIBLE_COMBO;
			Screen->ComboD[cp] = thisData;
			Screen->ComboC[cp] = thisCSet;
			if(type==1)
				Waitframes(8);
		}
		else
		{
			Screen->ComboD[cp] = thisData;
			Screen->ComboC[cp] = thisCSet;
			if(type==1)
				Waitframes(8);
			else
				Waitframe();
		}
		while(true)
		{
			if(GB_Shutter_InShutter(this, Link->X, Link->Y, 3)){
				Screen->ComboD[cp] = underCombo;
				Screen->ComboC[cp] = underCSet;
				if(Link->Y==0)
					moveDir = DIR_DOWN;
				else if(Link->Y==160)
					moveDir = DIR_UP;
				else if(Link->X==0)
					moveDir = DIR_RIGHT;
				else if(Link->X==240)
					moveDir = DIR_LEFT;
				while(GB_Shutter_InShutter(this, Link->X, Link->Y, 0)&&CanWalk(Link->X, Link->Y, moveDir, 1, false)){
					NoAction();
					if(moveDir==DIR_UP)
						Link->InputUp = true;
					else if(moveDir==DIR_DOWN)
						Link->InputDown = true;
					else if(moveDir==DIR_LEFT)
						Link->InputLeft = true;
					else if(moveDir==DIR_RIGHT)
						Link->InputRight = true;
					Waitframe();
				}
				Game->PlaySound(SFX_SHUTTER);
				Screen->ComboD[cp] = underCombo;
				Screen->ComboC[cp] = underCSet;
				this->Data = thisData+1;
				this->CSet = thisCSet;
				for(int i=0; i<4; i++){
					if(moveDir==DIR_UP)
						Link->Y = Min(Link->Y, 144);
					else if(moveDir==DIR_DOWN)
						Link->Y = Max(Link->Y, 8);
					else if(moveDir==DIR_LEFT)
						Link->X = Min(Link->X, 224);
					else if(moveDir==DIR_RIGHT)
						Link->X = Max(Link->X, 16);
					Waitframe();
				}
				this->Data = FFCS_INVISIBLE_COMBO;
				Screen->ComboD[cp] = thisData;
				Screen->ComboC[cp] = thisCSet;
				if(moveDir==DIR_UP)
					Link->Y = Min(Link->Y, 144);
				else if(moveDir==DIR_DOWN)
					Link->Y = Max(Link->Y, 8);
				else if(moveDir==DIR_LEFT)
					Link->X = Min(Link->X, 224);
				else if(moveDir==DIR_RIGHT)
					Link->X = Max(Link->X, 16);
				Waitframes(8);
			}
			if(type==0&&(Screen->ComboD[cp]!=thisData||Screen->ComboC[cp]!=thisCSet))
			{
				break;
			}
			if(type==1)
			{
				if(!GB_Shutter_CheckEnemies()){
					break;
				}
			}
			Waitframe();
		}
		Game->PlaySound(SFX_SHUTTER);
		Screen->ComboD[cp] = underCombo;
		Screen->ComboC[cp] = underCSet;
		this->Data = thisData+1;
		this->CSet = thisCSet;
		Waitframes(4);
		this->Data = FFCS_INVISIBLE_COMBO;
		if(perm)
			dbit(1, true);
	}
	bool GB_Shutter_InShutter(ffc this, int LinkX, int LinkY, int leeway)
	{
		if(Abs(LinkX-this->X)<16-leeway&&LinkY>this->Y-16+leeway&&LinkY<this->Y+8-leeway)
			return true;
		return false;
	}
	bool GB_Shutter_CheckEnemies()
	{
		for(int i=Screen->NumNPCs(); i>=1; i--){
			npc n = Screen->LoadNPC(i);
			if(n->Type!=NPCT_PROJECTILE&&n->Type!=NPCT_FAIRY&&n->Type!=NPCT_TRAP&&n->Type!=NPCT_GUY){
				if(!(n->MiscFlags&(1<<3)))
					return true;
			}
		}
		return false;
	}
	bool dbit(int bit)
	{
		return Screen->D[Div(bit,16)] & (1b << (bit%16));
	}
	void dbit(int bit, bool state)
	{
		if(state)
			Screen->D[Div(bit,16)] |= (1b << (bit%16));
		else
			Screen->D[Div(bit,16)] &= ~(1b << (bit%16));
	}
}