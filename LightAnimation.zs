#include "std.zh"

//returns CLK
int incLightClk(int clk, int pulseTime, int waitTime)
{
    const int totalTime = (pulseTime+waitTime)*2;
    return (clk+1)%totalTime;
}
//returns RADIUS
int getLight(int clk, int minRad, int maxRad, int pulseTime, int waitTime)
{
    if(clk < pulseTime)
        ; //fallthrough to pulse code
    else if(clk < pulseTime+waitTime)
        return maxRad;
    else if(clk < pulseTime*2+waitTime)
    {
        clk = pulseTime-(clk-pulseTime-waitTime+1);
        //fallthrough to pulse code
    }
    else //clk < pulseTime*2+waitTime*2
        return minRad;
    //at this point, 'clk < pulseTime'
    return Lerp(minRad,maxRad,(clk+1)/(pulseTime+1));
}

int run_lightclk(combodata obj, int clk, int minRad, int maxRad, int pulseTime, int waitTime, int shape)
{
    obj->Attribytes[0] = getLight(clk, minRad, maxRad, pulseTime, waitTime);
    if(shape > -1) obj->Attribytes[1] = shape;
    return incLightClk(clk, pulseTime, waitTime);
}
int run_lightclk(lweapon obj, int clk, int minRad, int maxRad, int pulseTime, int waitTime, int shape)
{
    obj->LightRadius = getLight(clk, minRad, maxRad, pulseTime, waitTime);
    if(shape > -1) obj->LightShape = shape;
    return incLightClk(clk, pulseTime, waitTime);
}
int run_lightclk(eweapon obj, int clk, int minRad, int maxRad, int pulseTime, int waitTime, int shape)
{
    obj->LightRadius = getLight(clk, minRad, maxRad, pulseTime, waitTime);
    if(shape > -1) obj->LightShape = shape;
    return incLightClk(clk, pulseTime, waitTime);
}
int run_lightclk(npc obj, int clk, int minRad, int maxRad, int pulseTime, int waitTime, int shape)
{
    obj->LightRadius = getLight(clk, minRad, maxRad, pulseTime, waitTime);
    if(shape > -1) obj->LightShape = shape;
    return incLightClk(clk, pulseTime, waitTime);
}
int run_lightclk(itemsprite obj, int clk, int minRad, int maxRad, int pulseTime, int waitTime, int shape)
{
    obj->LightRadius = getLight(clk, minRad, maxRad, pulseTime, waitTime);
    if(shape > -1) obj->LightShape = shape;
    return incLightClk(clk, pulseTime, waitTime);
}
int run_lightclk(itemdata obj, int clk, int minRad, int maxRad, int pulseTime, int waitTime, int shape)
{
    obj->Attributes[1] = getLight(clk, minRad, maxRad, pulseTime, waitTime);
    if(shape > -1) obj->Attributes[0] = shape;
    return incLightClk(clk, pulseTime, waitTime);
}

@InitD0("Min Size"), @InitDHelp0("The minimum size of the torch, in pixels. (Usually radius)"),
@InitD1("Max Size"), @InitDHelp1("The maximum size of the torch, in pixels. (Usually radius)"),
@InitD2("Pulse Duration"), @InitDHelp2("The time, in frames, that it takes"
    " to go from min to max, or vice-versa."),
@InitD3("Wait Time"), @InitDHelp3("The time, in frames, that it stops"
    " for when it gets to min or max before starting to go back."),
@InitD4("Shape"), @InitDHelp4("The shape of the light, use the values of the 'LIGHT_'"
    " constants in 'std_constants.zh'. Set to -1 to not set a shape.")
combodata script TorchPulse
{
    void run(int minRad, int maxRad, int pulseTime, int waitTime, int shape)
    {
        int clk;
        while(true)
        {
            clk = run_lightclk(this, clk, minRad, maxRad, pulseTime, waitTime, shape);
            Waitframe();
        }
    }
}

