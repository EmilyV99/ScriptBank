genericdata script buttonHolder
{
	genericdata gd;
	void reinit()
	{
		if(int scr = CheckGenericScript("buttonHolder"))
			gd = Game->LoadGenericData(scr);
		gd->Running = true;
		gd->DataSize = 0;
		gd->DataSize = CB_MAX;
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
			for(int q = 0; q < CB_MAX; ++q)
			{
				if(this->Data[q])
				{
					if(Input->Button[q])
					{
						Input->Press[q] = false;
						Input->Button[q] = false;
					}
					else this->Data[q] = false;
				}
			}
			Waitframe();
		}
	}
	genericdata startHold(int button)
	{
		init();
		gd->Data[button] = true;
		return gd;
	}
	bool isHolding(int button)
	{
		init();
		return gd->Data[button];
	}
}