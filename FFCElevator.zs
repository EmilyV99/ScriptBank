#include "std.zh"

CONFIG PROMPT_CMB = -1;
CONFIG PROMPT_CSET = 0;
CONFIG PROMPT_XOFF = 12;
CONFIG PROMPT_YOFF = -8;

CONFIG BTN_CMB = -1;
CONST_ASSERT(PROMPT_CMB > -1 && PROMPT_CMB <= MAX_COMBOS, "PROMPT_CMB must be a valid combo ID!");
CONST_ASSERT(BTN_CMB > -1 && BTN_CMB <= MAX_COMBOS, "BTN_CMB must be a valid combo ID!");

CONFIG PROMPT_BTN = CB_A;
const ffc INVALID_FFC = <ffc>(-1);

@InitD0("Height"), @InitDHelp0("Height, in pixels, of the elevator"),
@InitD1("Speed"), @InitDHelp1("Speed, in pixels, while moving"),
@InitD2("ID"), @InitDHelp2("A unique ID number for this elevator"),
@InitD7("dummy"), @InitDHelp7("The script uses this index for special purposes. Leave this blank.")
ffc script Elevator
{
    void run(int distance, int speed, int uID)
    {
        this->Flags[FFCF_SOLID] = true;
        distance = Abs(distance);
        speed = Abs(speed);
        int btnX = this->X+(this->EffectWidth/2)-8;
        int topY = this->Y, botY = this->Y+distance;
        int stop = 0;
        this->InitD[7] = -1;
        while(true)
        {
            bool force = this->InitD[7] > -1 && this->InitD[7] != stop;
            this->InitD[7] = -1;
            bool go = force;
            bool btn = false;
            if(!go && (btn = btnCheck(this, btnX)))
            {
                if(Input->Press[PROMPT_BTN])
                {
                    Input->Press[PROMPT_BTN] = false;
                    go = true;
                }
            }
            if(go)
            {
                this->Vy = stop ? -speed : speed;
                while(this->Vy)
                {
                    if(this->InitD[7] > -1 && this->InitD[7] == stop)
                    {
                        stop = 1-stop;
                        this->Vy = stop ? -speed : speed;
                    }
                    this->InitD[7] = -1;
                    unless(stop)
                    {
                        if(this->Y >= botY)
                        {
                            if(int diff = this->Y-botY)
                            {
                                this->Y -= diff;
                                if(onElevator(this)) Hero->Y -= diff;
                            }
                            stop = 1;
                            this->Vy = 0;
                        }
                    }
                    else
                    {
                        if(this->Y <= topY)
                        {
                            if(int diff = this->Y-topY)
                            {
                                this->Y -= diff;
                                if(onElevator(this)) Hero->Y -= diff;
                            }
                            stop = 0;
                            this->Vy = 0;
                        }
                    }
                    Waitdraw();
                    //should use SPLAYER_FFC_DRAW, once that's added
                    Screen->FastCombo(1, btnX, this->Y-16,BTN_CMB,this->CSet);
                    Waitframe();
                }
                btn = btnCheck(this, btnX);
            }
            Waitdraw();
            if(btn)
                Screen->FastCombo(SPLAYER_PLAYER_DRAW, Hero->X+PROMPT_XOFF, Hero->Y+PROMPT_YOFF, PROMPT_CMB, PROMPT_CSET);
            //should use SPLAYER_FFC_DRAW, once that's added
            Screen->FastCombo(1, btnX, this->Y-16,BTN_CMB,this->CSet);
            Waitframe();
        }
    }
    bool btnCheck(ffc this, int btnX)
    {
        return Hero->Y == this->Y-16 && Abs(Hero->X-btnX) <= 8;
    }
    bool onElevator(ffc this)
    {
        return Hero->Y == this->Y-16 && Hero->X > this->X-12 && Hero->X <= this->X+this->EffectWidth-4; 
    }
}

@InitD0("ID"), @InitDHelp0("A unique ID number for the elevator to call"),
@InitD1("Bottom"), @InitDHelp1("If the elevator should be called to the bottom"), @InitDType1("B")
ffc script ElevatorCall
{
    void run(int uID, int stop)
    {
        if(stop) stop = 1;
        int scrid = CheckFFCScript("Elevator");
        while(true)
        {
            if(Distance(Hero->X,Hero->Y,this->X,this->Y) <= 8)
            {
                if(Input->Press[PROMPT_BTN])
                {
                    Input->Press[PROMPT_BTN] = false;
                    ffc f = findElevator(scrid,uID);
                    if(f != INVALID_FFC)
                    {
                        f->InitD[7] = stop;
                    }
                }
                Waitdraw();
                Screen->FastCombo(SPLAYER_PLAYER_DRAW, Hero->X+PROMPT_XOFF, Hero->Y+PROMPT_YOFF, PROMPT_CMB, PROMPT_CSET);
            }
            Waitframe();
        }
    }
    ffc findElevator(int scrid, int uID)
    {
        int q;
        for(f : Screen->FFCs)
        {
            if(f->Script == scrid && f->InitD[2] == uID)
                return f;
        }
        return INVALID_FFC;
    }
}
