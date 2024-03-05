//Global script file

global script Active //start
{
	void run()
	{
		//one-time things here
		while(true)
		{
			//Pre-waitdraw loop items here
			Waitdraw();
			//Post-waitdraw loop items here
			Waitframe();
		}
	}
} //end

global script onLaunch //start Runs on a new game, or loading a save
{
	void run()
	{
		fishing::initFishingRNG();
	}
} //end

