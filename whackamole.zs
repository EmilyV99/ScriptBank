#include "std.zh"

int wpnsfx(int ewtype)
{
	switch(ewtype)
	{
		case EW_FIRETRAIL:
		case EW_FIRE:
		case EW_FIRE2+1:
		case EW_FIRE2:
			return 13;
			
		case EW_WIND:
		case EW_MAGIC:
			return 32;
			
		case EW_ROCK:
			return 51;
			
		case EW_FIREBALL:
		case EW_FIREBALL2:
			return 40;
	}
	
	return 0;
}

npc script WhackAMole
{
	enum
	{
		V_BURROW_TIMER, V_BURROW_MAXTIME,
		V_BURROW_TYPE, V_ACLK, V_WCLK,
		V_O_TILE, V_NPC, V_FIRED,
		V_HT, V_BT, V_ST, V_FR,
		V_ANGLE, V_ATKSFX, V_HURT,
		V_SIZE
	};
	enum
	{
		BT_NONE, BT_BURROW, BT_SURFACE, BT_HIDDEN
	};
	CONFIG BURROW_FRAMES = 3;
	CONFIG BURROW_OFFSET = 0;
	CONFIG STAND_FRAMES = 2;
	CONFIG STAND_ASPEED = 4;
	CONFIG STAND_OFFSET = 20;
	CONFIG FIRE_FRAMES = 2;
	CONFIG FIRE_ASPEED = 4;
	CONFIG FIRE_OFFSET = 40;
	CONFIG HURT_FRAMES = 1;
	CONFIG HURT_ASPEED = 10;
	CONFIG HURT_OFFSET = 60;
	CONFIG DEATH_FRAMES = 4;
	CONFIG DEATH_ASPEED = 8;
	CONFIG DEATH_OFFSET = 80;
	CONFIG DEATH_SIZE = 2;
	CONFIG DEATH_XOFFS = 0;
	CONFIG DEATH_YOFFS = -16;
	CONFIGB SPRITE_8DIR = false;
	/* 
	 * InitD[0] = Number of frames to stay completely underground
	 * InitD[1] = Number of frames it takes to burrow/resurface
	 * InitD[2] = Number of frames to stay on the surface
	 * InitD[3] = Number of frames between shots
	 * InitD[4] = SFX to use for attack. '-1' will use engine default, '0' uses none.
	 * InitD[5] = timer fuzz (small positive value for random timer changing)
	 */
	void run(int hideTime, int burrowTime, int surfaceTime, int fireRate, int atkSound, int timer_fuzz)
	{
		if(hideTime < 1) hideTime = 1;
		if(burrowTime < 1) burrowTime = 1;
		if(surfaceTime < 1) surfaceTime = 1;
		if(fireRate < 0) fireRate = 0;
		untyped arr[V_SIZE];
		arr[V_NPC] = this;
		arr[V_O_TILE] = this->OriginalTile;
		arr[V_BURROW_TIMER] = surfaceTime;
		arr[V_BURROW_TYPE] = BT_NONE;
		arr[V_HT] = hideTime;
		arr[V_BT] = burrowTime;
		arr[V_ST] = surfaceTime;
		arr[V_FR] = fireRate;
		arr[V_WCLK] = fireRate;
		arr[V_ATKSFX] = atkSound;
		int lasthp = this->HP;
		while(this->HP > 0)
		{
			if(arr[V_BURROW_TIMER]) //Switch states
			{
				unless(--arr[V_BURROW_TIMER]) //Timer ran out
				{
					arr[V_ACLK] = 0;
					arr[V_WCLK] = 0;
					switch(arr[V_BURROW_TYPE])
					{
						case BT_BURROW: //Done burrowing, hidden now
							arr[V_BURROW_TYPE] = BT_HIDDEN;
							arr[V_BURROW_MAXTIME] = arr[V_BURROW_TIMER] = arr[V_HT]+Rand(timer_fuzz);
							this->HitXOffset += 10000;
							this->DrawXOffset += 10000;
							break;
						case BT_HIDDEN: //Done hiding, burrow up
							this->HitXOffset -= 10000;
							this->DrawXOffset -= 10000;
							unless(reposition(arr))
							{ //Failed to find position?
								++arr[V_BURROW_TIMER];
								this->HitXOffset += 10000;
								this->DrawXOffset += 10000;
								break;
							}
							arr[V_ANGLE] = TurnTowards(this->X,this->Y,Hero->X,Hero->Y,0,1);
							arr[V_BURROW_TYPE] = BT_SURFACE;
							arr[V_BURROW_MAXTIME] = arr[V_BURROW_TIMER] = arr[V_BT];
							break;
						case BT_SURFACE: //Done burrowing up, wait
							arr[V_BURROW_TYPE] = BT_NONE;
							arr[V_BURROW_MAXTIME] = arr[V_BURROW_TIMER] = arr[V_ST]+Rand(timer_fuzz);
							arr[V_WCLK] = 1; //Fire immediately
							break;
						case BT_NONE: //Ready to burrow again
							arr[V_BURROW_TYPE] = BT_BURROW;
							arr[V_BURROW_MAXTIME] = arr[V_BURROW_TIMER] = arr[V_BT];
							break;
					}
				}
			}
			//Turn the angle towards the player
			int adjrate = 0.15;
			if(arr[V_BURROW_TYPE] != BT_NONE) adjrate /= 3; //Third as fast when burrowing
			arr[V_ANGLE] = TurnTowards(this->X,this->Y,Hero->X,Hero->Y,arr[V_ANGLE],adjrate);
			this->Dir = RadianAngleDir8(arr[V_ANGLE]);
			
			if(arr[V_FIRED]) --arr[V_FIRED]; //Fire animation timer
			if(this->HP != lasthp)
			{
				if(this->HP < lasthp)
				{
					arr[V_HURT] = HURT_FRAMES*HURT_ASPEED;
				}
				lasthp = this->HP;
			}
			if(arr[V_WCLK]) //Fire weapon
			{
				unless(--arr[V_WCLK])
				{
					arr[V_WCLK] = arr[V_FR];
					arr[V_FIRED] = FIRE_FRAMES*FIRE_ASPEED;
					attack(arr);
				}
			}
			setSprite(arr); //Update animation
			if(arr[V_HURT]) --arr[V_HURT];
			Waitframe();
		}
		
		this->HitXOffset += 10000;
		this->Immortal = true;
		if(DEATH_SIZE > 1)
		{
			this->TileWidth = DEATH_SIZE;
			this->TileHeight = DEATH_SIZE;
			this->Extend = 3;
			this->DrawXOffset = DEATH_XOFFS;
			this->DrawYOffset = DEATH_YOFFS;
		}
		arr[V_HURT] = DEATH_FRAMES*DEATH_ASPEED;
		while(arr[V_HURT])
		{
			setSprite(arr);
			--arr[V_HURT];
			Waitframe();
		}
		this->Immortal = false;
		if(DEATH_SIZE > 1)
		{
			this->TileWidth = 1;
			this->TileHeight = 1;
			this->Extend = 0;
			this->DrawXOffset = 0;
			this->DrawYOffset = 0;
		}
		this->ScriptTile = -1;
	}
	bool reposition(untyped arr)
	{
		bool checked[176];
		int checkcnt;
		npc n = arr[V_NPC];
		int ox = n->X, oy = n->Y;
		while(checkcnt < 176)
		{
			int pos = Rand(176);
			if(checked[pos]) continue;
			checked[pos] = true;
			++checkcnt;
			n->X = ComboX(pos);
			n->Y = ComboY(pos)+1;
			if(Abs(n->X-Hero->X) < 32) continue;
			if(Abs(n->Y-1-Hero->Y) < 32) continue;
			if(n->CanMove(DIR_UP,1,0))
			{
				n->Y--;
				return true;
			}
		}
		n->X = ox;
		n->Y = oy;
		return false;
	}
	void setSprite(untyped arr)
	{
		int tile = arr[V_O_TILE];
		npc n = arr[V_NPC];
		int dir = SPRITE_8DIR ? RadianAngleDir8(arr[V_ANGLE]) : RadianAngleDir4(arr[V_ANGLE]);
		if(n->HP <= 0) //Death animation
		{
			int frame = Div((DEATH_FRAMES*DEATH_ASPEED)-arr[V_HURT],DEATH_ASPEED);
			tile += DEATH_OFFSET;
			int trow = Div(tile,20);
			tile += (frame*DEATH_SIZE);
			int ntrow = Div(tile,20);
			if(trow != ntrow)
			{
				tile += 20*DEATH_SIZE*(ntrow-trow);
			}
		}
		else switch(arr[V_BURROW_TYPE])
		{
			case BT_NONE: //On the surface
			{
				if(arr[V_HURT])
				{
					int frame = Div((HURT_FRAMES*HURT_ASPEED)-arr[V_HURT],HURT_ASPEED);
					tile += HURT_OFFSET+(dir*HURT_FRAMES)+frame;
					arr[V_ACLK] = 0;
					break;
				}
				if(arr[V_FIRED])
				{
					int frame = Div((FIRE_FRAMES*FIRE_ASPEED)-arr[V_FIRED],FIRE_ASPEED);
					tile += FIRE_OFFSET+(dir*FIRE_FRAMES)+frame;
					arr[V_ACLK] = 0;
					break;
				}
				int frame = Div(arr[V_ACLK],STAND_ASPEED);
				if(frame >= STAND_FRAMES)
				{
					frame = 0;
					arr[V_ACLK] = 0;
				}
				else ++arr[V_ACLK];
				tile += STAND_OFFSET+(dir*STAND_FRAMES)+frame;
				break;
			}
			case BT_HIDDEN:
				break; //should be invisible
			case BT_BURROW:
			{
				int clk = arr[V_BURROW_TIMER]-1; //Inverted, so, animates backwards
				int aspeed = Div(arr[V_BURROW_MAXTIME],BURROW_FRAMES);
				int frame = Div(clk,aspeed);
				if(frame >= BURROW_FRAMES) frame = BURROW_FRAMES-1;
				if(frame < 0) frame = 0;
				tile += BURROW_OFFSET+(dir*BURROW_FRAMES)+frame;
				break;
			}
			case BT_SURFACE:
			{
				int clk = arr[V_BURROW_MAXTIME]-arr[V_BURROW_TIMER];
				int aspeed = Div(arr[V_BURROW_MAXTIME],BURROW_FRAMES);
				int frame = Div(clk,aspeed);
				if(frame >= BURROW_FRAMES) frame = BURROW_FRAMES-1;
				if(frame < 0) frame = 0;
				tile += BURROW_OFFSET+(dir*BURROW_FRAMES)+frame;
				break;
			}
		}
		n->ScriptTile = tile;
	}
	void attack(untyped arr)
	{
		npc n = arr[V_NPC];
		unless(n->Weapon) return; //No weapon set
		eweapon weap = CreateEWeaponAt(n->Weapon, n->X, n->Y);
		//Angle the weapon towards the player
		weap->Angular = true;
		weap->Angle = arr[V_ANGLE];
		weap->Dir = RadianAngleDir8(weap->Angle);
		if(n->WeaponSprite) //Override the sprite
			weap->UseSprite(n->WeaponSprite);
		weap->Damage = n->WeaponDamage;
		unless(weap->Step) weap->Step = 100; //Default 100 step speed
		int s = arr[V_ATKSFX];
		if(s < 0)
		{
			s = wpnsfx(n->Weapon);
		}
		if(s) Audio->PlaySound(s);
	}
}
