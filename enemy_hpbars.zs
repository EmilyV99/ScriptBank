#include "std.zh"
#include "EmilyMisc.zh"

namespace EnemyHP
{
	//Change these as you like to configure the script
	CONFIG ENMHP_DAMAGE_TIME = 120; //time in frames damage numbers linger for
	CONFIG ENMHP_DAMAGE_COMBO_TIME = 60; //time in frames to allow comboing damage
	CONFIG ENMHP_DAMAGE_DRIFT_RATE = 4; //time in frames between drifting upwards
	CONFIG ENMHP_DAMAGE_DRIFT_AMNT = 1; //amount in pixels to drift per rate
	CONFIG ENMHP_DAMAGE_LAYER = 7; //Layer to draw damage numbers on
	CONFIG ENMHP_DAMAGE_Y_OFFSET = -2; //Damage numbers are offset by this much
	CONFIGB ENMHP_DAMAGE_FADEOUT = true; //If damage numbers become transparent halfway through their time

	CONFIG ENMHP_BAR_HEIGHT = 5; //height of the bar, min 3
	CONFIG ENMHP_BAR_INCREMENT = 16; //hp per 'segment', 0 for no segments
	CONFIG ENMHP_BAR_YOFFSET = -ENMHP_BAR_HEIGHT; //y offset to draw the bar at
	CONFIG ENMHP_BAR_LAYER = 7; //Layer to draw HP bars on
	CONFIGB ENMHP_BAR_SHOW_NUMBERS = true; //to show numbers or not
	CONFIGB ENMHP_NO_OVER_SUBSCREEN = true; //avoid displaying over the subscreen

	CONFIG ENMHP_DAMAGE_FONT = FONT_Z3SMALL; //Damage text font
	CONFIG ENMHP_BAR_FONT = FONT_Z3SMALL; //Bar text font
	CONFIG ENMHP_DAMAGE_SHADOW = SHD_SHADOWED;
	CONFIG ENMHP_BAR_SHADOW = SHD_SHADOWED;


	CONFIG COLOR_ENMHP_DAMAGE = 0x81;
	CONFIG COLOR_ENMHP_NEUTRAL = 0x01;
	CONFIG COLOR_ENMHP_HEAL = 0x07;

	CONFIG COLOR_ENMHP_GOODHP = 0x07;
	CONFIG COLOR_ENMHP_MEDHP = 0x08;
	CONFIG COLOR_ENMHP_LOWHP = 0x81;
	CONFIG COLOR_ENMHP_BG = 0x0F;
	CONFIG COLOR_ENMHP_BORDER = 0x01;

	CONFIG COLOR_ENMHP_TEXT = 0x01;
	CONFIG COLOR_ENMHP_SHADOW = 0x0F;

	CONFIGB ENMHP_CURHP_USE_COLOR = true;

	CONFIGB ENMHP_DEFAULT_DAMAGENUMBERS = true;
	CONFIGB ENMHP_DEFAULT_BARS = true;

	CONFIG ENMHP_MISC_INDX = 0;
	
	//Do not change these
	DEFINEL ENMHP_FLAG_DAMAGENUMBERS = 001Lb;
	DEFINEL ENMHP_FLAG_BARS          = 010Lb;
	DEFINEL ENMHP_FLAG_DONE_DMGNUM   = 100Lb;
	DEFINEL ENMHP_DEF_FLAGS = (ENMHP_DEFAULT_DAMAGENUMBERS ? ENMHP_FLAG_DAMAGENUMBERS : 0)
		| (ENMHP_DEFAULT_BARS ? ENMHP_FLAG_BARS : 0);


