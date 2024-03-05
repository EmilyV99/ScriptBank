#include "std.zh"

CONFIG TORCH_SPIN_CHARGE_FRAMES = 64; //Frames to full charge
CONFIG SFX_TORCH_CHARGE = SFX_CHARGE1; //SFX when charged
CONFIG DELAY_TIME = 5; //Frames between each fire
CONFIG FLASH_RATE = 5; //Rate the wand flashes csets when charged

CONST_ASSERT(DELAY_TIME > 0, "Must have a delay between fires! (DELAY_TIME must be increased)");

@Author("EmilyV"),
@InitD0("Damage"), @InitDHelp0("The damage of the fires"),
@InitD1("Step Speed"), @InitDHelp1("The speed in 1/100 px/frame of the fires"),
@InitD2("Fire Sprite"), @InitDHelp2("The sprite to use for the fires"),
@InitD3("Wand Sprite"), @InitDHelp3("If this is not 0, a wand sprite will be displayed.\nThis sprite should be right-facing only."),
@InitD4("Wand Flash CSet"), @InitDHelp4("The wand will flash between its' normal cset and this cset when charged")
itemdata script MagicTorch
{
    enum //Some data we'll need
    {
        DATA_DMG, //the fire's damage
        DATA_STEP, //the fire's speed
        DATA_SPR, //the fire's sprite
        DATA_WAND, //the dummy wand weapon
        DATA_DIR, //the player's dir
        DATA_CAN_CHARGE, //if we can still charge up
        DATA_ID, //the item ID
        DATA_MAX
    };
    //The main function of the script
    void run(int damage, int step, int sprite, int wandsprite, int flash_cset)
    {
        if (step <= 0) step = 90;

        //A lot of functions need this info, so, we just store it all in an array for convenience.
        untyped arr[DATA_MAX] = {damage,step,sprite,NULL,Hero->Dir,true,this->ID};

        int fwd_angle = DirAngle(Hero->Dir); //The angle the player is facing
        int charge_angles[11]; //The angles to fire for charged shots
        int normal_angles[3]; //The angles to fire for normal shots
        int deg = fwd_angle+90; //Start to the player's right (+90deg)
        for(int ind = 0; ind < 11; ++ind)
        {
            charge_angles[ind] = WrapDegrees(deg);
            if(ind < 3) normal_angles[ind] = WrapDegrees(deg);
            deg -= 45; //Both slash and charge just go in 45deg CCW increments
        }
        
        lweapon wand;
        int o_cset;
        if(wandsprite) //Spawn a dummy weapon to display the wand
        {
            wand = Screen->CreateLWeapon(LW_SCRIPT1);
            wand->UseSprite(wandsprite);
            o_cset = wand->CSet;
            wand->AutoRotate = true; //Since it uses autorotate, it only needs a right-facing sprite
            wand->Angular = true;
            wand->CollDetection = false; //Dummy, doesn't collide with stuff
            wand->DrawXOffset = wand->DrawYOffset = wand->DrawZOffset = 0;
            arr[DATA_WAND] = wand; //store this in the array so other functions can access it
            position_wand(wand,normal_angles[0]); //Set the starting position
        }

        launch_fires(arr,normal_angles); //Slash the weapon normally

        int frames;
        bool charged;
        while(arr[DATA_CAN_CHARGE]) //If the button hasn't been let go at all, start charging up
        {
            position_wand(arr[DATA_WAND],fwd_angle);
            if(++frames >= TORCH_SPIN_CHARGE_FRAMES && !charged)
            {
                //Once charged enough, play the charged sound
                charged = true;
                if(SFX_TORCH_CHARGE > 0)
                    Audio->PlaySound(SFX_TORCH_CHARGE);
            }
            if(FLASH_RATE > 0 && wand && wand->isValid() && charged && flash_cset > -1) //Flash the wand CSet while charged
                wand->CSet = Div(frames,FLASH_RATE)%2 ? o_cset : flash_cset;
            Custom_Waitframe(arr);
        }
        
        if(charged)
        {
            if(wand && wand->isValid()) //Revert the cset in case it was flashing
                wand->CSet = o_cset;
            launch_fires(arr,charge_angles); //Slash the weapon with a spin attack
        }

        if(wand && wand->isValid()) //Delete the dummy wand weapon
            wand->Remove();
    }
    //Launch a single fire
    void launch_fire(int damage, int step, int sprite, int degrees)
    {
        lweapon fire = CreateLWeaponAt(LW_FIRE, Hero->X, Hero->Y);
        if (sprite > 0) fire->UseSprite(sprite);
        fire->Damage = damage;
        Game->PlaySound(SFX_FIRE);
        fire->MoveFlags[WPNMV_CAN_PITFALL] = false;
        fire->LightRadius = 32;
        fire->Step = step;
        fire->Angular = true;
        fire->DegAngle = degrees;
        move_out_of_player(fire);
    }
    //Launch multiple fires, waiting after each
    void launch_fires(untyped arr, int deg_array)
    {
        for(angle : deg_array)
        {
            launch_fire(arr[DATA_DMG],arr[DATA_STEP],arr[DATA_SPR],angle);
            Hero->Action = LA_ATTACKING;
            Hero->Stun = DELAY_TIME;
            position_wand(arr[DATA_WAND],angle);
            Custom_Waitframe(arr,DELAY_TIME);
        }
    }
    //Position the wand sprite at a specific angle
    void position_wand(lweapon wand, int angle)
    {
        if(wand && wand->isValid())
        {
            wand->DegAngle = angle;
            wand->X = Hero->X+VectorX(16,angle);
            wand->Y = Hero->Y+VectorY(16,angle);
        }
    }
    //Check if the specified item ID is pressed
    bool is_pressed(int itemid)
    {
        int cb[] = {CB_A,CB_B,CB_EX1,CB_EX2};
        int itm[] = {Hero->ItemA,Hero->ItemB,Hero->ItemX,Hero->ItemY};
        for(int q = 0; q < 4; ++q)
            if(Input->Button[cb[q]] && itm[q] == itemid)
                return true;
        return false;
    }
    //Move the specified lweapon until it is out of the player's hitbox
    void move_out_of_player(lweapon lw)
    {
        if(lw->Angular)
        {
            while(Collision(lw))
            {
                lw->X += VectorX(1,lw->DegAngle);
                lw->Y += VectorY(1,lw->DegAngle);
            }
            //plus a bit extra
            lw->X += VectorX(2,lw->DegAngle);
            lw->Y += VectorY(2,lw->DegAngle);
        }
        else
        {
            while(Collision(lw))
            {
                lw->X += Emily::dirX(lw->Dir);
                lw->Y += Emily::dirY(lw->Dir);
            }
            //plus a bit extra
            lw->X += 2*Emily::dirX(lw->Dir);
            lw->Y += 2*Emily::dirX(lw->Dir);
        }
    }
    //Wait for some frames, while checking custom stuff.
    void Custom_Waitframe(untyped arr, int frames = 1)
    {
        while(frames-- >= 0)
        {
            Hero->Dir = arr[DATA_DIR]; //Ensure the player stays facing this direction
            unless(is_pressed(arr[DATA_ID])) //Check if the button was let go of, this means no charge attack
                arr[DATA_CAN_CHARGE] = false;
            Waitdraw();
            Hero->Dir = arr[DATA_DIR]; //Ensure the player stays facing this direction
            Waitframe();
        }
    }
}

