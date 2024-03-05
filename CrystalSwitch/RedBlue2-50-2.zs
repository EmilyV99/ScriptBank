//Red/Blue Crystal Switch Script - Emily - Version 1.0 (10/13/2018)

import "std.zh"

//Instructions:
//Set constants below
//Place FFC CrystalSwitch wherever you want a switch to be. You probably want to place a solid combo under it so that Link cannot walk through it.

const int COMBO_REDUP_WALKABLE = 0; //Combo for Red block in the Up position (Walkable, inherent flag "No Ground Enemies")
const int COMBO_REDUP = 0; //Combo for Red block in Up position (solid)
const int COMBO_REDDOWN = 0; //Combo for Red block in Down position (walkable)

const int COMBO_RED_GOINGDOWN = 0; //Animated combo of a red block going from up to down, combo cycle to COMBO_REDDOWN
const int COMBO_RED_GOINGUP = 0; //Animated combo of a red block going from down to up, combo cycle to COMBO_REDUP

const int COMBO_BLUEUP_WALKABLE = 0; //Combo for Blue block in the Up position (Walkable, inherent flag "No Ground Enemies")
const int COMBO_BLUEUP = 0; //Combo for Blue block in Up position (solid)
const int COMBO_BLUEDOWN = 0; //Combo for Blue block in Down position (walkable)

const int COMBO_BLUE_GOINGDOWN = 0; //Animated combo of a blue block going from up to down, combo cycle to COMBO_BLUEDOWN
const int COMBO_BLUE_GOINGUP = 0; //Animated combo of a blue block going from down to up, combo cycle to COMBO_BLUEUP

const int COMBO_REDSWITCH = 0; //Combo for switch (red colored; red blocks are DOWN)
const int COMBO_BLUESWITCH = 0; //Combo for switch (blue colored; blue blocks are DOWN)

const int MAX_LEVEL_USED = 16; //The highest DMap Level # which will have switches/blocks on it

const int DEFAULT_RED_UP = 1; //Change to '0' to begin with blue up
const int SEPARATE_PER_LEVEL = 1; //Change to '0' to have all levels share switch states
const int CAN_WALK_ON_TOP = 1; //Change to '0' to prevent walking on top. Warning: Be careful not to create a situation in which Link can get stuck!


int lweapon_blacklist[] = {LW_BOMB, LW_SBOMB, LW_FIRE, LW_WHISTLE, LW_BAIT, LW_WIND, LW_SPARKLE, LW_FIRESPARKLE};
//LWeapons that will not trigger crystal switches
//Valid options:
//LW_SWORD, LW_WAND, LW_CANDLE, LW_HAMMER, LW_HOOKSHOT, LW_CANEOFBYRNA, LW_ARROW, LW_BEAM, LW_BRANG, LW_BOMB, LW_BOMBBLAST, LW_SBOMB, LW_SBOMBBLAST, LW_FIRE, LW_WHISTLE,
//LW_BAIT, LW_MAGIC, LW_WIND, LW_REFMAGIC, LW_REFFIREBALL, LW_REFROCK, LW_REFBEAM, LW_SPARKLE, LW_FIRESPARKLE, LW_SCRIPT1, LW_SCRIPT2, LW_SCRIPT3, LW_SCRIPT4, LW_SCRIPT5,
//LW_SCRIPT6, LW_SCRIPT7, LW_SCRIPT8, LW_SCRIPT9, LW_SCRIPT10
//(Any LW_ constant from std_constants.zh)

bool redIsUp[16];//You MUST set the number here to the same as MAX_LEVEL_USED. Very important.
bool linkOnRaised = false;

//This is an example Init script. If you already have an init script, you can remove this, and just call `initCrystalSwitch()` in your init script.
global script Init
{
	void run()
	{
		initCrystalSwitch();
	}
}

void initCrystalSwitch()
{
	for(int i = 0; i < MAX_LEVEL_USED; ++i)
	{
		redIsUp[i] = DEFAULT_RED_UP;
	}
}

//This is an example active script. If you have your own, you will need to merge this with it.
global script CrystalSwitchActive
{
    void run()
	{
        int lastScreen = Game->GetCurScreen();
        int lastMap = Game->GetCurMap();
        int lastLevel = Game->GetCurLevel();
        while(true)
		{
            if(Game->GetCurScreen() != lastScreen || Game->GetCurMap() != lastMap || Game->GetCurLevel() != lastLevel)
			{
                lastScreen = Game->GetCurScreen();
                lastMap = Game->GetCurMap();
                lastLevel = Game->GetCurLevel();
                checkSwitchCombos(true);
            }
			if(CAN_WALK_ON_TOP)checkLinkOnRaised();
            Waitframe();
        }
    }
}

