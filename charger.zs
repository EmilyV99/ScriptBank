
@Author("EmilyV")
npc script Charger
{
	CONFIG SFX_HITWALL = 0;
	void run()
	{
		int wanderStep = this->Step;
		int chargeStep = this->Step*3;
		while(true)
		{
			if(this->LinedUp(256)) //lined up with the player, any distance
			{
				//Start charge
				this->Step = 0; //stop engine movement
				int chargedir = AngleDir4(Angle(this->X, this->Y, Hero->X, Hero->Y));
				while(true)
				{
					if(Hero->HitBy[HIT_BY_NPC_UID] == this)
						break; //Stop charging if hits the player
					unless(this->Move(chargedir, chargeStep/100))
					{
						this->Stun = 300; //Stunned if hits a wall
						if(SFX_HITWALL)
							Audio->PlaySound(SFX_HITWALL);
						break;
					}
					Waitframe();
				}
				this->Step = wanderStep;
			}
			//Wait
			Waitframe();
			//If stunned, wait until stun wears off
			while(this->Stun)
				Waitframe();
		}
	}
}
