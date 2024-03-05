#include "std.zh"

generic script ButtonDisabler
{
	genericdata gd;
	void reinit()
	{
		if(int scr = CheckGenericScript("ButtonDisabler"))
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
	void add(int btn, int time)
	{
		init();
		gd->Data[btn] += time;
	}
	void set(int btn, int time)
	{
		init();
		gd->Data[btn] = time;
	}
	void run()
	{
		init();
		while(true)
		{
			WaitTo(SCR_TIMING_POST_POLL_INPUT, false);
			for(int q = 0; q < CB_MAX; ++q)
			{
				if(this->Data[q])
				{
					Input->Press[q] = false;
					Input->Button[q] = false;
					if(this->Data[q] > 0)
						--this->Data[q];
				}
			}
			Waitframe();
		}
	}
}
