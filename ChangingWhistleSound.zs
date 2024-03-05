#include "std.zh"

CONFIG ID_WHISTLE = I_WHISTLE;

CONST_ASSERT(ID_WHISTLE >= MIN_ITEMDATA && ID_WHISTLE <= MAX_ITEMDATA, "ID_WHISTLE must be a valid Item ID");

@Author("EmilyV"), @InitD0("SFX"), @InitDHelp0("The SFX the whistle should use for this screen.")
ffc script setWhistleSFX
{
	void run(int sfx)
	{
		Game->LoadItemData(ID_WHISTLE)->UseSound = sfx;
	}
}

@Author("EmilyV"), @InitD0("DefaultSFX"), @InitDHelp0("You don't need to set this; the WhistleSFXInit script handles it all for you.")
generic script resetWhistleSFX //Requires 0 setup, just assign to a slot
{
	void run(int default_sfx)
	{
        while(true)
        {
            switch(WaitEvent())
            {
                case GENSCR_EVENT_CHANGE_SCREEN:
                    Game->LoadItemData(ID_WHISTLE)->UseSound = default_sfx;
                    break;
            }
        }
	}
}

@Author("EmilyV"), @InitScript(-1000)
global script WhistleSFXInit //Requires 0 setup AND assigns ITSELF!
{
	void run()
	{
		if(int scr = CheckGenericScript("resetWhistleSFX"))
        {
            genericdata genscr = RunGenericScript(scr);
            genscr->InitD[0] = Game->LoadItemData(ID_WHISTLE)->UseSound;
		    genscr->EventListen[GENSCR_EVENT_CHANGE_SCREEN] = true;
        }
	}
}
