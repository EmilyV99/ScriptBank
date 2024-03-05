#option HEADER_GUARD on
#include "std.zh"

CONFIG EWMISC_STATUS = 0;
namespace Status
{
	enum Status
	{
		ITEMJINX,
		SWORDJINX,
		STUN,
		BUNNY,
		NUM_MISC_STATS,
		//
		SLOW = NUM_MISC_STATS,
		PEGASUS,
		ONFIRE,
		NUM_STATS
	};
	genericdata status;
	
	@Author("EmilyV")
	generic script StatusEffects
	{
		void run()
		{
			status = this;
			//Reset the data array; clear all status effects
			this->DataSize = 0;
			this->DataSize = NUM_STATS;
			while(true)
			{
				//BEFORE DECREMENT
				{
					//Deal fire damage, 1 heart every second
					if(this->Data[ONFIRE] && (this->Data[ONFIRE]%60==1))
						Hero->HP -= 16;
				}
				//MAIN DECREMENT
				{
					//Grab engine counters, incase anything reads this?
					for(int q = 0; q < NUM_MISC_STATS; ++q)
						this->Data[q] = get(<Status>q);
					//Decrement counters
					for(int q = NUM_MISC_STATS; q < NUM_STATS; ++q)
						if(this->Data[q] > 0)
							--this->Data[q];
				}
				//AFTER DECREMENT
				{
					//Set the player's speed
					int step = 150;
					if(this->Data[SLOW] && this->Data[PEGASUS])
						step = 125;
					else if(this->Data[SLOW])
						step = 75;
					else if(this->Data[PEGASUS])
						step = 300;
					
					Hero->Step = step;
				}
				Waitframe();
			}
		}
	}
	
	@Author("EmilyV")
	generic script HitEffects
	{
		void run()
		{
			this->EventListen[GENSCR_EVENT_HERO_HIT_2] = true;
			while(true)
			{
				until(WaitEvent() == GENSCR_EVENT_HERO_HIT_2);
				
				switch(Game->EventData[GENEV_HEROHIT_HITTYPE])
				{
					case OBJTYPE_EWPN:
					{
						eweapon weap = Game->EventData[GENEV_HEROHIT_HITOBJ];
						if(int arr = weap->Misc[EWMISC_STATUS])
						{
							int sz = Min(NUM_STATS, SizeOfArray(arr));
							for(int q = 0; q < sz; ++q)
								if(arr[q])
									set(<Status>(q),arr[q]);
						}
						break;
					}
				}
			}
		}
	}
	
	bool initStatus()
	{
		if(status) return true;
		if(int scr = CheckGenericScript("StatusEffects"))
			status = RunGenericScript(scr);
		return status != NULL;
	}
	void set(Status s, int duration, bool min = true)
	{
		if(min && get(s) > duration)
			return; //Don't shorten the effect
		if(s < NUM_MISC_STATS)
		{
			switch(s)
			{
				case ITEMJINX:
					Hero->ItemJinx = duration;
					break;
				case SWORDJINX:
					Hero->SwordJinx = duration;
					break;
				case STUN:
					Hero->Stun = duration;
					break;
				case BUNNY:
					if(Hero->BunnyClk > -1)
						Hero->BunnyClk = duration;
					break;
			}
		}
		unless(initStatus())
			return;
		status->Data[s] = duration;
	}
	int get(Status s)
	{
		if(s < NUM_MISC_STATS)
		{
			switch(s)
			{
				case ITEMJINX:
					return Hero->ItemJinx;
				case SWORDJINX:
					return Hero->SwordJinx;
				case STUN:
					return Hero->Stun;
				case BUNNY:
					return Hero->BunnyClk;
			}
			return 0;
		}
		unless(initStatus())
			return 0;
		return status->Data[s];
	}
	
	int make_status_arr(eweapon ew)
	{
		int arrptr = ew->Misc[EWMISC_STATUS];
		unless(arrptr)
		{
			int new_arr[NUM_STATS];
			arrptr = new_arr;
			ew->OwnArray(new_arr);
			ew->Misc[EWMISC_STATUS] = new_arr;
		}
		return arrptr;
	}
	void set_ew_status(eweapon ew, untyped arr)
	{
		int sz = SizeOfArray(arr);
		if(sz%2) --sz;
		int arrptr = make_status_arr(ew);
		for(int q = 0; q < sz; q += 2)
		{
			arrptr[arr[q]] = arr[q+1];
		}
	}
	void set_ew_status(eweapon ew, untyped status, int duration)
	{
		int arrptr = make_status_arr(ew);
		arrptr[status] = duration;
	}
}

namespace Status::ExampleScripts
{
	@Author("EmilyV"), @InitD0("Seconds"),
	@InitDHelp0("Seconds the player will be pegasus-boosted for.")
	itemdata script pegasusSeed
	{
		void run(int seconds)
		{
			Status::set(Status::PEGASUS, 60*seconds);
		}
	}
	
	@Author("EmilyV"), @InitD0("Seconds"),
	@InitDHelp0("Seconds the player will burn for, after being hit by this weapon."
		"\n1 heart per second damage.")
	eweapon script burnyWeapon
	{
		void run(int seconds)
		{
			Status::set_ew_status(this, Status::ONFIRE, 60*seconds);
			QuitNoKill();
		}
	}
	
	@Author("EmilyV"), @InitD0("Seconds"),
	@InitDHelp0("Seconds the player will be slowed for, after being hit by this weapon.")
	eweapon script slowWeapon
	{
		void run(int seconds)
		{
			Status::set_ew_status(this, Status::SLOW, 60*seconds);
			QuitNoKill();
		}
	}
	
	@Author("EmilyV"), @InitD0("Seconds"),
	@InitDHelp0("Seconds the player will be a bunny for, after being hit by this weapon.")
	eweapon script bunnyWeapon
	{
		void run(int seconds)
		{
			Status::set_ew_status(this, Status::BUNNY, 60*seconds);
			QuitNoKill();
		}
	}
}
