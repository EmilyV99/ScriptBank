CONFIGB LIFE_ON_TOP = true;

/** INSTRUCTIONS
 * Assign DynamicMeters script to a slot (or Smart Assign)
 * Under 'Init Data->GenScript->DynamicMeters', check 'Run from start'
 * In the subscreen editor for your passive subscreen, edit the following:
 *    - The 'Life Gauge', which should be a single piece: set its 'Label' to "LifeHearts"
 *    - The 'Magic Gauge', which should be a single piece: set its 'Label' to "MagicBlocks"
 *    - (Optional) The 'Text' labelling the life gauge: set its 'Label' to "LifeName"
 *    - (Optional) The 'Text' labelling the magic gauge: set its 'Label' to "MagicName"
 *    - (Optional) The 'Magic Gauge' showing the half-magic tile: set its 'Label' to "MagicHalf"
 * Set 'LIFE_ON_TOP' above based on if you want life above magic or vice-versa
 */
@Author("EmilyV")
generic script DynamicMeters
{
    CONFIGB DEBUG = false; //Set true for extra error messages
    enum MeterWidget
    {
        MW_LIFENAME, MW_LIFEGAUGE,
        MW_MAGICNAME, MW_MAGICGAUGE, MW_MAGICHALF,
        MW_MAX
    };
    void run()
    {
        auto sub = Game->LoadPSubData(-1);
        auto pg = sub->Pages[0];
        subscreenwidget widgets[MW_MAX];
        for(int q = 0; q < MW_MAX; ++q)
            widgets[q] = get_widg(pg, <MeterWidget>q);
        unless(widgets[MW_LIFEGAUGE] && widgets[MW_MAGICGAUGE])
        {
            if(DEBUG)
                printf("Subscreen requires a life and magic gauge for script to function!");
            return;
        }
        int ohp, omp;
        this->ReloadState[GENSCR_ST_CHANGE_DMAP] = true;
        while(true)
        {
            if(ohp != Hero->MaxHP || omp != Hero->MaxMP)
            {
                ohp = Hero->MaxHP;
                omp = Hero->MaxMP;
                update_meters(widgets);
            }
            Waitframe();
        }
    }
    subscreenwidget get_widg(subscreenpage pg, MeterWidget w)
    {
        switch(w)
        {
            case MW_LIFENAME:
                return pg->GetWidget("LifeName");
            case MW_LIFEGAUGE:
                return pg->GetWidget("LifeHearts");
            case MW_MAGICNAME:
                return pg->GetWidget("MagicName");
            case MW_MAGICGAUGE:
                return pg->GetWidget("MagicBlocks");
            case MW_MAGICHALF:
                return pg->GetWidget("MagicHalf");
        }
        return NULL;
    }

    void update_meters(subscreenwidget widgets)
    {
        int life_container = Ceiling(Hero->MaxHP / Game->Generic[GEN_HP_PER_HEART]);
        int magic_container = Ceiling(Hero->MaxMP / Game->Generic[GEN_MP_PER_BLOCK]);
        int life_rows = Ceiling(life_container / widgets[MW_LIFEGAUGE]->GaugeWid);
        widgets[MW_LIFEGAUGE]->GaugeHei = life_rows;
        int mag_rows = Ceiling(magic_container / widgets[MW_MAGICGAUGE]->GaugeWid);
        widgets[MW_MAGICGAUGE]->GaugeHei = mag_rows;
        int hy;
        if(widgets[MW_MAGICHALF])
            hy = widgets[MW_MAGICHALF]->Y - widgets[MW_MAGICNAME]->Y;
        if(LIFE_ON_TOP)
        {
            int y = 0;
            if(auto w = widgets[MW_LIFENAME])
            {
                w->Y = y;
                y += w->DispH;
            }
            widgets[MW_LIFEGAUGE]->Y = y; y += widgets[MW_LIFEGAUGE]->DispH;
            
            if(auto w = widgets[MW_MAGICNAME])
            {
                w->Y = y;
                y += w->DispH;
            }
            widgets[MW_MAGICGAUGE]->Y = y; y += widgets[MW_MAGICGAUGE]->DispH;
        }
        else
        {
            int y = 0;
            if(auto w = widgets[MW_MAGICNAME])
            {
                w->Y = y;
                y += w->DispH;
            }
            widgets[MW_MAGICGAUGE]->Y = y; y += widgets[MW_MAGICGAUGE]->DispH;

            if(auto w = widgets[MW_LIFENAME])
            {
                w->Y = y;
                y += w->DispH;
            }
            widgets[MW_LIFEGAUGE]->Y = y; y += widgets[MW_LIFEGAUGE]->DispH;
        }
        if(widgets[MW_MAGICHALF])
            widgets[MW_MAGICHALF]->Y = hy + widgets[MW_MAGICNAME]->Y;
    }
}

