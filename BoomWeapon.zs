#include "std.zh"

/** INSTRUCTIONS:
 * Assign 'LWBoomWeapon' to a slot, and to each item you want to create booming lweapons.
 * Assign 'EWBoomWeapon' to a slot, and to each enemy you want to shoot booming eweapons.
 * Assign 'BoomWeaponCollisionHandler' to a slot.
 *     In 'Init Data->GenScript', select 'BoomWeaponCollisionHandler' and click 'Edit'
 *     In this menu, under 'Main', check 'Run from Start'.
 *     In this menu, under 'Events', check 'Enemy Hit 2'
 *     In this menu, under 'Events', check 'Hero Hit 2'
 * If any other scripts you are using use 'lweapon->Misc[]/'eweapon->Misc[]', you may
 *     need to change 'BOOMWEAPON_MISC_IND'.
 ** OPTIONS
 * Set the damage for the explosion as the damage of the weapon with the 'BoomWeapon' script.
 *     (Either the power of the item, or the Weapon Damage of the enemy)
 */
CONFIG BOOMWEAPON_MISC_IND = 0; //Change if another script uses index 0

@Author("EmilyV")
lweapon script LWBoomWeapon
{
    void run()
    {
        this->Misc[BOOMWEAPON_MISC_IND] = 1;
    }
}
@Author("EmilyV")
eweapon script EWBoomWeapon
{
    void run()
    {
        this->Misc[BOOMWEAPON_MISC_IND] = 1;
    }
}

@Author("EmilyV")
generic script BoomWeaponCollisionHandler
{
    void run()
    {
        this->EventListen[GENSCR_EVENT_ENEMY_HIT2] = true;
        while(true)
        {
            switch(WaitEvent())
            {
                case GENSCR_EVENT_ENEMY_HIT2:
                {
                    lweapon w = Game->EventData[GENEV_EHIT_LWPNPTR];
                    if(w->Misc[BOOMWEAPON_MISC_IND]==1)
                    {
                        //BOOMWEAPON
                        boom(w);
                        w->Remove();
                        Game->EventData[GENEV_EHIT_NULLIFY] = true;
                    }
                    break;
                }
                case GENSCR_EVENT_HERO_HIT_2:
                {
                    switch(Game->EventData[GENEV_HEROHIT_HITTYPE])
                    {
                        case OBJTYPE_EWPN:
                        {
                            eweapon w = Game->EventData[GENEV_HEROHIT_HITOBJ];
                            if(w->Misc[BOOMWEAPON_MISC_IND]==1)
                            {
                                //BOOMWEAPON
                                boom(w);
                                w->Remove();
                                Game->EventData[GENEV_HEROHIT_NULLIFY] = true;
                            }
                            break;
                        }
                        case OBJTYPE_LWPN:
                        {
                            lweapon w = Game->EventData[GENEV_HEROHIT_HITOBJ];
                            if(w->Misc[BOOMWEAPON_MISC_IND]==1)
                            {
                                //BOOMWEAPON
                                boom(w);
                                w->Remove();
                                Game->EventData[GENEV_HEROHIT_NULLIFY] = true;
                            }
                            break;
                        }
                    }
                    break;
                }
            }
        }
    }
    lweapon boom(lweapon lw)
    {
        lweapon boom = CreateLWeaponAt(LW_BOMBBLAST,lw->X,lw->Y);
        boom->Dir = lw->Dir;
        boom->Damage = lw->Damage;
        return boom;
    }
    eweapon boom(eweapon ew)
    {
        eweapon boom = CreateEWeaponAt(EW_BOMBBLAST,ew->X,ew->Y);
        boom->Dir = ew->Dir;
        boom->Damage = ew->Damage;
        return boom;
    }
}