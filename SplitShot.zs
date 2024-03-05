#include "std.zh"

@Author("EmilyV"),
@InitD0("Total Shots"), @InitDHelp0("The number of shots to split into, total. Minimum '1'."),
@InitD1("Arc (Degrees)"), @InitDHelp1("The arc between each shot (in degrees)")
lweapon script splitShot
{
    void run(int totalShots, float degreesArc)
    {
        if(totalShots < 2)
            return;
        unless(this->Angular)
        {
            this->Angular = true;
            this->DegAngle = DirAngle(this->Dir);
        }
        float rotOffset = this->DegAngle;
        float degrees = this->DegAngle - (totalShots/2)*degreesArc;
        FireWpn(this,degrees,rotOffset);
        for(int q = 0; q < totalShots; ++q)
        {
            degrees += degreesArc;
            FireWpn(Copy(this),degrees,rotOffset);
        }
    }
    void FireWpn(lweapon wpn, float degAngle, float rotOffset)
    {
        wpn->Angular = true;
        wpn->DegAngle = degAngle;
        wpn->Rotation = degAngle-rotOffset;
    }
    lweapon Copy(lweapon base)
    {
        lweapon copy = Duplicate(base);
        copy->Script = 0;
        return copy;
    }
}
