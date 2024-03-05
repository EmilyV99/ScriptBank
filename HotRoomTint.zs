#include "std.zh"

/** INSTRUCTIONS
 * If you want to use a screen flag other than 'Script 1', change the CONFIG constants below
 * Assign the script to a slot (or use Smart Assign)
 * In 'Init Data->GenScript', select this script:
 *     Check 'Run from start'
 *     Set the InitD[]
 * Check the flag set below on a screen to make it a hot room.
 */
@Author("EmilyV"),
@InitD0("Wavy Intensity"), @InitDHelp0("If >0, applies a wavy effect while on the screen"),
@InitD1("Tint Percentage"), @InitDHelp1("A value between 0 and 1 (0.50 == 50%)"),
@InitD2("Tint Color"), @InitDHelp2("A long-hex value, 6-digit hex color code"), @InitDType2("LH")
generic script HotRoomTint
{
    // Which screen flag to use for hot rooms. Default 'SF_MISC, SFM__SCRIPT1' is the 'Script 1' flag.
    CONFIG SF_HOTROOM_CAT = SF_MISC;
    CONFIG SF_HOTROOM_FLAG = SFM_SCRIPT1;
    void run(int wavy, int tint_perc, long tint_color)
    {
        int pal_ind = -1;
        int oscr = -1, odm;
        bool tinted = false;
        paldata cachepal = Graphics->CreatePalData();
        paldata tintpal = Graphics->CreatePalData(Graphics->CreateRGB(tint_color));
        paldata tintedpal = Graphics->CreatePalData();
        
        while(true)
        {
            if(oscr != Game->CurScreen || odm != Game->CurDMap)
            {
                bool was_tinted = tinted;
                oscr = Game->CurScreen; odm = Game->CurDMap;
                tinted = ScreenFlag(SF_HOTROOM_CAT,SF_HOTROOM_FLAG);
                if(tint_perc)
                {
                    int new_pal = Game->LoadDMapData(Game->CurDMap)->Palette;
                    if(pal_ind != new_pal)
                    {
                        pal_ind = new_pal;
                        cachepal->LoadLevelPalette(pal_ind);
                        tintedpal->Mix(cachepal, tintpal, tint_perc);
                    }
                    if(was_tinted != tinted)
                        (tinted ? tintedpal : cachepal)->WriteMainPalette();
                }
                if(wavy && was_tinted && !tinted)
                    Screen->Wavy = 0;
            }
            if(wavy && tinted)
                Screen->Wavy = wavy;
            Waitframe();
        }
    }
    DEFINE SF_FLAG_MAX = (SF_HOTROOM_CAT==SF_ROOMTYPE ? SFR_LAST
        : (SF_HOTROOM_CAT==SF_VIEW ? SFV_LAST
        : (SF_HOTROOM_CAT==SF_SECRETS ? SFS_LAST
        : (SF_HOTROOM_CAT==SF_WARP ? SFW_LAST
        : (SF_HOTROOM_CAT==SF_ITEMS ? SFI_LAST
        : (SF_HOTROOM_CAT==SF_COMBOS ? SFC_LAST
        : (SF_HOTROOM_CAT==SF_SAVE ? SFSV_LAST
        : (SF_HOTROOM_CAT==SF_FFC ? SFF_LAST
        : (SF_HOTROOM_CAT==SF_WHISTLE ? SFWH_LAST
        : (SF_HOTROOM_CAT==SF_MISC ? SFM_LAST
        : (-1)))))))))));
    CONST_ASSERT(SF_FLAG_MAX > -1,"SF_HOTROOM_CAT must be a valid 'SF_' constant!");
    CONST_ASSERT(SF_HOTROOM_FLAG >= 0 && SF_HOTROOM_FLAG < SF_FLAG_MAX,
        "SF_HOTROOM_FLAG must be a valid screen flag for its category!");
}

