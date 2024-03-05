//Completely untested ball and chain script -Emily

void DrawChain(int lyr, int sx, int sy, int dx, int dy, int tile, int cs, int count)
{
	int degrees = Angle(sx,sy,dx,dy);
	for(int q = 0; q < count; ++q)
	{
		int x = Lerp(sx, dx, (q+1)/(count+1));
		int y = Lerp(sy, dy, (q+1)/(count+1));
		Screen->DrawTile(lyr, x-8, y-8, tile, 1, 1, cs, -1, -1, -777, -777, degrees, 0, true, OP_OPAQUE);
	}
}

DEFINE CHAIN_TILE = 0;
DEFINE CHAIN_CSET = 0;
@Author("EmilyV"), @InitD0("Max Distance"), @InitDHelp0("Distance, in pixels, before the ball returns"),
@InitD1("Num Chains"), @InitDHelp1("The number of chain graphics to stretch")
eweapon script BallAndChain
{
	void run(int maxdist, int num_chains)
	{
		npc n = this->Parent;
		bool bounced = false;
		while(this->DeadState != WDS_DEAD && n->isValid())
		{
			int dist = Distance(CenterX(this),CenterY(this),CenterX(n),CenterY(n));
			if(bounced)
			{
				if(dist < 4) //Too close, kill weapon!
					break;
				//Make sure it's moving towards the enemy during the rebound
				this->Angle = Angle(CenterX(this),CenterY(this),CenterX(n),CenterY(n));
			}
			else if(dist >= maxdist)
				bounced = true; //Too far from the enemy, rebound
			DrawChain(3, CenterX(this), CenterY(this),
				CenterX(n), CenterY(n), CHAIN_TILE,
				CHAIN_CSET, num_chains);
			Waitframe();
		}
		this->Remove();
	}
}

