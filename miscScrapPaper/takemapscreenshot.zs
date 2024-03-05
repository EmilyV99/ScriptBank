void takeMapScreenshot()
{
	if(Input->KeyPress[KEY_P])
	{
		Hero->Invisible = true;
		dmapdata dm = Game->LoadDMapData(Game->GetCurDMap());
		bool small = dm->Type != DMAP_OVERWORLD;
		int offs = dm->Offset;
		printf("DMap offset is %d\n", offs);
		//
		int dmpal = dm->Palette;
		int oldscr = Game->GetCurDMapScreen();
		int oldx = Hero->X;
		int oldy = Hero->Y;
		//
		int pals[0x200];
		int palscrs[0x200];
		int ind = 0;
		for(int q = 0; q < 0x80; ++q)
		{
			if(small && (q%0x10) > 0x08) continue;
			mapdata m = Game->LoadMapData(Game->GetCurMap(), q+offs);
			for(int p = 0; p < ind; ++p)
			{
				if(m->Palette == pals[p])
				{
					m = NULL;
					break;
				}
			}
			if(m)
			{
				pals[ind++] = m->Palette;
			}
		}
		bitmap b = create(256*16,176*8);
		for(int q = 0; q < ind; ++q)
		{
			dm->Palette = pals[q];
			b->Clear(C_WHITE);
			for(int x = small ? 7 : 15; x >= 0; --x)
			{
				for(int y = 0; y < 8; ++y)
				{
					int scr = x + (y*0x10);
					mapdata m = Game->LoadMapData(Game->GetCurMap(), scr + offs);
					unless(m->Palette == pals[q])
						continue;
					Hero->Warp(Game->GetCurDMap(), scr);
					repeat(10) Waitframe();
					b->BlitTo(7, RT_SCREEN, 0, 0, 256, 176, (x+offs)*256, y*176, 256, 176,
					          0, 0, 0, 0, 0, true);
					
					for(int lyr = 0; lyr < 7; ++lyr)
					{
						mapdata m = Game->LoadTempScreen(lyr);
						for(int pos = 160; pos < 176; ++pos)
						{
							b->FastCombo(lyr, (x+offs)*256 + (pos%16)*16, y*176 + 7*16, m->ComboD[pos], m->ComboC[pos], (lyr>0?(Screen->LayerOpacity[lyr]<255?OP_OPAQUE:OP_TRANS):OP_OPAQUE));
						}
					}
				}
			}
			char32 buf[256];
			sprintf(buf, "mapscreenshot/dm_%03d/pal_%04d.png", Game->GetCurDMap(), pals[q]);
			b->Write(7, buf, true);
			Waitframe();
		}
		dm->Palette = dmpal;
		Hero->X = oldx; Hero->Y = oldy;
		Hero->PitWarp(Game->GetCurDMap(), oldscr);
		Hero->Invisible = false;
	}
}