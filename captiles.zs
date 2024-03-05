#option SHORT_CIRCUIT on

void drawcount_wait()
{
	if(Graphics->NumDraws() >= Graphics->MaxDraws())
		WaitNoAction();
}
bitmap create(int w, int h)
{
	if(Game->FFRules[qr_OLDCREATEBITMAP_ARGS])
		return Game->CreateBitmap(h, w);
	else
		return Game->CreateBitmap(w, h);
}

DEFINE TILES_PER_ROW = 20;
DEFINE TILEROWS_PER_PAGE = 13;
DEFINE TILES_PER_PAGE = TILEROWS_PER_PAGE*TILES_PER_ROW;
DEFINE TILEROWS_TOTAL = TILEROWS_PER_PAGE*TILE_PAGES;

DEFINE TILE_PAGES = 825;
CONFIG CAPTURE_CSETS = 12;
DEFINE TILES_MAX = TILES_PER_PAGE*TILE_PAGES;

int get_lasttile()
{
	for(int q = TILES_MAX -1; q >= 0; --q)
	{
		unless(Graphics->IsBlankTile[q])
			return q;
	}
}

void captureTiles()
{
	Game->FFRules[qr_OLD_PRINTF_ARGS] = false;
	Game->FFRules[qr_BITMAP_AND_FILESYSTEM_PATHS_ALWAYS_RELATIVE] = true;
	int num_used_tilepage = 1+Div(get_lasttile(),TILES_PER_PAGE);
	int num_used_tilerow = num_used_tilepage*TILEROWS_PER_PAGE;
	bitmap tiles = create(TILES_PER_ROW*16,num_used_tilerow*16);
	for(int cset = 0; cset < CAPTURE_CSETS; ++cset)
	{
		tiles->Clear(0);
		for(int r = 0; r < num_used_tilerow; ++r)
		{
			for(int c = 0; c < 20; ++c)
			{
				drawcount_wait();
				tiles->FastTile(0, (c*16), r*16, r*TILES_PER_ROW+c, cset, OP_OPAQUE);
			}
		}
		char32 buf[32];
		sprintf(buf, "tiles_%02d.png", cset);
		tiles->Write(0, buf, true);
	}
	tiles->Free();
	Waitframe();
}

DEFINE COMBOS_HEIGHT = 13;
DEFINE COMBOS_NUMCOLS = 5;
DEFINE COMBOS_WID_PERCOL = 4;
DEFINE COMBOS_WIDTH = COMBOS_NUMCOLS*COMBOS_WID_PERCOL;
DEFINE COMBOS_PERCOL = COMBOS_HEIGHT*COMBOS_WID_PERCOL;
DEFINE COMBOS_PER_PAGE = 256;
DEFINE COMBO_PAGES = 255;
DEFINE COMBOS_MAX = COMBOS_PER_PAGE*COMBO_PAGES;

void captureCombos()
{
	Game->FFRules[qr_OLD_PRINTF_ARGS] = false;
	Game->FFRules[qr_BITMAP_AND_FILESYSTEM_PATHS_ALWAYS_RELATIVE] = true;
	int max_used_combo = COMBOS_MAX;
	for(int q = COMBOS_MAX - 1; q >= 0; --q)
	{
		combodata cd = Game->LoadComboData(q);
		if(cd->Tile)
		{
			max_used_combo = q;
			break;
		}
	}
	int num_used_combopage = 1+Div(max_used_combo,COMBOS_PER_PAGE);
	bitmap combos = create(COMBOS_WIDTH*16,(num_used_combopage*COMBOS_HEIGHT*16)+(num_used_combopage-1)*4);
	for(int cset = 0; cset < CAPTURE_CSETS; ++cset)
	{
		combos->Clear(0);
		for(int cmb = 0; cmb < max_used_combo; ++cmb)
		{
			unless(Game->LoadComboData(cmb)->Tile) continue;
			drawcount_wait();
			int cmb_in_page = cmb%COMBOS_PER_PAGE;
			int col = Div(cmb_in_page,COMBOS_PERCOL);
			int offs = cmb_in_page%COMBOS_WID_PERCOL;
			int row = Div(cmb_in_page%COMBOS_PERCOL,COMBOS_WID_PERCOL)+(Div(cmb,COMBOS_PER_PAGE)*COMBOS_HEIGHT);
			int voffs = Div(cmb,COMBOS_PER_PAGE)*4;
			combos->FastCombo(0, ((col*4)+offs)*16, row*16+voffs, cmb, cset, OP_OPAQUE);
		}
		for(int q = 1; q < num_used_combopage; ++q)
		{
			drawcount_wait();
			int y = (q*16*COMBOS_HEIGHT)+((q-1)*4);
			combos->Rectangle(0, 0, y, COMBOS_WIDTH*16-1, y+3, 0xEF, 1, 0, 0, 0, true, OP_OPAQUE);
		}
		char32 buf[32];
		sprintf(buf, "combos_%02d.png", cset);
		combos->Write(0, buf, true);
	}
	combos->Free();
	Waitframe();
}

global script capTiles
{
	void run()
	{
		captureTiles();
		captureCombos();
		Game->End();
	}
}
