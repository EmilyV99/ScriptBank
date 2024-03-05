////////////////////////////
//    Liftable Objects    //
//         V2.0.0         //
//         Emily          //
////////////////////////////
/**
 * Additional script help from:
 * ywkls (inspiration/ideas)
 * Moosh (scrollingDraws.zh, which I modified to work non-globally)
 */
#option SHORT_CIRCUIT on
#option BINARY_32BIT off
#option TRUE_INT_SIZE on
typedef const int DEFINE;
typedef const int CONFIG;

namespace LiftObjects
{
	CONFIG CB_LIFT = CB_A; //Button to press to pick stuff up
	CONFIG CB_THROW = CB_LIFT; //Button that throws a thing
	CONFIG HELD_DRAW_LAYER = 3; //Layer the object is drawn to while over your head
	CONFIG WEAPON_DRAW_LAYER = 3; //Layer the object is drawn to after thrown (including shadow)
	CONFIG TILE_INVIS = 20; //Invisible tile
	CONFIG LW_THROWN = LW_SCRIPT1; //Weapon type
	CONFIG SHADOW_SPRITE = 50; //Weapons/Misc sprite for the shadow. 0 for no shadow.
	CONFIG TOP_GRABBABLE_LAYER = 2; //Highest layer that liftables can be grabbed from
	
