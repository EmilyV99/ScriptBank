#include "std.zh"

/** INSTRUCTIONS
 * Assign to a slot. In 'Init Data->GenScript' for this script...
 *     - Check 'Run from Start'
 *     - If you want it to run on every *DMAP* change INSTEAD
 *       of every *LEVEL* change, then under 'Events' check 'Change DMap'.
 *     - Set the 'InitD' for 'Fade Seconds'
 * The highest-numbered widget on the entire 'Overlay Subscreen' will
 *     appear for a short time on entering a new dmap/level.
 */
@Author("EmilyV"),
@InitD0("Fade Seconds"), @InitDHelp0("Time for widget to fade, in seconds.")
generic script DMapFadeOverlay
{
	void run(int fadeTime)
	{
		fadeTime *= 60; //convert to frames from seconds
		if(fadeTime < 1) fadeTime = 60*4;
		bool dm = this->EventListen[GENSCR_EVENT_CHANGE_DMAP];
		int dml = (dm ? Game->CurDMap : Game->CurLevel);
		while(true)
		{
			while(dml == (dm ? Game->CurDMap : Game->CurLevel))
				Waitframe();
			dml = (dm ? Game->CurDMap : Game->CurLevel);
			subscreenwidget widg = get_fadewidg();
			unless(widg) continue;
			widg->VisibleFlags[SUBVISIB_OPEN] = false;
			widg->VisibleFlags[SUBVISIB_SCROLLING] = false;
			widg->VisibleFlags[SUBVISIB_CLOSED] = true;
			for(int q = fadeTime; dml == (dm ? Game->CurDMap : Game->CurLevel)
				&& q > 0; --q)
				Waitframe();
			widg->VisibleFlags[SUBVISIB_CLOSED] = false;
		}
	}
	//Picks which widget to fade
	subscreenwidget get_fadewidg()
	{
		int osub = Game->LoadDMapData(Game->CurDMap)->OverlaySubscreen;
		if(osub >= Game->NumOverlaySubscreens)
			return NULL;
		subscreendata sd = Game->LoadOSubData(osub);
		subscreenpage pg = sd->Pages[0];
		unless(pg->NumWidgets) return NULL;
		return pg->Widgets[pg->NumWidgets-1]; //highest index
	}
}
