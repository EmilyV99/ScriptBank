#include "std.zh"

enum //Item Menu Styles
{
    MENUSTYLE_GRID, // 0
    MENUSTYLE_ROW, // 1
    MENUSTYLE_COLUMN, // 2
    MENUSTYLE_MAX
};

// Tile/cset for the main frame
CONFIG TILE_2X2FRAME = 237;
CONFIG CSET_2X2FRAME = 0;
// Spacing options
CONFIG ITEMMENU_HSPACE = 1;
CONFIG ITEMMENU_VSPACE = 4;

// Set to -1 to use no selector draw
CONFIG IT_SELECTOR_FRONT = I_SELECTA;
CONFIG IT_SELECTOR_BACK = I_SELECTB;

// The main script, assign this to the subscreen item slot
@Author("EmilyV"),
@InitD0("X"), @InitDHelp0("The X value of the upper-left corner of the first item"),
@InitD1("Y"), @InitDHelp1("The Y value of the upper-left corner of the first item"),
@InitD2("Style"), @InitDHelp2("One of the 'MENUSTYLE_' values from the top of 'SubscrItemMenu.zs'"),
@InitD3("Itemclass"), @InitDHelp3("The value of the item class to select for"),
@InitD4("Item1"), @InitDHelp4("The 1st item ID in the menu. Use '-1' for blank."),
@InitD5("Item2"), @InitDHelp5("The 2nd item ID in the menu. Use '-1' for blank."),
@InitD6("Item3"), @InitDHelp6("The 3rd item ID in the menu. Use '-1' for blank."),
@InitD7("Item4"), @InitDHelp7("The 4th item ID in the menu. Use '-1' for blank.")
generic script ItemMenu
{
    void run(int x, int y, int style, int itemclass, int itm1, int itm2, int itm3, int itm4)
    {
        genericdata helper;
        if(int scr = CheckGenericScript("ItemMenuHelper"))
            helper = Game->LoadGenericData(scr);
        else return;
        if(itemclass < 0 || itemclass >= IC_MAX)
            return; //Invalid itemclass
        // Store the item IDs in an array
        int itms[] = {itm1,itm2,itm3,itm4};
        // ...and validate them as valid IDs.
        for(int q = 0; q < 4; ++q)
        {
            if(itms[q] < 0 || itms[q] >= NUM_ITEMDATA || Game->LoadItemData(itms[q])->Family != itemclass)
                itms[q] = -1;
        }
        // sort the array so blanks are at the end
        for(int q = 0; q < 3; ++q)
        {
            if(itms[q] == -1)
            {
                for(int p = q+1; p < 4; ++p)
                {
                    if(itms[p] > -1)
                    {
                        itms[q] = itms[p];
                        itms[p] = -1;
                        break;
                    }
                }
                else break; //everything after already -1
            }
        }
        // count the number of owned items
        int numitems, numowned;
        int sel_ind = 0;
        int curid = Game->CurrentItemID(itemclass, 0);
        for(int q = 0; q < 4; ++q)
        {
            if(itms[q] < 0) continue;
            ++numitems;
            if(Game->DisableItem[itms[q]] || !Hero->Item[itms[q]])
                itms[q] = -1;
            else ++numowned;
            if(curid > -1 && itms[q] == curid)
                sel_ind = q;
        }
        if(numowned < 1) return; //No items to show, don't open menu!

        if(helper->DataSize <= itemclass)
            helper->DataSize = itemclass+1;
        helper->Data[itemclass] = true;
        helper->Running = true;

        if(numitems == 1) //only one valid item? no need for a menu...
        {
            Game->OverrideItems[itemclass] = itms[0];
            return;
        }
        int btns_ok[] = {CB_A,CB_B,CB_X,CB_Y};
        NoAction();
        while(true)
        {
            if(itms[sel_ind] > -1) //valid item
                for(b : btns_ok)
                    if(Input->Press[b]) //pressed button
                    {
                        Game->OverrideItems[itemclass] = itms[sel_ind];
                        return;
                    }
            bool moved = false;
            switch(style) //Draw the menu
            {
                default:
                case MENUSTYLE_GRID: //2x2 grid
                    if(numitems > 2)
                    {
                        if(Input->Press[CB_UP] || Input->Press[CB_DOWN])
                        {
                            sel_ind ^= 2;
                            moved = true;
                        }
                        else if(Input->Press[CB_LEFT] || Input->Press[CB_RIGHT])
                        {
                            sel_ind ^= 1;
                            moved = true;
                        }
                        DEFINE leftover_hpad = (8-(ITEMMENU_HSPACE%8))%8;
                        DEFINE leftover_vpad = (8-(ITEMMENU_VSPACE%8))%8;
                        DEFINE lpad = 8+Ceiling(leftover_hpad/2);
                        DEFINE rpad = 8+Floor(leftover_hpad/2);
                        DEFINE tpad = 8+Ceiling(leftover_vpad/2);
                        DEFINE bpad = 8+Floor(leftover_vpad/2);
                        DEFINE wid_pad = (ITEMMENU_HSPACE+leftover_hpad)/8;
                        DEFINE hei_pad = (ITEMMENU_VSPACE+leftover_vpad)/8;
                        Screen->DrawFrame(0, x-lpad, y-tpad, TILE_2X2FRAME, CSET_2X2FRAME, 6+wid_pad, 6+hei_pad);
                        for(int ind = 0; ind < numitems; ++ind)
                        {
                            int tx = x+((ind&1) ? 16+ITEMMENU_HSPACE : 0);
                            int ty = y+((ind>1) ? 16+ITEMMENU_VSPACE : 0);
                            if(sel_ind == ind)
                                draw_item(tx,ty,IT_SELECTOR_BACK);
                            draw_item(tx,ty,itms[ind]);
                            if(sel_ind == ind)
                                draw_item(tx,ty,IT_SELECTOR_FRONT);
                        }
                        break;
                    }
                    // else fallthrough
                case MENUSTYLE_ROW:
                {
                    if(Input->Press[CB_LEFT])
                    {
                        sel_ind = wrap(sel_ind-1,numitems);
                        moved = true;
                    }
                    else if(Input->Press[CB_RIGHT])
                    {
                        sel_ind = wrap(sel_ind+1,numitems);
                        moved = true;
                    }
                    DEFINE hspace = (numitems-1)*ITEMMENU_HSPACE;
                    DEFINE leftover_hpad = (8-(hspace%8))%8;
                    DEFINE lpad = 8+Ceiling(leftover_hpad/2);
                    DEFINE rpad = 8+Floor(leftover_hpad/2);
                    DEFINE wid_pad = (hspace+leftover_hpad)/8;
                    Screen->DrawFrame(0, x-lpad, y-8, TILE_2X2FRAME, CSET_2X2FRAME, 2+(2*numitems)+wid_pad, 4);
                    for(int ind = 0; ind < numitems; ++ind)
                    {
                        int tx = x+((16+ITEMMENU_HSPACE)*ind);
                        int ty = y;
                        if(sel_ind == ind)
                            draw_item(tx,ty,IT_SELECTOR_BACK);
                        draw_item(tx,ty,itms[ind]);
                        if(sel_ind == ind)
                            draw_item(tx,ty,IT_SELECTOR_FRONT);
                    }
                    break;
                }
                case MENUSTYLE_COLUMN:
                {
                    if(Input->Press[CB_UP])
                    {
                        sel_ind = wrap(sel_ind-1,numitems);
                        moved = true;
                    }
                    else if(Input->Press[CB_DOWN])
                    {
                        sel_ind = wrap(sel_ind+1,numitems);
                        moved = true;
                    }
                    DEFINE vspace = (numitems-1)*ITEMMENU_VSPACE;
                    DEFINE leftover_vpad = (8-(vspace%8))%8;
                    DEFINE tpad = 8+Ceiling(leftover_vpad/2);
                    DEFINE bpad = 8+Floor(leftover_vpad/2);
                    DEFINE hei_pad = (vspace+leftover_vpad)/8;
                    Screen->DrawFrame(0, x-8, y-tpad, TILE_2X2FRAME, CSET_2X2FRAME, 4, 2+(2*numitems)+hei_pad);
                    for(int ind = 0; ind < numitems; ++ind)
                    {
                        int tx = x;
                        int ty = y+((16+ITEMMENU_VSPACE)*ind);
                        if(sel_ind == ind)
                            draw_item(tx,ty,IT_SELECTOR_BACK);
                        draw_item(tx,ty,itms[ind]);
                        if(sel_ind == ind)
                            draw_item(tx,ty,IT_SELECTOR_FRONT);
                    }
                    break;
                }
            }
            if(moved)
                if(int sfx = Game->MiscSFX[MISCSFX_SUBSCR_CURSOR_MOVE])
                    Audio->PlaySound(sfx);
            Waitframe();
        }
    }
    void draw_item(int x, int y, int id)
    {
        if(id < 0 || id >= NUM_ITEMDATA)
            return;
        Screen->FastTile(0,x,y,Emily::item_tile(id),Emily::item_cset(id));
    }
}

// A helper script, just assign it to a slot.
@Author("EmilyV")
generic script ItemMenuHelper
{
    void run()
    {
        while(true)
        {
            for(int q = 0; q < this->DataSize; ++q)
            {
                unless(this->Data[q]) continue;
                int id = Game->OverrideItems[q];
                if(id > -2)
                    if(Game->DisableItem[id] || !Hero->Item[id])
                        Game->OverrideItems[q] = -2;
            }
            Waitframe();
        }
    }
}

// A helper init script, you don't need to touch this at all.
@Author("EmilyV"), @InitScript(-1)
global script ItemMenuInit
{
    void run()
    {
        if(int scr = CheckGenericScript("ItemMenuHelper"))
            RunGenericScript(scr)->DataSize = 0;
    }
}

