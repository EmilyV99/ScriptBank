
untyped wrap(untyped x, int mod) //math-y stuff.
{
    if(x < 0)
        return (mod-(-x%mod))%mod;
    return x%mod;
}
namespace Costumes
{
	typedef const int CONFIG;
	CONFIG I_DUMMY_COSTUME = 0; //the dummy costume item ID
	CONFIG COSTUME_PREVIEW_TILE = 0;
	CONFIG CB_COSTUME_MENU = CB_L; //which button to open the costume menu
	CONFIG SFX_SWAP = 0;
	CONFIG SFX_ERROR = 0;
	CONFIG SFX_OPENMENU = 0;
	CONFIG SFX_CLOSEMENU = 0;
	CONFIG C_BLACK = 0x0F; //A black color
	CONFIG C_WHITE = 0x01; //A white color
	enum Costume
	{
		COSTUME_LINK,
		COSTUME_ZELDA,
		COSTUME_WHATEVERELSE,
		MAX_COSTUME
	};
	int getTileMod(Costume c)
	{
		switch(c)
		{
			case COSTUME_LINK: return 0;
			case COSTUME_ZELDA: return 200;
			case COSTUME_WHATEVERELSE: return 400;
		}
		return 0; //in case of error
	}
	
	CONST_ASSERT(I_DUMMY_COSTUME > 0 && I_DUMMY_COSTUME <= MAX_ITEMDATA, "I_DUMMY_COSTUME must be set to an item ID of a dummy item!");
	
	Costume currentCostume;
	bool ownedCostumes[MAX_COSTUME] = {true};
	void equipCostume(Costume c)
	{
		if(c < 0 || c >= MAX_COSTUME)
			return; //invalid costume
		currentCostume = c;
		Hero->Item[I_DUMMY_COSTUME] = true;
		itemdata dummy = Game->LoadItemData(I_DUMMY_COSTUME);
		dummy->Modifier = getTileMod(c);
	}
	void setCostume(Costume c, bool owned)
	{
		ownedCostumes[c] = owned;
	}
	
	void cycleCostumeRight()
	{
		untyped c = currentCostume;
		do c = wrap(c+1,MAX_COSTUME); until(c == currentCostume || ownedCostumes[c]);
		if(c == currentCostume)
		{
			if(SFX_ERROR) Audio->PlaySound(SFX_ERROR);
		}
		else
		{
			if(SFX_SWAP) Audio->PlaySound(SFX_SWAP);
			equipCostume(c);
		}
	}
	void cycleCostumeLeft()
	{
		untyped c = currentCostume;
		do c = wrap(c-1,MAX_COSTUME); until(c == currentCostume || ownedCostumes[c]);
		if(c == currentCostume)
		{
			if(SFX_ERROR) Audio->PlaySound(SFX_ERROR);
		}
		else
		{
			if(SFX_SWAP) Audio->PlaySound(SFX_SWAP);
			equipCostume(c);
		}
	}
	
	itemdata script pickupCostume
	{
		void run(Costume costumeID)
		{
			setCostume(costumeID, true);
		}
	}
	generic script CostumeButtonManager
	{
		void run()
		{
			if(this->DataSize) //run menu
			{
				if(SFX_OPENMENU) Audio->PlaySound(SFX_OPENMENU);
				Costume c = currentCostume;
				bitmap bg = Game->CreateBitmap(256,256);
				bg->Clear(0);
				DEFINE BOX_WID = 32;
				DEFINE BOX_X = (256-BOX_WID)/2;
				DEFINE BOX_Y = (224-BOX_WID)/2;
				DEFINE BOX_T_X = (256-16)/2;
				DEFINE BOX_T_Y = (224-16)/2;
				bg->Rectangle(0, BOX_X, BOX_Y, BOX_X+BOX_WID-1, BOX_Y+BOX_WID-1, C_WHITE, -1, 0, 0, 0, true, OP_OPAQUE);
				bg->Rectangle(0, BOX_X+3, BOX_Y+3, BOX_X+BOX_WID-1-3, BOX_Y+BOX_WID-1-3, C_BLACK, -1, 0, 0, 0, true, OP_OPAQUE);
				bg->PutPixel(0, BOX_X, BOX_Y, 0, 0, 0, 0, OP_OPAQUE);
				bg->PutPixel(0, BOX_X, BOX_Y+BOX_WID-1, 0, 0, 0, 0, OP_OPAQUE);
				bg->PutPixel(0, BOX_X+BOX_WID-1, BOX_Y, 0, 0, 0, 0, OP_OPAQUE);
				bg->PutPixel(0, BOX_X+BOX_WID-1, BOX_Y+BOX_WID-1, 0, 0, 0, 0, OP_OPAQUE);
				Waitframe();
				while(true)
				{
					if(Hero->PressA || Hero->PressStart)
						break;
					if(Hero->PressB)
					{
						equipCostume(c);
						break;
					}
					if(Hero->PressRight || Hero->PressR)
						cycleCostumeRight();
					else if(Hero->PressLeft || Hero->PressL)
						cycleCostumeLeft();
					
					int tile = COSTUME_PREVIEW_TILE + getTileMod(currentCostume);
					bg->Blit(6, RT_SCREEN, 0, 0, 256, 224, 0, -56, 256, 224, 0, 0, 0, 0, 0, true);
					Screen->FastTile(6, BOX_T_X, BOX_T_Y-56, tile, 6, OP_OPAQUE);
					Waitframe();
				}
				if(SFX_CLOSEMENU) Audio->PlaySound(SFX_CLOSEMENU);
				return;
			}
			do
			{
				WaitTo(SCR_TIMING_POST_POLL_INPUT, true);
				if(Input->Press[CB_COSTUME_MENU])
				{
					this->DataSize = 1;
					this->RunFrozen();
					this->DataSize = 0;
				}
				Input->Press[CB_COSTUME_MENU] = false;
				Input->Button[CB_COSTUME_MENU] = false;
				Waitframe();
			} while(true);
		}
	}
	void runHandler()
	{
		int gdid = Game->GetGenericScript("CostumeButtonManager");
		if(gdid < 0)
		{
			printf("ERROR: Generic Script 'CostumeButtonManager' must be assigned to a slot!\n");
			return;
		}
		Game->LoadGenericData(gdid)->Running = true;
	}
}

global script ExampleCostumeActive
{
	void run()
	{
		Costumes::runHandler();
	}
}