	generic script enemyHP
	{
		enum
		{
			EHP_FLAGS, EHP_LAST, EHP_MAX,
			EHP_NPCPTR, EHP_BARW, EHP_BMP,
			EHP_LATEST_DMGNUM, EHP_DMGX, EHP_DMGY,
			EHP_DEFSZ
		};
		enum
		{
			HT_BMP,
			HT_X,HT_Y,
			HT_CLK, HT_NUM,
			HT_SZ
		};
		
		genericdata gd;
		void _draw_enhpbar(untyped arr)
		{
			npc n = arr[EHP_NPCPTR];
			bool init = false;
			int w = arr[EHP_BARW], h = ENMHP_BAR_HEIGHT+Text->FontHeight(ENMHP_BAR_FONT)+1;
			bitmap bmp = arr[EHP_BMP];
			unless(arr[EHP_BMP])
			{
				bmp = arr[EHP_BMP] = Emily::create(w,h);
				bmp->Own();
				init = true;
			}
			if(init || n->HP != arr[EHP_LAST])
			{
				bmp->Clear(0);
				float perc = n->HP / arr[EHP_MAX];
				int color = (perc < 0.34 ? COLOR_ENMHP_LOWHP : (perc > 0.66 ? COLOR_ENMHP_GOODHP : COLOR_ENMHP_MEDHP));
				if(ENMHP_BAR_SHOW_NUMBERS)
				{
					int tcol = ENMHP_CURHP_USE_COLOR ? color : COLOR_ENMHP_TEXT;
					char32 buf1[10];
					char32 buf2[10];
					sprintf(buf1, "%d", n->HP);
					sprintf(buf2, "/%d", arr[EHP_MAX]);
					bmp->DrawString(0,0,0,ENMHP_BAR_FONT,tcol,-1,TF_NORMAL,buf1,OP_OPAQUE,ENMHP_BAR_SHADOW,COLOR_ENMHP_SHADOW);
					bmp->DrawString(0,Text->StringWidth(buf1,ENMHP_BAR_FONT),0,ENMHP_BAR_FONT,COLOR_ENMHP_TEXT,-1,TF_NORMAL,buf2,OP_OPAQUE,ENMHP_BAR_SHADOW,COLOR_ENMHP_SHADOW);
				}
				int filled_x = Floor(perc*w);
				int y = Text->FontHeight(ENMHP_BAR_FONT)+1;
				bmp->Rectangle(0,0,y,w-1,h-1,COLOR_ENMHP_BG,1,0,0,0,true,OP_OPAQUE);
				bmp->Rectangle(0,0,y,filled_x,h-1,color,1,0,0,0,true,OP_OPAQUE);
				for(int q = ENMHP_BAR_INCREMENT; q > 0 && q < arr[EHP_MAX]; q += ENMHP_BAR_INCREMENT)
				{
					int incx = Floor((q / arr[EHP_MAX])*w);
					bmp->Line(0,incx,y,incx,h-1,COLOR_ENMHP_BG,1,0,0,0,OP_OPAQUE);
				}
				bmp->Rectangle(0,0,y,w-1,h-1,COLOR_ENMHP_BORDER,1,0,0,0,false,OP_OPAQUE);
			}
			int x = n->X;
			int ow = n->TileWidth*16;
			if(ow < w)
			{
				x -= (w - ow)/2;
			}
			int y = n->Y + ENMHP_BAR_YOFFSET - (ENMHP_BAR_SHOW_NUMBERS ? Text->FontHeight(ENMHP_BAR_FONT)+1 : 0);
			if(ENMHP_NO_OVER_SUBSCREEN && y < 0) y = 0;
			bmp->Blit(ENMHP_BAR_LAYER, RT_SCREEN, 0, 0, w, h, x, y, w, h, 0, 0, 0, BITDX_NORMAL, 0, true);
		}
		void _do_dmgnum(untyped arr)
		{
			npc n = arr[EHP_NPCPTR];
			int curhp = n->isValid() ? n->HP : 0;
			int dmgamnt = curhp - arr[EHP_LAST];
			int len = SizeOfArray(arr);
			int ind = -1;
			if(len > EHP_DEFSZ)
			{
				if(arr[EHP_LATEST_DMGNUM])
				{
					ind = arr[EHP_LATEST_DMGNUM];
					if(!arr[ind+HT_BMP] || arr[ind+HT_CLK] > ENMHP_DAMAGE_COMBO_TIME)
						ind = -1;
					else
					{
						dmgamnt += arr[ind+HT_NUM];
						<bitmap>(arr[ind+HT_BMP])->Free();
					}
				}
				if(ind < 0) for(int q = EHP_DEFSZ; q < len; q += HT_SZ)
				{
					unless(arr[q+HT_BMP])
					{
						ind = q;
						break;
					}
				}
			}
			if(ind < 0)
			{
				ResizeArray(arr, len+HT_SZ);
				ind = len;
				len += HT_SZ;
			}
			arr[EHP_LATEST_DMGNUM] = ind;
			char32 buf[10];
			if(dmgamnt > 0)
				sprintf(buf, "+%d", dmgamnt);
			else sprintf(buf, "%d", dmgamnt);
			int w = Text->StringWidth(buf, ENMHP_DAMAGE_FONT);
			int h = Text->FontHeight(ENMHP_DAMAGE_FONT);
			bitmap bmp = arr[ind+HT_BMP] = Emily::create(w,h);
			int color = (dmgamnt > 0 ? COLOR_ENMHP_HEAL : (dmgamnt < 0 ? COLOR_ENMHP_DAMAGE : COLOR_ENMHP_NEUTRAL));
			bmp->Own();
			bmp->Clear(0);
			bmp->DrawString(0,0,0,ENMHP_DAMAGE_FONT,color,-1,TF_NORMAL,buf,OP_OPAQUE,ENMHP_DAMAGE_SHADOW,COLOR_ENMHP_SHADOW);
			if(n->isValid())
			{
				arr[EHP_DMGX] = arr[ind+HT_X] = n->X+(n->TileWidth*8)-(w/2);
				arr[EHP_DMGY] = arr[ind+HT_Y] = n->Y+ENMHP_DAMAGE_Y_OFFSET;
			}
			else
			{
				arr[ind+HT_X] = arr[EHP_DMGX];
				arr[ind+HT_Y] = arr[EHP_DMGY];
			}
			arr[ind+HT_CLK] = 0;
			arr[ind+HT_NUM] = dmgamnt;
		}
		void _run_dmgnum(untyped arr)
		{
			int len = SizeOfArray(arr);
			bool ran = false;
			for(int q = EHP_DEFSZ; q < len; q += HT_SZ)
			{
				if(bitmap bmp = arr[q+HT_BMP])
				{
					int mode = BITDX_NORMAL;
					if(ENMHP_DAMAGE_FADEOUT && arr[q+HT_CLK] >= (ENMHP_DAMAGE_TIME/2))
						mode = BITDX_TRANS;
					bmp->Blit(ENMHP_DAMAGE_LAYER, RT_SCREEN,
						0, 0, bmp->Width, bmp->Height,
						arr[q+HT_X], arr[q+HT_Y], bmp->Width, bmp->Height,
						0, 0, 0, mode, 0, true);
					unless(arr[q+HT_CLK] % ENMHP_DAMAGE_DRIFT_RATE)
					{
						arr[q+HT_Y] -= ENMHP_DAMAGE_DRIFT_AMNT;
					}
					if(arr[q+HT_CLK]++ == ENMHP_DAMAGE_TIME)
					{
						bmp->Free();
						arr[q+HT_BMP] = NULL;
					}
					ran = true;
				}
			}
			if(ran)
				arr[EHP_FLAGS] ~= ENMHP_FLAG_DONE_DMGNUM;
			else arr[EHP_FLAGS] |= ENMHP_FLAG_DONE_DMGNUM;
		}
		untyped narr[2];
		void _ensure_arr(npc n)
		{
			untyped arr = n->Misc[ENMHP_MISC_INDX];
			unless(IsValidArray(arr))
			{
				untyped arr[EHP_DEFSZ] = {ENMHP_DEF_FLAGS, n->HP, n->HP};
				int w = n->TileWidth*16;
				char32 buf[32];
				if(ENMHP_BAR_SHOW_NUMBERS)
					sprintf(buf, "%d/%d", n->HP, n->HP);
				arr[EHP_BARW] = Max(w, Text->StringWidth(buf, ENMHP_BAR_FONT));
				arr[EHP_NPCPTR] = n;
				OwnArray(arr); //places array at script scope
				n->Misc[ENMHP_MISC_INDX] = arr;
				int sz = Max(narr[0],0);
				ResizeArray(narr, sz+2);
				narr[sz+1] = arr;
				narr[0] = sz+1;
			}
		}
		void run()
		{
			gd = this;
			this->ReloadState[GENSCR_ST_CHANGE_SCREEN] = true;
			ResizeArray(narr, 1);
			narr[0] = 0;
			while(true)
			{
				WaitTo(SCR_TIMING_PRE_DRAW, false);
				for(int q = 1; q <= Screen->NumNPCs(); ++q)
				{
					_ensure_arr(Screen->LoadNPC(q));
				}
				for(int q = 1; q <= narr[0]; ++q)
				{
					untyped arr = narr[q];
					unless(IsValidArray(arr)) continue;
					npc n = arr[EHP_NPCPTR];
					OwnArray(arr);
					bool quit = false;
					bool valid = n->isValid();
					int curhp = valid ? n->HP : 0;
					if(valid && (arr[EHP_FLAGS] & ENMHP_FLAG_BARS))
					{
						_draw_enhpbar(arr);
					}
					if(arr[EHP_FLAGS] & ENMHP_FLAG_DAMAGENUMBERS)
					{
						if(curhp != arr[EHP_LAST])
							_do_dmgnum(arr);
						_run_dmgnum(arr);
						unless(valid)
						{
							if(arr[EHP_FLAGS] & ENMHP_FLAG_DONE_DMGNUM)
								quit = true;
						}
					}
					else unless(valid) quit = true;
					if(quit)
					{
						if(arr[EHP_BMP])
							<bitmap>(arr[EHP_BMP])->Free();
						DestroyArray(arr);
						narr[q] = NULL;
						continue;
					}
					arr[EHP_LAST] = curhp;
				}
				Waitframe();
			}
		}
		void init()
		{
			if(int scr = CheckGenericScript("enemyHP"))
			{
				gd = Game->LoadGenericData(scr);
				gd->Running = true;
			}
		}
		void set_damagenums(npc n, bool state)
		{
			_ensure_arr(n);
			untyped arr = n->Misc[ENMHP_MISC_INDX];
			if(state)
				arr[EHP_FLAGS] |= ENMHP_FLAG_DAMAGENUMBERS;
			else arr[EHP_FLAGS] ~= ENMHP_FLAG_DAMAGENUMBERS;
		}
		void set_hpbar(npc n, bool state)
		{
			_ensure_arr(n);
			untyped arr = n->Misc[ENMHP_MISC_INDX];
			if(state)
				arr[EHP_FLAGS] |= ENMHP_FLAG_BARS;
			else arr[EHP_FLAGS] ~= ENMHP_FLAG_BARS;
		}
	}

	global script ehpExampleOnLaunch
	{
		void run()
		{
			enemyHP.init();
		}
	}
}