	//Combodata attributes/flags
	DEFINE ATTR_SPRITE = 0;
	DEFINE ATTR_DAMAGE = 1;
	DEFINE ATTR_ITEM = 2;
	DEFINE ATTR_IMPACTSFX = 3;
	DEFINE FLAG_NEXTCOMBO = 0x20;
	DEFINE FLAG_SPECIALITEM = 0x40;
	DEFINE FLAG_ONIMPACTITEM = 0x80;
	//Item flags
	DEFINE FLAG_HOLDWATER = 0;
	DEFINE FLAG_DROPHIT = 1;
	DEFINE FLAG_CROSSSCREEN = 2;
	itemdata script PowerBracelet //start
	{
		using namespace scrollingDraws;
		/**
		 * SETUP:
		 * To lift heavy things, set the item's power to a number larger than 1.
		 * The sound set in the item editor is played when lifting an object.
		 * Set this script as the 'Action' script, and under 'Flags',
		 *    make sure that 'Constant Script' ('Flags[15]') is checked.
		 * d0: Throw speed, as Step (100 = 1 pixel per frame)
		 * d1: Throw vertical velocity, as '->Jump' (Pixels per frame vertically,
		 *     as a starting velocity before gravity takes effect)
		 * d2: Lift Delay (How many frames does it take to lift an object)
		 * d3:
		 *     Combo setup for custom player animation:
		 *     Create 16 combos in a row.
		 *     First 4: Up,Down,Left,Right - standing still
		 *     Second 4: Up,Down,Left,Right - walking
		 *     Third 4: Up,Down,Left,Right - swimming
		 *     Fourth 4: Up,Down,Left,Right - Lifting
		 *     d3 should be set to the upper-leftmost combo (The up-facing standing still one)
		 * Item Properties:
		 * UseSound: Lifting SFX. UseSound + 1 should be Throwing SFX. Using '0' will make neither play a sound.
		 * Flags:
		 * Flags[0]: Can carry while swimming
		 * Flags[1]: Will drop if hit
		 * Flags[2]: Can carry across screens
		 * COMBO SETUP:
		 * Attributes[0]: Sprite for the breaking object (eg. shards/crumbled rock)
		 * Attributes[1]: Damage for the thrown LWeapon
		 * Attributes[2]: If negative, this is a dropset. If positive, this is an item ID.
		 * Attributes[3]: Break SFX (on impact)
		 * Misc. Flag 0x20: If checked, the 'next' combo will always be used.
		 *                  - Bush->Next will use the next combo regardless.
		 * Misc. Flag 0x40: If checked, the item will be the room's "Special Item", only
		 *                  spawning if State[ST_SPECIALITEM] is false.
		 *                  - This will use the attribute for the item;
		 *                    if that is 0, it will use the room's catchall.
		 * Misc. Flag 0x80: If checked, the item will appear when the object breaks on impact,
		 *                  instead of undercombo the combo when lifted.
		 */
		void run(int throwspeed, int upthrow, int liftDelay, int COMBO_PLAYER_HOLDING_ANIM)
		{
			Game->FFRules[qr_OLDSPRITEDRAWS] = false; //So ScriptTile works
			Game->FFRules[qr_CHECKSCRIPTWEAPONOFFSCREENCLIP] = true; //So the weapons don't despawn early
			Game->FFRules[qr_WEAPONS_EXTRA_FRAME] = true; //So the weapon's death effect can play
			if(this->Flags[FLAG_CROSSSCREEN]) Game->FFRules[qr_SMOOTHVERTICALSCROLLING] = true; //Won't draw right without this
			combodata held_combo;
			DEFINE NUM_PCOMBO = 16;
			combodata player_combos[NUM_PCOMBO];
			if(COMBO_PLAYER_HOLDING_ANIM)
			{
				for(int q = 0; q < NUM_PCOMBO; ++q)
				{
					player_combos[q] = Game->LoadComboData(COMBO_PLAYER_HOLDING_ANIM+q);
					unless(player_combos[q]->Frames) player_combos[q]->Frames = 1;
					unless(player_combos[q]->ASpeed) player_combos[q]->ASpeed = 1;
				}
			}
			int cset;
			unless(this->WeaponScript) this->WeaponScript = Game->GetLWeaponScript("ThrownObject");
			int globalframe;
			while(true)
			{
				if(Input->Press[CB_LIFT])
				{
					int combo = ComboInFront(Hero->Dir);
					if(combo > -1)
					{
						bool canLift = true; //Assume true for checking Hero-> stuff
						switch(Hero->Action)
						{
							case LA_NONE:
							case LA_WALKING:
								break;
							case LA_SWIMMING:
								unless(this->Flags[FLAG_HOLDWATER])
									canLift = false;
								break;
							default:
								canLift = false;
						}
						if(Hero->Z || Hero->Jump != 0) canLift = false; //No grabbing in mid-air!
						if(canLift) //Valid action / position to lift; check for liftable combo
						{
							canLift = false; //Assume the combo is not liftable
							mapdata currlayer;
							int undercombo;
							int undercset;
							bool placedFlag;
							for(int q = TOP_GRABBABLE_LAYER; !canLift && q >= 0; --q)
							{
								currlayer = Game->LoadTempScreen(q);
								combodata cd = Game->LoadComboData(currlayer->ComboD[combo]);
								undercombo = (cd->UserFlags & FLAG_NEXTCOMBO) ? cd->ID+1 : currlayer->UnderCombo;
								undercset = (cd->UserFlags & FLAG_NEXTCOMBO) ? currlayer->ComboC[combo] : currlayer->UnderCSet;
								switch(cd->Type)
								{
									case CT_BUSHNEXT:
										canLift = true;
										undercombo = cd->ID+1;
										undercset = currlayer->ComboC[combo];
										break;
								}
								switch(currlayer->ComboF[combo])
								{
									case CF_SCRIPT_POT_LIFT:
									case CF_SCRIPT_POT_SLASH_OR_LIFT:
									case CF_SCRIPT_LIFT_NORMAL:
										canLift = true;
										placedFlag = true;
										break;
									case CF_SCRIPT_LIFT_HEAVY:
										canLift = (this->Power > 1);
										placedFlag = true;
										break;
								}
								switch(currlayer->ComboI[combo])
								{
									case CF_SCRIPT_POT_LIFT:
									case CF_SCRIPT_POT_SLASH_OR_LIFT:
									case CF_SCRIPT_LIFT_NORMAL:
										canLift = true;
										break;
									case CF_SCRIPT_LIFT_HEAVY:
										canLift = (this->Power > 1);
										break;
								}
							}
							if(canLift)
							{
								held_combo = Game->LoadComboData(currlayer->ComboD[combo]);
								cset = currlayer->ComboC[combo];
								if(placedFlag) currlayer->ComboF[combo] = 0;
								currlayer->ComboD[combo] = undercombo;
								currlayer->ComboC[combo] = undercset;
								Input->Press[CB_LIFT] = false;
								int spawnItem = held_combo->Attributes[ATTR_ITEM] ? held_combo->Attributes[ATTR_ITEM] : ((held_combo->UserFlags & FLAG_SPECIALITEM) ? Screen->Catchall : NULL);
								if(this->UseSound) Audio->PlaySound(this->UseSound); //Lift sound
								if(liftDelay)
								{
									int ox = ComboX(combo), oy = ComboY(combo), //Original coords
										x = ox, y = oy, //Current coords
										tx = Hero->X, ty = Hero->Y - 8, //Target coords
										dx = (tx - ox) / liftDelay, dy = (ty - oy) / liftDelay, //Change in coords
										minx = (ox < tx) ? ox : tx, maxx = (ox > tx) ? ox : tx, //X bounds
										miny = (oy < ty) ? oy : ty, maxy = (oy > ty) ? oy : ty; //Y bounds
									combodata pcombo = player_combos[Hero->Dir + 12];
									for(int q = 0; q < liftDelay; ++q)
									{
										if(pcombo)
										{
											Hero->ScriptTile = pcombo->Tile;
										}
										Screen->FastCombo(HELD_DRAW_LAYER, x, y, held_combo->ID, cset, OP_OPAQUE);
										x = VBound(x+dx, maxx, minx);
										y = VBound(y+dy, maxy, miny);
										WaitNoAction();
									}
									if(pcombo) Hero->ScriptTile = -1;
								}
								if(spawnItem)
								{
									unless(held_combo->UserFlags & FLAG_ONIMPACTITEM)
									{
										unless(Screen->State[ST_SPECIALITEM] && (held_combo->UserFlags & FLAG_SPECIALITEM))
										{
											int it_id = spawnItem;
											if(it_id < 0) //Dropset
											{
												dropsetdata dr = Game->LoadDropset(-spawnItem);
												it_id = dr->Choose();
											}
											unless(it_id < 0)
											{
												itemsprite it = CreateItemAt(it_id, ComboX(combo), ComboY(combo));
												if(held_combo->UserFlags & FLAG_SPECIALITEM)
													it->Pickup |= IP_ST_SPECIALITEM;
												else
													it->Pickup |= IP_TIMEOUT;
											}
										}
									}
								}
							}
						}
					}
				}
				if(held_combo)
				{
					int scroll_data[SD_SCROLL_DATA_SIZE];
					InitScrollingDraws(scroll_data);
					while(held_combo)
					{
						combodata pcombo = player_combos[Hero->Dir + (Hero->Action==LA_SWIMMING?8:(Hero->Action==LA_WALKING?4:0))];
						if(pcombo)
						{
							Hero->ScriptTile = pcombo->Tile;
						}
						bool is_swimming = (Hero->Action==LA_SWIMMING || Hero->Action==LA_GOTHURTWATER || Hero->Action==LA_HOPPING);
						bool throw = Input->Press[CB_THROW];
						int weapstep = throwspeed;
						switch(Hero->Action)
						{
							case LA_CASTING:
							case LA_HOLD1WATER:
							case LA_HOLD2WATER:
							case LA_HOLD1LAND:
							case LA_HOLD2LAND:
							case LA_INWIND:
							case LA_CAVEWALKUP:
							case LA_CAVEWALKDOWN:
							case LA_DYING:
							case LA_DROWNING:
							case LA_DIVING:
							case LA_WINNING:
								weapstep = 0;
							case LA_ATTACKING:
							case LA_CHARGING:
							case LA_SPINNING:
								throw = true;
								break;
							case LA_SWIMMING:
							case LA_HOPPING:
								unless(this->Flags[FLAG_HOLDWATER])
								{
									weapstep = 0;
									throw = true;
								}
								break;
							case LA_GOTHURTLAND:
							case LA_GOTHURTWATER:
								if(this->Flags[FLAG_DROPHIT])
								{
									weapstep = 0;
									throw = true;
								}
								break;
						}
						if(throw)
						{
							lweapon l = Screen->CreateLWeapon(LW_THROWN);
							l->X = Hero->X;
							l->Y = Hero->Y;
							if(IsSideview())
							{
								l->Y -= 8;
								l->Gravity = true;
							}
							else
							{
								l->Z = 8;
								l->Gravity = false;
							}
							l->Step = weapstep;
							l->Jump = weapstep ? upthrow : 0; //If dropping, no upthrow
							l->Dir = Hero->Dir;
							l->Script = this->WeaponScript;
							l->InitD[0] = held_combo->Attributes[ATTR_ITEM];
							l->InitD[1] = held_combo->Attributes[ATTR_SPRITE];
							l->InitD[2] = held_combo->Attributes[ATTR_IMPACTSFX];
							l->InitD[3] = held_combo->UserFlags;
							l->Damage = held_combo->Attributes[ATTR_DAMAGE];
							l->OriginalTile = held_combo->Tile;
							l->Tile = l->OriginalTile;
							l->NumFrames = held_combo->Frames;
							l->Flip = held_combo->Flip;
							l->CSet = cset;
							//l->HitZHeight = 16;
							held_combo = NULL;
							if(this->UseSound) Audio->PlaySound(this->UseSound+1);
							NoAction();
						}
						KillButton(CB_A);
						KillButton(CB_B);
						KillButton(CB_THROW);
						Waitdraw();
						UpdateScrollingData(scroll_data);
						int xoffs = Hero->DrawXOffset + (Hero->Action==LA_SCROLLING ? scroll_data[SD_NSCX] : 0);
						int yoffs = Hero->DrawYOffset - (Hero->Z + Hero->DrawZOffset) + (Hero->Action==LA_SCROLLING ? scroll_data[SD_NSCY] : 0);
						Screen->FastCombo(HELD_DRAW_LAYER, Hero->X+xoffs, Hero->Y-8+yoffs, held_combo->ID, cset, OP_OPAQUE);
						Waitframe();
						unless(this->Flags[FLAG_CROSSSCREEN] || (scroll_data[SD_SAVELASTSCREEN] == Game->GetCurScreen()))
						{
							held_combo = NULL;
						}
					}
					if(COMBO_PLAYER_HOLDING_ANIM)
						Hero->ScriptTile = -1;
				}
				Waitframe();
			}
		}
		//start helperFunctions
		int ComboInFront(int dir)
		{
			switch(dir)
			{
				case DIR_UP:
					return ComboAt(Hero->X+8, Hero->Y-8);
				case DIR_DOWN:
					return ComboAt(Hero->X+8, Hero->Y+24);
				case DIR_LEFT:
					return ComboAt(Hero->X-8, Hero->Y+8);
				case DIR_RIGHT:
					return ComboAt(Hero->X+24, Hero->Y+8);
			}
			return -1;
		}
		
		void KillButton(int CB)
		{
			Input->Press[CB] = false;
			Input->Button[CB] = false;
		}
		//end helperFunctions
	} //end

