

@Author("EmilyV"),
@InitD0("Frame Delay"),
@InitDHelp0("Number of frames before the split. Use 0 for instant."),
@InitD1("Arc (deg)"),
@InitDHelp1("The arc, in degrees, between each weapon."),
@InitD2("Weap Count"),
@InitDHelp2("How many weapons to split into.")
lweapon script splitLWeapon
{
	void run(int delay, int degrees, int numWeapons)
	{
		unless(this->Angular)
		{
			this->Angular = true;
			this->DegAngle = DirAngle(this->Dir);
		}
		if(numWeapons < 2)
			return;
		int numExtra = numWeapons-1;
		if(delay > 0)
			Waitframes(delay);
		if(numExtra%2) //Odd number, need to change the angle of the base weapon
		{
			numExtra = (numExtra-1)/2;
			for(int q = 1; q <= numExtra; ++q)
			{
				lweapon left = duplicateWeapon(this);
				lweapon right = duplicateWeapon(this);
				left->DegAngle -= degrees*(q+0.5);
				right->DegAngle += degrees*(q+0.5);
			}
			lweapon offs = duplicateWeapon(this);
			offs->DegAngle -= degrees*0.5;
			this->DegAngle += degrees*0.5;
		}
		else //Even number, evenly between each side
		{
			numExtra/=2;
			for(int q = 1; q <= numExtra; ++q)
			{
				lweapon left = duplicateWeapon(this);
				lweapon right = duplicateWeapon(this);
				left->DegAngle -= degrees*q;
				right->DegAngle += degrees*q;
			}
		}
	}
	
	lweapon duplicateWeapon(lweapon src)
	{
		lweapon weap = Duplicate(src);
		weap->Script = 0;
		return weap;
	}
}
@Author("EmilyV"),
@InitD0("Frame Delay"),
@InitDHelp0("Number of frames before the split. Use 0 for instant."),
@InitD1("Arc (deg)"),
@InitDHelp1("The arc, in degrees, between each weapon."),
@InitD2("Weap Count"),
@InitDHelp2("How many weapons to split into.")
eweapon script splitEWeapon
{
	void run(int delay, int degrees, int numWeapons)
	{
		unless(this->Angular)
		{
			this->Angular = true;
			this->DegAngle = DirAngle(this->Dir);
		}
		if(numWeapons < 2)
			return;
		int numExtra = numWeapons-1;
		if(delay > 0)
			Waitframes(delay);
		if(numExtra%2) //Odd number, need to change the angle of the base weapon
		{
			numExtra = (numExtra-1)/2;
			for(int q = 1; q <= numExtra; ++q)
			{
				eweapon left = duplicateWeapon(this);
				eweapon right = duplicateWeapon(this);
				left->DegAngle -= degrees*(q+0.5);
				right->DegAngle += degrees*(q+0.5);
			}
			eweapon offs = duplicateWeapon(this);
			offs->DegAngle -= degrees*0.5;
			this->DegAngle += degrees*0.5;
		}
		else //Even number, evenly between each side
		{
			numExtra/=2;
			for(int q = 1; q <= numExtra; ++q)
			{
				eweapon left = duplicateWeapon(this);
				eweapon right = duplicateWeapon(this);
				left->DegAngle -= degrees*q;
				right->DegAngle += degrees*q;
			}
		}
	}
	
	eweapon duplicateWeapon(eweapon src)
	{
		eweapon weap = Duplicate(src);
		weap->Script = 0;
		return weap;
	}
}
