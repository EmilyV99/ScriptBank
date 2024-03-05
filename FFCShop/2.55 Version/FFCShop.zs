//////////////////////
//     FFC Shop     //
//       v2.0       //
//      EmilyV      //
//////////////////////
#option SHORT_CIRCUIT on
#option HEADER_GUARD on
#option BINARY_32BIT off
#include "TangoHandler.zh"

namespace FFCShop
{
	typedef const int DEFINE;
	typedef const int CONFIG;
	typedef const bool CONFIGB;
	
	CONFIG COMBO_SHOP_INVIS = 4; //A non-combo-0 invisible combo
	CONFIG COMBO_SHOP_OUT_OF_STOCK = 65028; //A combo to display if the shop is "out of stock"
	CONFIG FONT_PRICEDISPLAY = FONT_Z3SMALL; //Font to use for the price display
	CONFIG COLOR_PRICETEXT = 0x01; //Color for price display
	CONFIG LAYER_PRICETEXT = 2;
	CONFIG SIZE_SHOPDATA = 2000; //Must be larger than the highest shopIndex you use!

	bool UniqueShopData[SIZE_SHOPDATA];
	@Author("EmilyV99")
	ffc script FFCShop
	{
		void run(int itemID, int price, int shopSpecial, int visualYOffset, int priceYOffset, bool reqBottle, bool hidePrice, int shopIndex)
		{
			this->Data=COMBO_SHOP_INVIS;
			DEFINE TILE_SHOP_INVIS = Game->LoadComboData(COMBO_SHOP_INVIS)->Tile;
			this->Y += visualYOffset;
			itemdata idata = Game->LoadItemData(itemID);
			switch(shopSpecial)
			{
				//If this shop needs to do anything special, put that code here.
				//For instance, not allowing buying a given item more than once, or something.
				case 1:
				{
					unless(idata->Keep) shopSpecial = 0; //Only works for equipment items!
					break;
				}
				case 2:
				{
					if(shopIndex < 0 || shopIndex >= SIZE_SHOPDATA) shopSpecial = 0; //Don't run on a negative index!
					break;
				}
			}
			unless(itemID) Quit(); //No item to sell.
			char32 shopbuystr[] = "Hello, would you like to buy ((@string(@shopstr))) for [[@number(@sprice)]] rupees? @26<<@choice(1)Yes@choice(2)No>>@domenu(1)@if(@equal(@chosen 1) @set(@ttemp 1))@close()";
			char32 boughtstr[] = "Thank you for your purchase!";
			char32 notboughtstr[] = "No? Well if you need anything else, just ask.";
			char32 nobottlestr[] = "This ((@string(@shopstr))) costs [[@number(@sprice)]] rupees.@pressa() I can't sell you this unless you have an ((Empty Bottle))!";
			char32 nomoneystr[] = "This ((@string(@shopstr))) costs [[@number(@sprice)]] rupees. Come back with more money!";
			itemsprite thisVisual = CreateItemAt(itemID, this->X, this->Y);
			char32 priceStr[16];
			itoa(priceStr, price);
			while(true)
			{
				until(AgainstPosition(this->X, this->Y-visualYOffset) && Hero->PressA)
				{
					switch(shopSpecial)
					{
						case 1:
						{
							if(Hero->Item[itemID])
							{
								//Set the "out of stock" combo, and remove the dummy item.
								this->Data = COMBO_SHOP_OUT_OF_STOCK;
								thisVisual->ScriptTile = TILE_SHOP_INVIS;
								while(Hero->Item[itemID])
									Waitframe();
								this->Data = COMBO_SHOP_INVIS;
							}
							break;
						}
						case 2:
						{
							if(UniqueShopData[shopIndex]) //Permanently out of stock!
							{
								thisVisual->ScriptTile = TILE_SHOP_INVIS;
								this->Data = COMBO_SHOP_OUT_OF_STOCK;
								Quit();
							}
							break;
						}
					}
					thisVisual->ScriptTile = -1;
					unless(hidePrice) drawPriceString(this->X+8, this->Y+16+priceYOffset-visualYOffset, priceStr);
					Waitframe();
				}
				Hero->InputA = false;
				Hero->PressA = false;
				//Set shop vars
				tangoTemp=false; //Set the default answer, if the menu is canceled out of, to "no"
				remchr(shopString,0);
				idata->GetName(shopString); //Load the item name into '@shopstr'
				shopPrice=price; //Load the item price into '@sprice'
				//
				bool hasEmptyBottle = CanFillBottle();
				if(idata->Family == IC_BOTTLE_FILL) reqBottle = true;
				if((fullCounter(CR_RUPEES))>=price&&(!reqBottle||hasEmptyBottle))
				{
					ShowStringAndWait(shopbuystr); //Sets 'tangoTemp = true' if player says yes to buy item
					if(tangoTemp)
					{
						ShowStringAndWait(boughtstr);
						itemsprite itm = CreateItemAt(itemID, Hero->X, Hero->Y);
						itm->Pickup = IP_HOLDUP;
						itm->ForceGrab = true;
						Game->DCounter[CR_RUPEES] -= price;
						switch(shopSpecial)
						{
							case 1:
							{
								thisVisual->ScriptTile = TILE_SHOP_INVIS;
								this->Data = COMBO_SHOP_OUT_OF_STOCK;
								WaitNoAction(10);
								break;
							}
							case 2:
							{
								thisVisual->ScriptTile = TILE_SHOP_INVIS;
								this->Data = COMBO_SHOP_OUT_OF_STOCK;
								UniqueShopData[shopIndex] = true;
								WaitNoAction(10);
								Quit();
								break;
							}
							default:
							{
								for(int q = 0; q < 10; ++q)
								{
									unless(hidePrice) drawPriceString(this->X+8, this->Y+16+priceYOffset-visualYOffset, priceStr);
									WaitNoAction();
								}
							}
						}
					}
					else ShowStringAndWait(notboughtstr);
				}
				else if(reqBottle&&!hasEmptyBottle)
				{
					ShowStringAndWait(nobottlestr);
				}
				else
				{
					ShowStringAndWait(nomoneystr);
				}
			}
		}
		void drawPriceString(int x, int y, int priceStr)
		{
			Screen->DrawString(LAYER_PRICETEXT, x, y, FONT_PRICEDISPLAY, COLOR_PRICETEXT, -1, TF_CENTERED, priceStr, OP_OPAQUE);
		}
		bool AgainstPosition(int x, int y)
		{
			return AgainstPosition(x, y, true);
		}
		bool AgainstPosition(int x, int y, bool anySide)
		{
			if(Hero->BigHitbox && !anySide)
			{
				return Hero->Z == 0 && (Hero->Dir == DIR_UP && Hero->Y == y+16 && Abs(Hero->X-x) < 8);
			}
			else if (!Hero->BigHitbox&&!anySide)
			{
				return Hero->Z == 0 && (Hero->Dir == DIR_UP && Hero->Y == y+8 && Abs(Hero->X-x) < 8);
			}
			else if (Hero->BigHitbox && anySide)
			{
				return Hero->Z == 0 && ((Hero->Dir == DIR_UP && Hero->Y == y+16 && Abs(Hero->X-x) < 8)||(Hero->Dir == DIR_DOWN && Hero->Y == y-16 && Abs(Hero->X-x) < 8)||(Hero->Dir == DIR_LEFT && Hero->X == x+16 && Abs(Hero->Y-y) < 8)||(Hero->Dir == DIR_RIGHT && Hero->X == x-16 && Abs(Hero->Y-y) < 8));
			}
			else if (!Hero->BigHitbox && anySide)
			{
				return Hero->Z == 0 && ((Hero->Dir == DIR_UP && Hero->Y == y+8 && Abs(Hero->X-x) < 8)||(Hero->Dir == DIR_DOWN && Hero->Y == y-16 && Abs(Hero->X-x) < 8)||(Hero->Dir == DIR_LEFT && Hero->X == x+16 && Abs(Hero->Y-y) < 8)||(Hero->Dir == DIR_RIGHT && Hero->X == x-16 && Abs(Hero->Y-y) < 8));
			}
			return false;
		}
		int fullCounter(int counter) //Use this to make sure draining rupees are not counted when determining if you have enough money.
		{
			return Game->Counter[counter]+Game->DCounter[counter];
		}
	}
	
	bool CanFillBottle()
	{
		for(int id = 0; id < NUM_ITEMDATA; ++id)
		{
			itemdata data = Game->LoadItemData(id);
			if(data->Family == IC_BOTTLE)
			{
				unless(Game->BottleState[data->Attributes[0]])
					return true;
			}
		}
		return false;
	}
}