	lweapon script ThrownObject //start
	{
		/**
		 * Setup:
		 * impactItem will be dropped when the object breaks.
		 *  -If negative, it will be treated as a dropset, not an item.
		 *  -If 0, no item will spawn.
		 */
		void run(int impactItem, int deathSprite, int breaksound, int flags)
		{
			bool sv = IsSideview();
			int jump = this->Jump;
			int z = this->Z;
			spritedata shadow;
			if(Game->FFRules[qr_WEAPONSHADOWS] && SHADOW_SPRITE > -1)
			{
				shadow = Game->LoadSpriteData(SHADOW_SPRITE);
				unless(shadow->Speed) shadow->Speed = 1;
				unless(shadow->Frames) shadow->Frames = 1;
			}
			int shadowtimer;
			unless(sv)
			{
				this->Jump = 0;
				this->Z = 0;
			}
			else
			{
				if(this->Dir==DIR_UP)
				{
					this->Jump += this->Step/100;
					this->Step = 0;
				}
				else if(this->Dir==DIR_DOWN)
				{
					this->Jump -= this->Step/100;
					this->Step = 0;
				}
			}
			int spawnItem = impactItem ? impactItem : ((flags & FLAG_SPECIALITEM) ? Screen->Catchall : NULL); 
			unless(sv)
			{
				if(shadow) this->ScriptTile = TILE_INVIS;
				while(CanWalk(this->X,this->Y,this->Dir,this->Step/100,true) && z && this->DeadState!=WDS_DEAD)
				{
					z += jump;
					if(z < 0) z = 0;
					jump -= Game->Gravity[GR_STRENGTH];
					this->DrawYOffset = -z;
					if(shadow)
					{
						DEFINE time = shadow->Frames * shadow->Speed;
						DEFINE frame = Div(shadowtimer, shadow->Speed);
						Screen->FastTile(WEAPON_DRAW_LAYER, this->X, this->Y, shadow->Tile + frame, shadow->CSet, Game->FFRules[qr_TRANSSHADOWS] ? OP_TRANS : OP_OPAQUE);
						shadowtimer = (shadowtimer+1)%time;
						Screen->FastTile(WEAPON_DRAW_LAYER, this->X + this->DrawXOffset, this->Y + this->DrawYOffset, this->Tile, this->CSet, OP_OPAQUE);
					}
					Waitframe();
				}
				this->ScriptTile = -1;
			}
			else
			{
				if(this->Dir==DIR_UP || this->Dir==DIR_DOWN)
				{
					while(CanWalk(this->X,this->Y,this->Jump>0?DIR_UP:DIR_DOWN,Max(1,Abs(this->Jump)),true)
					      && this->DeadState!=WDS_DEAD)
					{
						this->Dir = this->Jump>0?DIR_UP:DIR_DOWN;
						Waitframe();
					}
				}
				else
				{
					while(CanWalk(this->X,this->Y,this->Dir,this->Step/100,true)
					      && CanWalk(this->X,this->Y,this->Jump>0?DIR_UP:DIR_DOWN,Max(1,Abs(this->Jump)),true)
						   && this->DeadState!=WDS_DEAD)
					{
						Waitframe();
					}
				}
			}
			if(spawnItem)
			{
				if(flags & FLAG_ONIMPACTITEM)
				{
					unless(Screen->State[ST_SPECIALITEM] && (flags & FLAG_SPECIALITEM))
					{
						int it_id = spawnItem;
						if(it_id < 0) //Dropset
						{
							dropsetdata dr = Game->LoadDropset(-spawnItem);
							it_id = dr->Choose();
						}
						unless(it_id < 0)
						{
							itemsprite it = CreateItemAt(it_id, this->X, this->Y);
							it->Z = z;
							if(flags & FLAG_SPECIALITEM)
								it->Pickup |= IP_ST_SPECIALITEM;
							else
								it->Pickup |= IP_TIMEOUT;
						}
					}
				}
			}
			Audio->PlaySound(breaksound);
			if(deathSprite)
			{
				this->DeadState = WDS_ALIVE;
				int cset = this->CSet;
				this->UseSprite(deathSprite);
				this->CSet = cset;
				this->Behind = true;
				this->Frame = 0;
				this->Step = 0;
				this->Gravity = false;
				this->CollDetection = false;
				Waitframes((this->ASpeed?this->ASpeed:1) * (this->NumFrames?this->NumFrames:1) - 1);
			}
			Remove(this);
		}
		
		//start Screen edge functions
		DEFINE SCREDGE_LEFT = 8;
		DEFINE SCREDGE_RIGHT = 232;
		DEFINE SCREDGE_TOP = 8;
		DEFINE SCREDGE_BOTTOM = 152;
		bool offscreen(int x, int y)
		{
			return x <= SCREDGE_LEFT || x >= SCREDGE_RIGHT || y <= SCREDGE_TOP || y >= SCREDGE_BOTTOM;
		}
		//end
	} //end
}

