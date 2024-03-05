#include "std.zh"

CONFIG CR_ATK = CR_CUSTOM1;
CONFIG CR_DEF = CR_CUSTOM2;
CONFIG _CII_FLAGS = CIID_FLAG_CHECKCOST|CIID_FLAG_CHECKJINX|CIID_FLAG_CHECKBUNNY;
void updateAttackDefenseCtrs()
{
    int atk, def;
    int id = Game->CurrentItemID(IC_SWORD, _CII_FLAGS);
    if(id > -1)
    {
        itemdata id = Game->LoadItemData(id);
        atk = id->Damage*Game->Generic[GEN_HERO_DMG_MULT];
    }
    id = Game->CurrentItemID(IC_RING, _CII_FLAGS);
    if(id > -1)
    {
        itemdata id = Game->LoadItemData(id);
        if(id->Flags[1]) //percentage multiplier
        {
            if(id->Power > 0 && id->Power <= 100)
                def = 100-id->Power;
        }
        else //divisor
        {
            unless(id->Power)
                def = 100;
            else def = Round(100-(100/id->Power));
        }
    }
    Game->MCounter[CR_ATK] = Game->Counter[CR_ATK] = atk;
    Game->MCounter[CR_DEF] = 100;
    Game->Counter[CR_DEF] = Clamp(def,0,100);
}
