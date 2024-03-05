#include "std.zh"

/** INSTRUCTIONS
 * Assign OOTHotRooms script to a slot (or Smart Assign)
 * Under 'Init Data->GenScript->OOTHotRooms', check 'Run from start'
 * Set 'CONFIG' type constants below
 */
@Author("EmilyV"),
@InitD0("Seconds Per Heart"), @InitDHelp0("Number of seconds in a hot room per heart of HP before death"),
@InitD1("Immune ItemID"), @InitDHelp1("Item that, when equipped, makes the player immune to hot rooms"),
@InitD2("Immune Must Equip"), @InitDHelp2("If checked, the 'Immune ItemID' must"
    " be the 'Current Item' of its' itemclass to have any effect."),
@InitD3("Heat Warn Message"), @InitDHelp3("A string editor message ID for a message to play each session"
    " when first entering a hot room unprotected.")
generic script OOTHotRooms
{
    // Which screen flag to use for hot rooms. Default 'SF_MISC, SFM__SCRIPT1' is the 'Script 1' flag.
    CONFIG SF_HOTROOM_CAT = SF_MISC;
    CONFIG SF_HOTROOM_FLAG = SFM_SCRIPT1;
    // Colors/font for the timer text
    CONFIG C_TEXT_FG = 0x01;
    CONFIG C_TEXT_BG = 0x0F;
    CONFIG FONT_TEXT = FONT_DEF;
    CONFIG TIMER_X = 0;
    CONFIG TIMER_Y = 0;
    CONFIG TIMER_ALIGN = TF_NORMAL;
    // Beep SFX
    CONFIG SFX_BEEP_NORMAL = 0; // Play this sfx...
    CONFIG BEEP_RATE_NORMAL = 5; // Every this many seconds...
    CONFIG BEEP_NORMAL_THRESHHOLD = 999; // While you have less than this many seconds left

    CONFIG SFX_BEEP_DANGER = 0; // Play this sfx...
    CONFIG BEEP_RATE_DANGER = 1; // Every this many seconds...
    CONFIG BEEP_DANGER_THRESHHOLD = 10; // While you have less than this many seconds left

    
	void run(int sec_per_heart, int immune_item_id, bool must_equip, int heat_warning)
	{
        itemdata id = (immune_item_id < 0 || immune_item_id >= NUM_ITEMDATA) ? NULL
            : Game->LoadItemData(immune_item_id);
        
        DEFINE FR_SEC = 60;
        DEFINE SEC_MIN = 60;
        DEFINE FR_MIN = FR_SEC*SEC_MIN;

        bool gave_heat_warning = false;
        
		while(true)
		{
			until(ScreenFlag(SF_HOTROOM_CAT,SF_HOTROOM_FLAG) && !is_immune(id,must_equip))
                Waitframe();
            unless(gave_heat_warning)
            {
                if(heat_warning)
                    Screen->Message(heat_warning);
                gave_heat_warning = true;
            }
            DEFINE TIMER = Ceiling((FR_SEC * sec_per_heart * Hero->HP) / Game->Generic[GEN_HP_PER_HEART]);
            int time_fr = TIMER;
            while(ScreenFlag(SF_HOTROOM_CAT,SF_HOTROOM_FLAG) && !is_immune(id,must_equip))
            {
                char32 buf[6];
                sprintf(buf, "%02d:%02d", Min(99,Div(time_fr,FR_MIN)), Div(time_fr,FR_SEC)%SEC_MIN);
                Screen->DrawString(7, TIMER_X, TIMER_Y, FONT_TEXT, C_TEXT_FG, C_TEXT_BG, TIMER_ALIGN, buf);
                unless(HotTimePaused())
                    --time_fr;
                if(Hero->HP <= 0)
                    break;
                unless(time_fr % FR_SEC)
                {
                    int s = Div(time_fr,FR_SEC);
                    if(SFX_BEEP_NORMAL && s <= BEEP_NORMAL_THRESHHOLD && !(s % BEEP_RATE_NORMAL))
                        Audio->PlaySound(SFX_BEEP_NORMAL);
                    if(SFX_BEEP_DANGER && s <= BEEP_DANGER_THRESHHOLD && !(s % BEEP_RATE_DANGER))
                        Audio->PlaySound(SFX_BEEP_DANGER);
                    unless(time_fr)
                    {
                        Hero->HP = 0;
                        break;
                    }
                }
                Waitframe();
            }
			Waitframe();
		}
	}
    bool is_immune(itemdata id, bool must_equip)
    {
        unless(id) return false;
        if(Hero->Item[id->ID])
        {
            unless(must_equip)
                return true;
            if(Game->CurrentItemID(id->Family, 0) == id->ID)
                return true;
        }
        return false;
    }
    bool HotTimePaused()
    {
        return Screen->ShowingMessage > 0;
    }
}