namespace scrollingDraws //start
{
	enum
	{
		SD_NSCX,
		SD_NSCY,
		SD_OSCX,
		SD_OSCY,
		SD_SAVELASTSCREEN,
		SD_LASTSCREEN,
		SD_SCROLLDIR,
		SD_SCROLLTIMER,
		SD_SCROLL_DATA_SIZE
	};
	
	void InitScrollingDraws(int scrollingDraws)
	{
		scrollingDraws[SD_SAVELASTSCREEN] = Game->GetCurScreen();
		scrollingDraws[SD_SCROLLTIMER] = -1; 
		scrollingDraws[SD_NSCX] = -1000;
		scrollingDraws[SD_NSCY] = -1000;
		scrollingDraws[SD_OSCX] = 0;
		scrollingDraws[SD_OSCY] = 0;
	}
	
	void UpdateScrollingData(int scrollingDraws)
	{
		if(Hero->Action==LA_SCROLLING)
		{
			bool fast = Game->FFRules[qr_VERYFASTSCROLLING];
			bool fixed = Game->FFRules[qr_FIXSCRIPTSDURINGSCROLLING];
			//Try to get the direction the screen is scrolling based on the position of the last screen visited
			if(Game->GetCurScreen()==scrollingDraws[SD_LASTSCREEN]-16)
				scrollingDraws[SD_SCROLLDIR] = DIR_UP;
			else if(Game->GetCurScreen()==scrollingDraws[SD_LASTSCREEN]+16)
				scrollingDraws[SD_SCROLLDIR] = DIR_DOWN;
			else if(Game->GetCurScreen()==scrollingDraws[SD_LASTSCREEN]-1)
				scrollingDraws[SD_SCROLLDIR] = DIR_LEFT;
			else if(Game->GetCurScreen()==scrollingDraws[SD_LASTSCREEN]+1)
				scrollingDraws[SD_SCROLLDIR] = DIR_RIGHT;	
				
			//If just started scrolling, reset the timer
			if(scrollingDraws[SD_SCROLLTIMER]==-1)
			{
				scrollingDraws[SD_SCROLLTIMER] = 0;
				if(fixed && !fast) return; //No update first frame
			}
			
			//Change max timer frames to account for Fast Scrolling
			int framesX = fast?16:64;
			int framesY = fast?11:44;
			
			//There's a few extra frames after the screen stops visibly scrolling. Clamp the timer to accommodate.
			int scrollmax;
			switch(scrollingDraws[SD_SCROLLDIR])
			{
				case DIR_UP:
					scrollmax = framesY+1;
					break;
				case DIR_DOWN:
					scrollmax = framesY;
					break;
				case DIR_LEFT:
					scrollmax = framesX;
					break;
				case DIR_RIGHT:
					scrollmax = framesX+1;
			}
			int i = Clamp(scrollingDraws[SD_SCROLLTIMER], 0, scrollmax);
			
			int incrementX = 256/framesX;
			int incrementY = 176/framesY;
			//Set screen positions based on the timer
			switch(scrollingDraws[SD_SCROLLDIR])
			{
				case DIR_UP:
					scrollingDraws[SD_NSCX] = 0;
					scrollingDraws[SD_NSCY] = -176+incrementY*i;
					if(scrollingDraws[SD_NSCY]>-20) scrollingDraws[SD_NSCY]+=4;
					if(scrollingDraws[SD_NSCY]>=8) scrollingDraws[SD_NSCY] = 0;
					scrollingDraws[SD_OSCX] = 0;
					scrollingDraws[SD_OSCY] = incrementY*i;
					break;
				case DIR_DOWN:
					scrollingDraws[SD_NSCX] = 0;
					unless(fast && scrollingDraws[SD_NSCY]==16)
						scrollingDraws[SD_NSCY] = 176-incrementY*i;
					else
						scrollingDraws[SD_NSCY] = 12;
					scrollingDraws[SD_OSCX] = 0;
					scrollingDraws[SD_OSCY] = -incrementY*i;
					break;
				case DIR_LEFT:
					unless(fast && scrollingDraws[SD_NSCX]==-16)
						scrollingDraws[SD_NSCX] = -256+incrementX*i;
					else
						scrollingDraws[SD_NSCX] = -12;
					scrollingDraws[SD_NSCY] = 0;
					scrollingDraws[SD_OSCX] = incrementX*i;
					scrollingDraws[SD_OSCY] = 0;
					break;
				case DIR_RIGHT:
					scrollingDraws[SD_NSCX] = 256-incrementX*i;
					if(scrollingDraws[SD_NSCX]<20) scrollingDraws[SD_NSCX]-=4;
					if(scrollingDraws[SD_NSCX]<=-8) scrollingDraws[SD_NSCX] = 0;
					scrollingDraws[SD_NSCY] = 0;
					scrollingDraws[SD_OSCX] = -incrementX*i;
					scrollingDraws[SD_OSCY] = 0;
			}
			
			if(scrollingDraws[SD_SCROLLTIMER]>=0)
				++scrollingDraws[SD_SCROLLTIMER];
		}
		else //Vars are reset when not scrolling
		{
			InitScrollingDraws(scrollingDraws);
		}
		
		scrollingDraws[SD_LASTSCREEN] = Game->GetCurScreen();
	}
	
	int HeroX(int scrollingDraws)
	{
		if(Hero->Action == LA_SCROLLING)
			return Hero->X + scrollingDraws[SD_NSCX];
		return Hero->X;
	}
	
	int HeroY(int scrollingDraws)
	{
		if(Hero->Action == LA_SCROLLING)
			return Hero->Y + scrollingDraws[SD_NSCY];
		return Hero->Y;
	}
} //end
