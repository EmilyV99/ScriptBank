#option HEADER_GUARD on
#include "std.zh"
typedef const int DEFINE;
typedef const int CONFIG;

//Merge with any existing global active script
@Author("EmilyV99")
global script bottle_Active
{
	void run()
	{
		while(true)
		{
			CustomBottle::checkCustomBottles();
			Waitframe();
		}
	}
}

CONFIG CR_FX_HALFMAGIC = CR_CUSTOM1;
CONFIG CR_FX_INFMAGIC = CR_CUSTOM2;
namespace CustomBottle
{
	/* Setup Instructions
	 * Set the configs above to the counters you wish to use (Defaults provided)
	 * Set the bottle type to add a number (in frames of effect) to these counters
	 * !IMPORTANT! make sure the MAX for these counters is high enough in Init Data!
	 */
	enum
	{
		BD_OLD_DRAINRATE,
		BD_HALFMAGIC,
		BD_INFMAGIC,
		BD_SZ
	};
	untyped bottle_data[BD_SZ];
	void checkCustomBottles()
	{
		if(Game->Counter[CR_FX_INFMAGIC]) //Inf magic active
		{
			--Game->Counter[CR_FX_INFMAGIC];
			unless(bottle_data[BD_INFMAGIC]) //Just activated inf magic
			{
				bottle_data[BD_INFMAGIC] = true;
				unless(bottle_data[BD_HALFMAGIC]) //don't store the halved rate!
					bottle_data[BD_OLD_DRAINRATE] = Game->Generic[GEN_MAGICDRAINRATE];
				Game->Generic[GEN_MAGICDRAINRATE] = 0;
			}
			//Disable halfmagic if infmagic is active
			Game->Counter[CR_FX_HALFMAGIC] = 0;
			bottle_data[BD_HALFMAGIC] = false;
		}
		else if(bottle_data[BD_INFMAGIC]) //Just deactivated inf magic
		{
			bottle_data[BD_INFMAGIC] = false;
			Game->Generic[GEN_MAGICDRAINRATE] = bottle_data[BD_OLD_DRAINRATE];
		}
		
		if(Game->Counter[CR_FX_HALFMAGIC]) //Half magic active
		{
			--Game->Counter[CR_FX_HALFMAGIC];
			unless(bottle_data[BD_HALFMAGIC]) //Just activated half magic
			{
				bottle_data[BD_HALFMAGIC] = true;
				bottle_data[BD_OLD_DRAINRATE] = Game->Generic[GEN_MAGICDRAINRATE];
				Game->Generic[GEN_MAGICDRAINRATE] = 1;
			}
		}
		else if(bottle_data[BD_HALFMAGIC]) //Just deactivated half magic
		{
			bottle_data[BD_HALFMAGIC] = false;
			Game->Generic[GEN_MAGICDRAINRATE] = bottle_data[BD_OLD_DRAINRATE];
		}
	}
}