@InitD0("Min Size"), @InitDHelp0("The minimum size of the light, in pixels. (Usually radius)"),
@InitD1("Max Size"), @InitDHelp1("The maximum size of the light, in pixels. (Usually radius)"),
@InitD2("Pulse Duration"), @InitDHelp2("The time, in frames, that it takes"
    " to go from min to max, or vice-versa."),
@InitD3("Wait Time"), @InitDHelp3("The time, in frames, that it stops"
    " for when it gets to min or max before starting to go back.")
lweapon script LW_LightPulse
{
    void run(int minRad, int maxRad, int pulseTime, int waitTime, int shape)
    {
        int clk;
        while(true)
        {
            clk = run_lightclk(this, clk, minRad, maxRad, pulseTime, waitTime, shape);
            Waitframe();
        }
    }
}

@InitD0("Min Size"), @InitDHelp0("The minimum size of the light, in pixels. (Usually radius)"),
@InitD1("Max Size"), @InitDHelp1("The maximum size of the light, in pixels. (Usually radius)"),
@InitD2("Pulse Duration"), @InitDHelp2("The time, in frames, that it takes"
    " to go from min to max, or vice-versa."),
@InitD3("Wait Time"), @InitDHelp3("The time, in frames, that it stops"
    " for when it gets to min or max before starting to go back.")
eweapon script EW_LightPulse
{
    void run(int minRad, int maxRad, int pulseTime, int waitTime, int shape)
    {
        int clk;
        while(true)
        {
            clk = run_lightclk(this, clk, minRad, maxRad, pulseTime, waitTime, shape);
            Waitframe();
        }
    }
}

@InitD0("Min Size"), @InitDHelp0("The minimum size of the light, in pixels. (Usually radius)"),
@InitD1("Max Size"), @InitDHelp1("The maximum size of the light, in pixels. (Usually radius)"),
@InitD2("Pulse Duration"), @InitDHelp2("The time, in frames, that it takes"
    " to go from min to max, or vice-versa."),
@InitD3("Wait Time"), @InitDHelp3("The time, in frames, that it stops"
    " for when it gets to min or max before starting to go back.")
npc script NPC_LightPulse
{
    void run(int minRad, int maxRad, int pulseTime, int waitTime, int shape)
    {
        int clk;
        while(true)
        {
            clk = run_lightclk(this, clk, minRad, maxRad, pulseTime, waitTime, shape);
            Waitframe();
        }
    }
}

@InitD0("Min Size"), @InitDHelp0("The minimum size of the light, in pixels. (Usually radius)"),
@InitD1("Max Size"), @InitDHelp1("The maximum size of the light, in pixels. (Usually radius)"),
@InitD2("Pulse Duration"), @InitDHelp2("The time, in frames, that it takes"
    " to go from min to max, or vice-versa."),
@InitD3("Wait Time"), @InitDHelp3("The time, in frames, that it stops"
    " for when it gets to min or max before starting to go back.")
itemsprite script ItemSprite_LightPulse
{
    void run(int minRad, int maxRad, int pulseTime, int waitTime, int shape)
    {
        int clk;
        while(true)
        {
            clk = run_lightclk(this, clk, minRad, maxRad, pulseTime, waitTime, shape);
            Waitframe();
        }
    }
}


@InitD0("Min Size"), @InitDHelp0("The minimum size of the light, in pixels. (Usually radius)"),
@InitD1("Max Size"), @InitDHelp1("The maximum size of the light, in pixels. (Usually radius)"),
@InitD2("Pulse Duration"), @InitDHelp2("The time, in frames, that it takes"
    " to go from min to max, or vice-versa."),
@InitD3("Wait Time"), @InitDHelp3("The time, in frames, that it stops"
    " for when it gets to min or max before starting to go back.")
itemdata script LanternPulse
{
    void run(int minRad, int maxRad, int pulseTime, int waitTime, int shape)
    {
        int clk;
        while(true)
        {
            clk = run_lightclk(this, clk, minRad, maxRad, pulseTime, waitTime, shape);
            Waitframe();
        }
    }
}