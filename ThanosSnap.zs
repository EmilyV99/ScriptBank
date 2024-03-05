//////////////////////////////
//       Thanos Snap        //
//          V1.01           //
//          Emily           //
//////////////////////////////
#option SHORT_CIRCUIT on
#option BINARY_32BIT off

namespace ThanosSnap
{
	typedef const int DEFINE;
	typedef const int CONFIG;
	@Author("Emily")
	itemdata script ThanosSnap
	{
		DEFINE FLAG_DELETEMODE = 0;
		CONFIG SNAP_COOLDOWN_COUNTER = 0; //The counter to use for the cooldown. Set to 0 to ignore.
		/**
		 * Settings:
		 * d0 - Charge up length, in frames
		 * d1 - Cooldown length, in seconds
		 * d2 - Counter to use for the cooldown; pass 0 for no counter (Use this to display the cooldown, for instance on the passive subscreen)
		 * Flags[0] - If checked, enemies killed will not drop items, and will not count as 'defeated' (as far as temp no return is concerned)
		 * Note: You will need to clear the counter used for the cooldown yourself, from a 'global script onLaunch' slot script, so that it does not carry
		 *     over when F6->Continue'ing.
		 */
		void run(int chargeFrames, int cooldownSeconds, int explodeEffect)
		{
			if(SNAP_COOLDOWN_COUNTER) Game->Counter[SNAP_COOLDOWN_COUNTER] = 0;
			bool swimming = Hero->Action == LA_SWIMMING || Hero->Action == LA_DIVING;
			for(int q = 0; q < chargeFrames; ++q)
			{
				if(Hero->Action == LA_GOTHURTLAND || Hero->Action == LA_GOTHURTWATER) Quit();
				Hero->Action = swimming ? LA_SWIMMING : LA_NONE;
				++Hero->Stun;
				WaitNoAction();
			}
			//
			int num = Floor(countSnappables()/2); //Snap only half of the living enemies (rounded down)
			
			while(num > 0)
			{
				for(int q = Screen->NumNPCs(); q > 0; --q) //start Snap enemies
				{
					if(num < 2) break;
					npc n = Screen->LoadNPC(q);
					unless(canSnap(n)) continue; //Skip unsnappables
					if(Rand(2)) continue; //Add RNG to which enemies are chosen to be snapped
					--num; //Since this was killable, subtract one from the kill counter
					n->Explode(explodeEffect); //Visual effect
					if(this->Flags[FLAG_DELETEMODE])
					{
						n->Remove();
					}
					else
					{
						n->HP = HP_SILENT; //Kill
					}
				} //end
			}
			Audio->PlaySound(this->UseSound);
			//
			for(int q = cooldownSeconds * 60; q; --q)
			{
				if(SNAP_COOLDOWN_COUNTER) Game->Counter[SNAP_COOLDOWN_COUNTER] = Ceiling(q/60);
				Waitframe();
			}
			if(SNAP_COOLDOWN_COUNTER) Game->Counter[SNAP_COOLDOWN_COUNTER] = 0;
		}
		
		int countSnappables()
		{
			int num;
			for(int q = Screen->NumNPCs(); q > 0; --q)
			{
				if(canSnap(Screen->LoadNPC(q))) ++num;
			}
			return num;
		}
		
		void canSnap(npc n)
		{
			switch(n->Type)
			{
				//Don't kill friendlies
				case NPCT_GUY:
				case NPCT_FAIRY:
				//Don't kill inanimate objects
				case NPCT_ROCK:
				case NPCT_TRAP:
				case NPCT_PROJECTILE:
				//Segmented enemies don't work
				case NPCT_MOLDORM:
				case NPCT_LANMOLA:
				//Don't kill Z1 Bosses
				case NPCT_AQUAMENTUS:
				case NPCT_DODONGO:
				case NPCT_MANHANDLA:
				case NPCT_GLEEOK:
				case NPCT_DIGDOGGER:
				case NPCT_GOHMA:
				case NPCT_PATRA:
				case NPCT_GANON:
					return false; //Immune types
			}
			if(n->MiscFlags & NPCMF_NOT_BEATABLE)
			{
				return false;
			}
			if(n->HP <= 0) return false; //Don't kill dying things
			if(n->Immortal) return false; //Don't kill immortal things
			// if(n->Script == Game->GetNPCScript("Name")) return false; //Don't kill enemies of a particular script
			
			return true;
		}
	}

	//Merge this with your global 'onExit' slot
	//If you are not using a counter, this can be ignored.
	@Author("Emily")
	global script ThanosSnapOnExit
	{
		void run()
		{
			if(ThanosSnap.SNAP_COOLDOWN_COUNTER)
			{
				Game->Counter[ThanosSnap.SNAP_COOLDOWN_COUNTER] = 0;
			}
		}
	}
}