ffc script crystalSwitch
{
	void run()
	{
		bool collided = false;
		bool redup = getSwitchState();
		while(true)
		{
			if(redup)this->Data = COMBO_BLUESWITCH;
			else this->Data = COMBO_REDSWITCH;
			bool collision = HitByValidLWeapon(this);
        	if(collision && !collided)
			{
				redup = !redup;
				setSwitchState(redup);
            	checkSwitchCombos();
            	collided = true;
        	}
			else if(!collision && collided)
			{
            	collided = false;
        	}
        	Waitframe();
    	}
	}
}

bool HitByValidLWeapon(ffc f)
{
	for(int q = Screen->NumLWeapons();q>0;--q)
	{
		lweapon weap = Screen->LoadLWeapon(q);
		if(!isValidType(weap))continue;
		if(Collision(f,weap))
		{
			return true;
		}
	}
	return false;
}

bool isValidType(lweapon l)
{
    for ( int q = SizeOfArray(lweapon_blacklist)-1; q >= 0; --q )
    {
        if ( l->ID == lweapon_blacklist[q] ) return false;
    }
    return true;
}

void checkSwitchCombos(bool ignoreTransitions)
{
	bool redup = getSwitchState();
	int redup_combo = COMBO_RED_GOINGUP;
	int reddown_combo = COMBO_RED_GOINGDOWN;
	int blueup_combo = COMBO_BLUE_GOINGUP;
	int bluedown_combo = COMBO_BLUE_GOINGDOWN;
	if(ignoreTransitions)
	{
		redup_combo = COMBO_REDUP;
		reddown_combo = COMBO_REDDOWN;
		blueup_combo = COMBO_BLUEUP;
		bluedown_combo = COMBO_BLUEDOWN;
	}
    for(int i = 0; i < 176; i++)
	{
        if(redup)
		{
            if(Screen->ComboD[i] == COMBO_REDDOWN)Screen->ComboD[i] = redup_combo;
            else if(Screen->ComboD[i] == COMBO_BLUEUP || Screen->ComboD[i] == COMBO_BLUEUP_WALKABLE)Screen->ComboD[i] = bluedown_combo;
        }
		else
		{
            if(Screen->ComboD[i] == COMBO_REDUP || Screen->ComboD[i] == COMBO_REDUP_WALKABLE)Screen->ComboD[i] = reddown_combo;
            else if(Screen->ComboD[i] == COMBO_BLUEDOWN)Screen->ComboD[i] = blueup_combo;
        }
    }
}

void checkSwitchCombos()
{
	checkSwitchCombos(false);
}

int getSwitchIndex()
{
	if(SEPARATE_PER_LEVEL)
	{
		if(Game->GetCurLevel() > MAX_LEVEL_USED)
		{
			int s[] = "ERROR: LEVEL GREATER THAN MAX_LEVEL_USED!";
			TraceS(s);
			return 0;
		}
		return Game->GetCurLevel();
	}
	else return 0;
}

void setSwitchState(bool state)
{
	int index = getSwitchIndex();
	redIsUp[index] = state;
}

bool getSwitchState()
{
	int index = getSwitchIndex();
	return redIsUp[index];
}

void checkWalkableCombos()
{
	for(int i = 0; i < 176; i++)
	{
		if(linkOnRaised)
		{
			if(Screen->ComboD[i] == COMBO_BLUEUP)Screen->ComboD[i] = COMBO_BLUEUP_WALKABLE;
			if(Screen->ComboD[i] == COMBO_REDUP)Screen->ComboD[i] = COMBO_REDUP_WALKABLE;
		}
		else
		{
			if(Screen->ComboD[i] == COMBO_BLUEUP_WALKABLE)Screen->ComboD[i] = COMBO_BLUEUP;
			if(Screen->ComboD[i] == COMBO_REDUP_WALKABLE)Screen->ComboD[i] = COMBO_REDUP;
		}
    }
}

void checkLinkOnRaised()
{
	int cd = comboUnderLink();
	if(linkOnRaised)
	{
		if(cd != COMBO_BLUEUP_WALKABLE && cd != COMBO_REDUP_WALKABLE)
		{
			linkOnRaised = false;
			checkWalkableCombos();
		}
	}
	else
	{
		if(cd == COMBO_BLUEUP || cd == COMBO_REDUP)
		{
			linkOnRaised = true;
			checkWalkableCombos();
		}
	}
}

int comboUnderLink()
{
	return Screen->ComboD[ComboAt(Link->X+8,Link->Y+12)];
}