#option HEADER_GUARD on
#include "std.zh"

@Author("EmilyV")
combodata script LightPulseCombo
{
	/** Setup:
	 * InitD[0]: Number of pixels to grow by from the min radius
	 * InitD[1]: Number of pixels to grow per frame
	 * Attribytes[7]: Starting (minimum) radius
	 */
    void run(int range, int rate)
    {
		int min = this->Attribytes[7];
		LightPulseManager.go();
		LightPulseManager.add(this, min, range, rate);
    }
}

@Author("EmilyV")
generic script LightPulseManager
{
	CONFIGB DEBUG = false;
	genericdata gd;
	void run()
	{
		unless(gd)
			gd = this;
		while(true)
		{
			for(int q = 0; q < this->DataSize; q += LPM_COUNT)
			{
				calc(q);
			}
			preserve_time_clock();
			Waitframe();
		}
	}
	
	//Start the script
	void go()
	{
		loadgd();
		if(!gd->Running)
			gd->Running = true;
	}
	
	//Ensure the global variable of the genericdata is loaded
	void loadgd()
	{
		unless(gd)
			gd = Game->LoadGenericData(Game->GetGenericScript("LightPulseManager"));
	}
	
	//Clear all the combos in the queue
	void clear()
	{
		loadgd();
		gd->DataSize = 0;
	}
	
	enum //Some constants for the data array
	{
		LPM_CD,
		LPM_MIN,
		LPM_RANGE,
		LPM_RATE,
		LPM_COUNT
	};
	
	//Add a given combo to the animation, with its' own parameters
	void add(combodata cd, int min, int range, int rate)
	{
		loadgd();
		int q;
		for(q = 0; q < gd->DataSize; q += LPM_COUNT)
		{
			if(gd->Data[q] == cd)
			{
				gd->Data[q+LPM_MIN] = min;
				gd->Data[q+LPM_RANGE] = range;
				gd->Data[q+LPM_RATE] = rate;
				return;
			}
		}
		gd->DataSize += LPM_COUNT;
		gd->Data[q+LPM_CD] = cd;
		gd->Data[q+LPM_MIN] = min;
		gd->Data[q+LPM_RANGE] = range;
		gd->Data[q+LPM_RATE] = rate;
	}
	
	//Calculates the radius for the current frame, at a given offset of the data array
	void calc(int offs)
	{
		loadgd();
		if(offs % LPM_COUNT)
		{
			int newoffs = offs - (offs % LPM_COUNT);
			if(DEBUG)
				printf("[LightPulseManager.calc()] Bad offset '%d' used. Assuming '%d' instead!", offs, newoffs);
			offs = newoffs;
		}
		
		int range = gd->Data[offs+LPM_RANGE];
		int rate = gd->Data[offs+LPM_RATE];
		int time1 = Ceiling(range/rate); //How many frames of animation does it take to reach max?
		int time2 = time1*2; //How many frames of animation to get back to min again?
		int num_frame = (Game->Time % (1L*time2))/1L; //We can skip full loops, so modulo down the frame number
		
		int val = gd->Data[offs+LPM_MIN];
		for(int q = 0; q < num_frame; ++q)
		{
			if(q < time1)
				val += rate;
			else val -= rate;
		}
		<combodata>(gd->Data[offs+LPM_CD])->Attribytes[0] = val;
	}
	
	//Makes sure 'Game->Time' never maxes out
	void preserve_time_clock()
	{
		//Loop the 'playtime' value used as a clock if it gets too high
		if(Game->Time == MAX_TIME)
			Game->Time = 0;
	}
}
