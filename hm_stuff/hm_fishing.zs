namespace fishing
{
	randgen fishRNG;
	
	void initFishingRNG() //start
	{
		unless(fishRNG)
			fishRNG = Game->LoadRNG();
		fishRNG->SRand();
	} //end
	
	enum fishType //start
	{
		FISH_NONE,
		FISH_SALMON,
		FISH_TUNA,
		NUM_FISH_TYPES
	}; //end
	
	enum waterType //start
	{
		WTR_LAKE,
		WTR_RIVER,
		NUM_WTR_TYPE
	}; //end
	
	fishType selectFish(waterType wt) //start
	{
		switch(wt)
		{
			case WTR_LAKE:
			{
				switch(fishRNG->Rand(99)) //0-99, inclusive
				{
					case 0...49: //0-49, inclusive
						return FISH_TUNA;
					default: //No bite, maybe select a trash item?
						return FISH_NONE;
				}
			}
			case WTR_RIVER:
			{
				switch(fishRNG->Rand(99)) //0-99, inclusive
				{
					case 0...49:
						return FISH_SALMON;
					case 50...74:
						return FISH_TUNA;
					default: //No bite, maybe select a trash item?
						return FISH_NONE;
				}
			}
		}
		return FISH_NONE; //Shouldn't be reachable, but to be safe...
	} //end
}