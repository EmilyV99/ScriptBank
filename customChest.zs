#option HEADER_GUARD on
#include "std.zh"

@Author("EmilyV")
combodata script customChestClosed
{
	/** Setup Instructions:
	 * Create a 'closed' chest combo (type 'None').
	 * On the 'Triggers' Tab:
	 *     -Check '->Next'
	 *     -Check at least one of the 'Btn: [dir]' checkboxes -
	 *            these set the sides you can open it from.
	 *     -Set 'Buttons:' based on what buttons you want to open it
	 *            (follow the instructions in the '?' button next to it)
	 * On the 'Scripts' Tab:
	 *     -Set this script (customChestClosed)
	 *     -InitD[0] = A unique number from '0' to '255'. Multiple chests on the same screen
	 *                     must have different numbers, or they will clash.
	 *                 This COULD be useful, for instance, for a 'pick one of the chests' room, as
	 *                     opening one would open all, but only give the item for the one you opened.
	 * Make the 'Next' combo after this be an 'open' chest combo (type 'None'), and follow the instructions
	 *     for 'customChestOpen' below.
	 */
	void run(int reg)
	{
		until(getD(reg)) Waitframe();
		mapdata tmp = Game->LoadTempScreen(this->Layer);
		tmp->ComboD[this->Pos] += 1;
	}
}
@Author("EmilyV")
combodata script customChestOpen
{
	/** Setup Instructions:
	 * On an 'open' chest combo (type 'None'), which is the 'Next' combo
	 *     to a 'closed' chest combo set up as instructed above in 'customChestClosed'
	 * On the 'Scripts' Tab:
	 *     -InitD[0] = The number you used for 'InitD[0]' on the closed chest combo before this combo
	 *     -InitD[1] = Item ID in the chest.
	 *                     Set to '-1' to use the screen item.
	 *                     Set to '-2' to use the screen catchall value.
	 */
	void run(int reg, int itmID)
	{
		if(getD(reg)) return;
		setD(reg, true);
		
		switch(itmID)
		{
			case -1:
				itmID = Screen->Item;
				break;
			case -2:
				itmID = Screen->Catchall;
				break;
		}
		switch(itmID)
		{
			case MIN_ITEMDATA...MAX_ITEMDATA:
				break;
			default:
				return;
		}
		
		itemsprite itm = CreateItemAt(itmID, Hero->X, Hero->Y);
		itm->Pickup |= IP_HOLDUP;
		
		//shouldn't be able to open it in air anyway, but to be safe...
		if(Hero->Z) Hero->Z = 0;
	}
}

bool getD(int reg)
{
	if(reg < 0 || reg > 255) return false;
	if(Screen->D[Div(reg,32)] & (1Lb << (reg%32)))
		return true;
	return false;
}

void setD(int reg, bool state)
{
	if(reg < 0 || reg > 255) return;
	if(state)
		Screen->D[Div(reg,32)] |= (1Lb << (reg%32));
	else Screen->D[Div(reg,32)] ~= (1Lb << (reg%32));
}

