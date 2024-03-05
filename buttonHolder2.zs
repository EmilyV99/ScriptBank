genericdata script buttonHolder
{
	genericdata gd;
	void reinit()
	{
		if(int scr = CheckGenericScript("buttonHolder"))
			gd = Game->LoadGenericData(scr);
		gd->Running = true;
		gd->DataSize = 0;
		gd->DataSize = 2;
	}
	void init()
	{
		unless(gd)
		{
			reinit();
		}
	}
	void run()
	{
		while(true)
		{
			WaitTo(SCR_TIMING_POST_POLL_INPUT, false);
			if(this->Data[0])
			{
				if(Input->Button[this->Data[1]])
					NoAction();
				else this->Data[0] = false;
			}
			Waitframe();
		}
	}
	genericdata startHold(int button)
	{
		init();
		gd->Data[0] = true;
		gd->Data[1] = button;
		return gd;
	}
	bool isHolding()
	{
		init();
		return gd->Data[0];
	}
}
