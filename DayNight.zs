///////////////////////////////////
//         Day/Night Tint        //
//             Emily             //
//         Version: 1.0          //
//           23 Jun 19           //
///////////////////////////////////
#option SHORT_CIRCUIT on
#option HEADER_GUARD on
#include "Tint.zh"

namespace DayNight
{
	using namespace TintZH;
	typedef const int CONFIG;
	typedef const bool CONFIGB;
	CONFIG DAY_LENGTH = 1; //In minutes, decimal not allowed
	CONFIGB ONLY_OUTDOORS = true; //Should this only apply when outdoors? (i.e. overworld screens)?
	//These are the RGB values for the tint:
	CONFIG NIGHT_R = -21;
	CONFIG NIGHT_G = -23;
	CONFIG NIGHT_B = -10;
	
	int NightTint = NULL; //Needs to be initialized by Tint.zh
	bool nightActive = false; //Start at daytime
	
	void initializeNightTint()
	{
		unless(NightTint)
			NightTint = createTintPalette(NIGHT_R, NIGHT_G, NIGHT_B);
	}
	
	void toggleNight()
	{
		nightActive = !nightActive;
	}
	
	void handleTint()
	{
		if(!ONLY_OUTDOORS || isOverworldScreen())
		{
			setTint(NightTint, nightActive);
		}
		else
		{
			setTint(NightTint,false);
		}
	}
	
	bool isOverworldScreen()
	{
		if(IsDungeonFlag() || IsInteriorFlag())return false;
		dmapdata dm = Game->LoadDMapData(Game->GetCurDMap());
		switch(dm->Type)
		{
			case DMAP_OVERWORLD:
			case DMAP_BSOVERWORLD:
				return true;
		}
		return false;
	}
}

global script DayNightActive //Example active script
{
	void run()
	{
		int frame = 0;
		int min = 0;
		while(true)
		{
			if(++frame >= 3600)
			{
				frame = 0;
				if(++min >= DayNight::DAY_LENGTH)
				{
					DayNight::toggleNight();
					min = 0;
				}
			}
			DayNight::handleTint();
			TintZH::runTints();
			Waitdraw();
			Waitframe();
		}
	}
}

global script DayNightInit
{
	void run()
	{
		TintZH::tintInit(); //Required by Tint.zh
		DayNight::initializeNightTint();
	}
}

global script DayNightOnContinue //Required by Tint.zh
{
	void run()
	{
		TintZH::tintOnContinue();
	}
}