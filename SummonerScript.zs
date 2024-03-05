typedef const int DEFINE;
typedef const int CONFIG;
@Author("Emily")
npc script Summoner
{
	DEFINE MAX_MAX_SUMMONED = 512; //If the parameter for MAX is above this, it will be truncated to this.
	/**
	 * d0: Max enemies to spawn
	 * d1: Frames to wait between spawns
	 * d2: If not set to 0, killing the summoner will kill all its' children
	 * d3-d8 are enemy IDs. Each time the summoner summons one, it will choose a random one from the InitD[].
	 * ID 0 is ignored.
	 */
	void run(int max, int RATE, bool ringleader, int n1, int n2, int n3, int n4, int n5)
	{
		RATE = Max(RATE, 1); //Rate of 0 would softlock, via endless loop, so don't allow it
		//start ID handling
		int IDs[5];
		int index = 0;
		if(n1) IDs[index++] = n1;
		if(n2) IDs[index++] = n2;
		if(n3) IDs[index++] = n3;
		if(n4) IDs[index++] = n4;
		if(n5) IDs[index++] = n5;
		DEFINE NUM_IDS = index;
		unless(NUM_IDS) Quit(); //If no enemies, nothing to summon
		//end ID handling
		DEFINE MAX_SPAWNED = VBound(max, MAX_MAX_SUMMONED, 0);
		npc Children[MAX_MAX_SUMMONED];
		Waitframes(RATE);
		until(this->HP<=0)
		{
			for(int q = 0; q < MAX_SPAWNED; ++q)
			{
				if(Children[q]->isValid()) continue;
				Children[q] = CreateNPCAt(IDs[Rand(NUM_IDS)], this->X, this->Y);
				break;
			}
			for(int q = 0; (q < RATE) && !(this->HP<=0); ++q)
			{
				Waitframe();
			}
		}
		unless(ringleader) Quit();
		for(int q = 0; q < MAX_SPAWNED; ++q)
		{
			if(Children[q]->isValid())
			{
				Children[q]->HP = -1000;
			}
		}
	}
}