#include "std.zh"

@Author("EmilyV")
generic script RupeeArmor
{
	CONFIG ITEM_RUPEE_RING = -1; //Set this to the item ID you want to use
	/* Instructions:
	 * -- The following settings apply to the item:
	 * Attributes[0] = Number of rupees to drain
	 * Flags[0] = If checked, the number of rupees is per HP lost instead of per hit
	 * The item should not be of an itemclass that does anything- use a 'zz###' item class.
	 *     (You can rename the itemclass in 'Quest->ZInfo')
	 * -- The following should be set in "Init Data->GenScript" for this script
	 * -Run from Start
	 * -Event Listens: Hero Hit 1
	 */
	void run()
	{
		while(true)
		{
			switch(WaitEvent())
			{
				case GENSCR_EVENT_HERO_HIT_1:
				case GENSCR_EVENT_HERO_HIT_2:
				{
					if(ITEM_RUPEE_RING > -1 && Hero->Item[ITEM_RUPEE_RING])
					{
						itemdata id = Game->LoadItemData(ITEM_RUPEE_RING);
						int cost = id->Attributes[0];
						if(id->Flags[0]) //Charge the cost for each point of damage
						{
							int fullcost = cost*Game->EventData[GENEV_HEROHIT_DAMAGE];
							if(fullcost <= fullcounter(CR_RUPEES)) //Fully prevent the hit
							{
								Game->DCounter[CR_RUPEES] -= fullcost;
								Game->EventData[GENEV_HEROHIT_NULLIFY] = true;
							}
							else //Not enough money, prevent as much damage as possible
							{
								int numprev = Floor(fullcounter(CR_RUPEES) / cost);
								Game->DCounter[CR_RUPEES] -= cost*numprev;
								Game->EventData[GENEV_HEROHIT_DAMAGE] -= numprev;
							}
						}
						else //Charge the cost for each HIT, regardless of damage
						{
							if(cost <= fullcounter(CR_RUPEES))
							{
								Game->DCounter[CR_RUPEES] -= cost;
								Game->EventData[GENEV_HEROHIT_NULLIFY] = true;
							}
						}
					}
					break;
				}
			}
		}
	}
	int fullcounter(int cr)
	{
		return Game->Counter[cr] + Game->DCounter[cr];
	}
	CONST_ASSERT(ITEM_RUPEE_RING > -1 && ITEM_RUPEE_RING < NUM_ITEMDATA,
		"You must set the ITEM_RUPEE_RING constant to a valid item ID!");
}

