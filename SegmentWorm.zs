/**
* Author: Emily
* Version: 1.1
* Release: 31 May, 2021
* Dependencies: "EmilyMisc.zh" version 1.3
*/

#option HEADER_GUARD on
#option TRUNCATE_DIVISION_BY_LITERAL_BUG off
#option SHORT_CIRCUIT on
#option BOOL_TRUE_RETURN_DECIMAL off
#include "EmilyMisc.zh"

typedef const int DEFINE; //DEFINE constants should not be changed unless you know what you are doing!
typedef const int CONFIG; //CONFIG constants can be changed as you wish, usually with directions as to what they should be.
typedef untyped u; //Just for shorthand, doesn't mean anything special.

CONFIG TILE_INVIS = 5; //Invisible tile
CONFIG WORM_SEGMENT_DISTANCE = 16; //Space between segments. Affects compactness of the worm.
DEFINE WORM_SEGMENT_DELAY = WORM_SEGMENT_DISTANCE; //The indexes 0 - WORM_SEGMENT_DELAY of worm->Misc[] are used for movement calculations. Messing with this number can have adverse effects.

/**
* D0: Number of segments for this worm. Minimum 2.
* D1: Number of frames to wait before turning. Will turn sooner if it hits a wall.
* D2: Leave this at 0. Used by the script.
* D3: Leave this at 0. Used by the script.
* D4+: Unused
* 
* Tile setup: For whatever animation style you use, make it 3 rows tall.
* The first row should be a middle segment.
* The second row should be a head segment.
* The third row should be a tail segment.
*/
@Author("Emily")
npc script worm //start
{
	void run(int segments, int turntime, npc front, npc back) //start
	{
		this->ScriptTile = TILE_INVIS;
		unless(front->isValid()) //If this is the first head
		{
			this->Dir = Rand(8);//Any 8-dir direction
		}
		if(--segments)
		{
			//Create the segment behind this one
			back = Emily::RunNPCScript(this->ID, this->Script, (untyped[8]){segments, turntime, this, 0});
			back->Dir = this->Dir;
			if(Emily::CanWalkM(this, Game->LoadTempScreen(0), OppositeDir(this->Dir), 16))
			{
				back->X = this->X - (Emily::dirX(this->Dir) * WORM_SEGMENT_DISTANCE);
				back->Y = this->Y - (Emily::dirY(this->Dir) * WORM_SEGMENT_DISTANCE);
				if(back->X < 0 || back->X > 240)
				{
					back->X = VBound(back->X,240,0);
					back->Dir = Emily::remX(back->Dir);
				}
				if(back->Y < 0 || back->Y > 160)
				{
					back->Y = VBound(back->Y,160,0);
					back->Dir = Emily::remY(back->Dir);
				}
			}
			else
			{
				back->Dir = -1;
				back->X = this->X;
				back->Y = this->Y;
			}
			for(int q = 0; q <= WORM_SEGMENT_DELAY; ++q)
				back->Misc[q] = back->Dir;
			if(back->Dir==-1)back->Dir = this->Dir;
		}
		while(front->isValid()) //start Not the head
		{
			unless(back->isValid()) //start Become the tail
			{
				this->OriginalTile += 40;//Go to row 3 for tail sprite
				while(front->isValid())
				{
					if(this->Misc[0] != -1)
					{
						this->Dir = this->Misc[0];
						this->X = VBound(this->X + Emily::dirX(this->Dir),240,0);
						this->Y = VBound(this->Y + Emily::dirY(this->Dir),160,0);
						//this->ConstantWalk8({100,100,100});
					}
					for(int q = 0; q < WORM_SEGMENT_DELAY; ++q)
						this->Misc[q] = this->Misc[q+1];
					Emily::MooshDrawTile(6, this->X+8, this->Y+8, this->OriginalTile, 1, 1, this->CSet, -1, -1, this->X+8, this->Y+8, DirAngle(this->Dir), 0, true, OP_OPAQUE);
					Waitframe();
				}
				//Only 1 segment; cannot survive!
				this->HP = 0;
				Quit();
			} //end Tail
			if(this->Misc[0] != -1)
			{
				this->Dir = this->Misc[0];
				this->X = VBound(this->X + Emily::dirX(this->Dir),240,0);
				this->Y = VBound(this->Y + Emily::dirY(this->Dir),160,0);
				//this->ConstantWalk8({100,100,100});
			}
			back->Misc[WORM_SEGMENT_DELAY] = this->Misc[0];
			for(int q = 0; q < WORM_SEGMENT_DELAY; ++q)
				this->Misc[q] = this->Misc[q+1];
			Emily::MooshDrawTile(6, this->X+8, this->Y+8, this->OriginalTile, 1, 1, this->CSet, -1, -1, this->X+8, this->Y+8, DirAngle(this->Dir), 0, true, OP_OPAQUE);
			Waitframe();
		} //end Not Head
		//Become the Head
		this->OriginalTile += 20;//Go to row 2 for head sprite
		int timer = turntime;
		while(back->isValid()) //start Control the worm
		{
			if(!(--timer) || !Emily::CanWalkM(this, Game->LoadTempScreen(0), this->Dir, 1))
			{
				timer = turntime;
				do
				{
					this->Dir = Emily::SpinDir8(this->Dir, Choose(1,-1));
				} until(Emily::CanWalkM(this, Game->LoadTempScreen(0), this->Dir, 1));
			}
			this->X = VBound(this->X + Emily::dirX(this->Dir),240,0);
			this->Y = VBound(this->Y + Emily::dirY(this->Dir),160,0);
			//this->ConstantWalk8({100,100,100});
			back->Misc[WORM_SEGMENT_DELAY] = this->Dir;
			Emily::MooshDrawTile(6, this->X+8, this->Y+8, this->OriginalTile, 1, 1, this->CSet, -1, -1, this->X+8, this->Y+8, DirAngle(this->Dir), 0, true, OP_OPAQUE);
			Waitframe();
		} //end Control
		//Only 1 segment; cannot survive!
		this->HP = 0;
	} //end
} //end
