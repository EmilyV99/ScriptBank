#include "std.zh"
#include "EmilyMisc.zh"

@Author("EmilyV"),
@InitD0("ID"), @InitDHelp0("The ID of the submenu to use (from the SUBMENU_ constants)"),
@InitD1("X"), @InitDHelp1("The leftmost X of the menu"),
@InitD2("Y"), @InitDHelp2("The topmost Y of the menu"),
@InitD3("W"), @InitDHelp3("The width of the menu, in items"),
@InitD4("H"), @InitDHelp4("The height of the menu, in items"),
@InitD5("Spacing"), @InitDHelp5("The spacing between each row/column, in pixels")
generic script ItemSubmenu
{
    CONFIG IT_CLASS_SATCHEL = 0;
    CONFIG IT_SATCHEL_EMBER = 0;
    CONFIG IT_SATCHEL_SCENT = 0;
    CONFIG IT_SATCHEL_PEGASUS = 0;
    CONFIG IT_SATCHEL_GALE = 0;
    CONFIG IT_SATCHEL_MYSTERY = 0;

    CONFIG IT_CLASS_SHOOTER = 0;
    CONFIG IT_SHOOTER_EMBER = 0;
    CONFIG IT_SHOOTER_SCENT = 0;
    CONFIG IT_SHOOTER_PEGASUS = 0;
    CONFIG IT_SHOOTER_GALE = 0;
    CONFIG IT_SHOOTER_MYSTERY = 0;

    // A 2x2 frame upper-left corner
    CONFIG SUBMENU_FRAME_TILE = 0;
    CONFIG SUBMENU_FRAME_CSET = 0;
    enum
    {
        SUBMENU_SATCHEL,
        SUBMENU_SHOOTER,
        MAX_SUBMENU
    };
    int submenu_info(int items, int id)
    {
        switch(id)
        {
            case SUBMENU_SATCHEL:
                ResizeArray(items,5);
                ArrayCopy(items,{IT_SATCHEL_EMBER,IT_SATCHEL_SCENT,IT_SATCHEL_PEGASUS,IT_SATCHEL_GALE,IT_SATCHEL_MYSTERY});
                return IT_CLASS_SATCHEL;
            case SUBMENU_SHOOTER:
                ResizeArray(items,5);
                ArrayCopy(items,{IT_SHOOTER_EMBER,IT_SHOOTER_SCENT,IT_SHOOTER_PEGASUS,IT_SHOOTER_GALE,IT_SHOOTER_MYSTERY});
                return IT_CLASS_SHOOTER;
        }
        return -1;
    }
    void run(int id, int x, int y, int w, int h, int spacing, int btns)
    {
        int items[0];
        int indx = confindx();
        int btn = confbtn();
        if(indx < 0) return;
        int btnitem = {Hero->ItemA, Hero->ItemB, Hero->ItemX, Hero->ItemY}[indx];
        int iclass = submenu_info(items,id);
        for(it : items)
        {
            if(it == btnitem)
                break;
        }
        else //assign the item normally
        {
            if(Game->OverrideItems[iclass] == -2)
                assign(btn, Game->CurrentItemID(iclass));
            else assign(btn, Game->OverrideItems[iclass]);
            return;
        }
        int cursorpos = 0;
        int frame_w = w*2 + Ceiling(spacing/8), frame_h = h*2 + Ceiling(spacing/8);
        int lx = x+(spacing%8)/2, ly = y+(spacing%8)/2;
        int ld = 16+spacing;
        until(confirm(btn,cursorpos,items) || cancel())
        {
            Screen->DrawFrame(0,x,y,SUBMENU_FRAME_TILE,SUBMENU_FRAME_CSET,frame_w,frame_h);
            int ind = 0;
            int ty = ly;
            for(int yi = 0; yi < h; ++yi)
            {
                int tx = lx;
                for(int xi = 0; xi < w; ++xi)
                {
                    if(cursorpos == ind)
                        fast_item(I_SELECTB, tx, ty);
                    if(ind < SizeOfArray(items) && Hero->Item[items[ind]])
                        fast_item(items[ind], tx, ty);
                    if(cursorpos == ind)
                        fast_item(I_SELECTA, tx, ty);
                    ++ind;
                    tx += ld;
                }
                ty += ld;
            }
            Waitframe();
        }
        if(cancel())
            return;
        assign(btn, items[cursorpos]);
    }
    int confbtn()
    {
        if(Hero->PressB)
            return CB_B;
        if(Game->FFRules[qr_SELECTAWPN] && Hero->PressA)
            return CB_A;
        if(Game->FFRules[qr_SET_XBUTTON_ITEMS] && Hero->PressEx1)
            return CB_X;
        if(Game->FFRules[qr_SET_YBUTTON_ITEMS] && Hero->PressEx2)
            return CB_Y;
        return -1;
    }
    int confindx()
    {
        if(Hero->PressB)
            return 1;
        if(Game->FFRules[qr_SELECTAWPN] && Hero->PressA)
            return 0;
        if(Game->FFRules[qr_SET_XBUTTON_ITEMS] && Hero->PressEx1)
            return 2;
        if(Game->FFRules[qr_SET_YBUTTON_ITEMS] && Hero->PressEx2)
            return 3;
        return -1;
    }
    void assign(int btn, int itm)
    {
        switch(btn)
        {
            case CB_A:
                Hero->ItemA = itm;
                break;
            case CB_B:
                Hero->ItemB = itm;
                break;
            case CB_EX1:
                Hero->ItemX = itm;
                break;
            case CB_EX2:
                Hero->ItemY = itm;
                break;
        }
    }
    bool cancel()
    {
        return Hero->PressStart;
    }
    bool confirm(int btn, int cursorpos, int items)
    {
        return (Input->Press[btn] && cursorpos < SizeOfArray(items) && Hero->Item[items[cursorpos]]);
    }
    void fast_item(int id, int x, int y)
    {
        Screen->FastTile(0,x,y,Emily::item_tile(id),Emily::item_cset(id));
    }
}
