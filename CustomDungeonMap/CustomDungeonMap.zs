#include "std.zh"

// HOW TO SETUP?
// Edit the constants in the 'namespace CustomMap //Constants' below for settings
// Edit 'generate_map' in 'namespace CustomMap //Script' below to create your maps

namespace CustomMap //Constants
{
    //// These constants are for the user to configure

    // Tiles / Graphics
    CONFIG TILE_RM_OFFMAP = 520; //The background for rooms not part of the map
    CONFIG TILE_RM_UNEXPLORED = 521; //The background for an unexplored room
    CONFIG TILE_RM_EXPLORED = 522; //The background for an explored room
    CONFIG TILE_RM_CURRENT = 523; //The background for the current room

    CONFIG TILE_WALL_OUTLINE = 540; //Outline of walls
    CONFIG TILE_WALL_DIRS = 560; //First of 4 directional wall tiles
    CONFIG TILE_LOCKDOOR_DIRS = 580; //First of 4 directional locked door tiles
    CONFIG TILE_BOSSDOOR_DIRS = 600; //First of 4 directional boss door tiles
    CONFIG TILE_ONEWAY_DIRS = 620; //First of 4 directional 1-way door tiles

    CONFIG TILE_CHEST_OVERLAY = 640; //First chest overlay tile
    CONFIGB MULTI_CHEST_TILE = true; //If true, adds the number of extra chests on the screen to the overlay

    CONFIG TILE_BOSS_OVERLAY = 660; // Icon for boss rooms
    CONFIG TILE_BOSS_DEAD_OVERLAY = 661; // Icon for dead boss rooms

    CONFIG TILE_ICON_STAIRDOWN = 760;
    CONFIG TILE_ICON_STAIRUP = 761;

    CONFIG TILE_2X2_FRAME = 680; // 2x2 Frame for borders
    CONFIG TILE_FLOOR_TEXTBOX = 720; // Left of textbox for floors
    CONFIG TILE_FLOOR_SEL_TEXTBOX = 740; // Left of textbox for floors
    CONFIG FONT_FLOORTEXT = FONT_Z1;
    CONFIG C_FLOORTEXT = 0x01;
    CONFIG C_FLOORSHADOW = 0x02;
    CONFIG SHD_FLOOR = SHD_SHADOWED;

    CONFIG C_BACKGROUND = 0x0F; //Background color
    
    // Positioning
    CONFIG ROOM_SZ = 16;
    CONFIG MAP_SZ = 8*ROOM_SZ;
    CONFIG FLOORBTN_TILEWID = 2;
    CONFIG FLOORBTN_PADDING = 8;

    // SFX
    CONFIG SFX_FLOORSWAP = 0; // Cursor moves between floors

    // Doors/Logic
    CONFIGB USE_NES_DOORS = true; //If true, will use nes doors
    CONFIGB USE_EXSTATE_DOORS = true; //If true, will use these exstates to represent locked doors
    CONFIGB AUTODETECT_OPENINGS = true; //If true, will use solidity to autodetect open directions
    CONFIGB AUTODETECT_BOSSROOM = true; //If true, will use the 'Dungeon Boss' screenflag to mark boss rooms
    //The 4 ExStates used by lockblocks/bosslockblocks to simulate doors
    CONFIG EX_UPDOOR = 0;
    CONFIG EX_DOWNDOOR = 1;
    CONFIG EX_LEFTDOOR = 2;
    CONFIG EX_RIGHTDOOR = 3;
    
    CONFIGB REQ_COMPASS_FOR_CHESTS = true;
    CONFIGB REQ_COMPASS_FOR_BOSS = true;
    CONFIGB REQ_COMPASS_FOR_ICONS = false;
    CONFIGB REQ_MAP_FOR_CHESTS = false;
    CONFIGB REQ_MAP_FOR_BOSS = false;
    CONFIGB REQ_MAP_FOR_ICONS = true;
    CONFIGB REQ_MAP_FOR_UNEXPLORED = true;
    CONFIGB REQ_MAP_FOR_OPEN = false;
    CONFIGB DISPLAY_LITEMS = true;

    //// These values are used by the script
    CONFIGB DEBUG = false;
    DEFINE FLOORPANEL_WID = 16*FLOORBTN_TILEWID + FLOORBTN_PADDING*2;
    CONFIG WINDOW_X = (256-WINDOW_WID)/2, WINDOW_Y = (224-WINDOW_HEI)/2;
    DEFINE MAP_X = WINDOW_X+FLOORPANEL_WID+24, MAP_Y = WINDOW_Y+8;
    DEFINE FLOORPANEL_X = WINDOW_X+8, FLOORPANEL_Y = WINDOW_Y+8;
    DEFINE WINDOW_WID = FLOORPANEL_WID+MAP_SZ+32;
    DEFINE WINDOW_HEI = MAP_SZ+16;
    DEFINE MAP_ENDX = MAP_X + MAP_SZ, MAP_ENDY = MAP_Y + MAP_SZ;
    DEFINE FLOORSIZE = 8*8;

    DEFINE LI_REQCHEST = (REQ_COMPASS_FOR_CHESTS?LI_COMPASS:0)|(REQ_MAP_FOR_CHESTS?LI_MAP:0);
    DEFINE LI_REQBOSS = (REQ_COMPASS_FOR_BOSS?LI_COMPASS:0)|(REQ_MAP_FOR_BOSS?LI_MAP:0);
    DEFINE LI_REQICON = (REQ_COMPASS_FOR_ICONS?LI_COMPASS:0)|(REQ_MAP_FOR_ICONS?LI_MAP:0);
    DEFINE LI_REQUNEXPL = (REQ_MAP_FOR_UNEXPLORED?LI_MAP:0);
    DEFINE LI_REQOPEN = (REQ_MAP_FOR_OPEN?LI_MAP:0);
    enum DoorState
    {
        DST_WALL,
        DST_OPEN,
        DST_LOCK,
        DST_BOSSLOCK,
        DST_ONEWAY,
        DST_MAX
    };
}

namespace CustomMap //Classes
{
    class Room
    {
        mapdata scr;
        int chests[0];
        DoorState doors[4];
        int icon;
        bool bossroom;

        //construct a blank room
        Room(mapdata basescr)
        {
            scr = basescr;
            icon = -1;
            autoSetup();
        }
        //// SETUP FUNCTIONS
        void autoSetup()
        {
            if(AUTODETECT_BOSSROOM)
                bossroom = ScreenEFlag(scr,SEF_LIST1,SEFL1_BOSS) != 0;
            autoDoors();
        }
        // Automatically determine doorstates
        // These directions will be set to 'Open', unless locks are detected
        // If locks are detected, the door will indicate the lock state.
        void autoDoors()
        {
            const int exsts[] = {EX_UPDOOR,EX_DOWNDOOR,EX_LEFTDOOR,EX_RIGHTDOOR};
            mapdata lyrs[1] = {scr}; //Get all the layers
            for(int q = 1; q < 7; ++q)
                if(scr->LayerMap[q] > 0)
                    ArrayPushBack(lyrs,Game->LoadMapData(scr->LayerMap[q],scr->LayerScreen[q]));
            if(AUTODETECT_OPENINGS)
            {
                setDoors(DST_WALL,DST_WALL,DST_WALL,DST_WALL);
                int x1 = 0, x2 = 255, y1 = 0, y2 = 175;
                for(int x = x1; x <= x2; ++x)
                    unless(scr->isSolid(x,y1))
                    {
                        doors[DIR_UP] = DST_OPEN;
                    }
                for(int x = x1; x <= x2; ++x)
                    unless(scr->isSolid(x,y2))
                    {
                        doors[DIR_DOWN] = DST_OPEN;
                    }
                for(int y = y1; y <= y2; ++y)
                    unless(scr->isSolid(x1,y))
                    {
                        doors[DIR_LEFT] = DST_OPEN;
                    }
                for(int y = y1; y <= y2; ++y)
                    unless(scr->isSolid(x2,y))
                    {
                        doors[DIR_RIGHT] = DST_OPEN;
                    }
            }
            for(int dir = 0; dir < 4; ++dir)
            {
                if((USE_NES_DOORS && scr->State[ST_DOORUP+dir])
                    || (USE_EXSTATE_DOORS && scr->ExState[exsts[dir]]))
                { //It's already been unlocked!
                    doors[dir] = DST_OPEN;
                    continue;
                }
                //check for locks
                if(USE_EXSTATE_DOORS)
                {
                    for(l : lyrs) //For each layer, look for lockblocks
                    {
                        unless(l->Valid) continue; //skip empty layers
                        for(int pos = 0; pos < 176; ++pos)
                        {
                            combodata cd = Game->LoadComboData(l->ComboD[pos]);
                            switch(cd->Type)
                            {
                                case CT_LOCKBLOCK:
                                    unless(cd->Flags[15] && cd->Attribytes[5] == exsts[dir])
                                        continue;
                                    doors[dir] = DST_LOCK;
                                    continue 3;
                                case CT_BOSSLOCKBLOCK:
                                    unless(cd->Flags[15] && cd->Attribytes[5] == exsts[dir])
                                        continue;
                                    doors[dir] = DST_BOSSLOCK;
                                    continue 3;
                            }
                        }
                    }
                }
                if(USE_NES_DOORS)
                {
                    switch(scr->Door[dir])
                    {
                        case D_WALL:
                        case D_BOMB:
                        case D_SHUTTER:
                        case D_WALKTHRU:
                            break;
                        case D_OPEN:
                        case D_UNLOCKED:
                        case D_BOMBED:
                        case D_BOSSUNLOCKED:
                        case D_OPENSHUTTER:
                            doors[dir] = DST_OPEN;
                            break;
                        case D_LOCKED:
                            doors[dir] = DST_LOCK;
                            break;
                        case D_BOSSLOCKED:
                            doors[dir] = DST_BOSSLOCK;
                            break;
                        case D_1WAYSHUTTER:
                            doors[dir] = DST_ONEWAY;
                            break;
                    }
                }
            }
        }
        // Set the 4 door states for the room
        void setDoors(DoorState up, DoorState down, DoorState left, DoorState right)
        {
            doors[DIR_UP] = up;
            doors[DIR_DOWN] = down;
            doors[DIR_LEFT] = left;
            doors[DIR_RIGHT] = right;
        }
        // Hides these directions until the 'Screen->State[ST_DOOR*]' is set for the dir
        void hideDoors(...int[] dirs)
        {
            for(dir : dirs)
                unless(scr->State[ST_DOORUP+dir])
                    doors[dir] = DST_WALL;
        }
        // Set the array of chests for the room
        // Use '-1' for 'normal chest', '-2' for 'locked chest',
        //     '-3' for 'boss chest', or >= 0 for an ExState
        void setChests(...int[] chest_exstates)
        {
            DEFINE MINCHEST = -3;
            DEFINE MAXCHEST = 32;
            bool maxchests[MAXCHEST-MINCHEST];
            int count = 0;
            for(ex : chest_exstates)
            {
                if(ex < MINCHEST || ex >= MAXCHEST)
                    continue;
                ex -= MINCHEST; //offset
                if(maxchests[ex])
                    continue; //duplicate
                maxchests[ex] = true;
                ++count;
            }
            ResizeArray(chests,count);
            int ind = 0;
            for(int q = MINCHEST; q < MAXCHEST; ++q)
            {
                if(maxchests[q-MINCHEST])
                    chests[ind++] = q;
            }
        }
        // Adds an icon to the room
        void setIcon(int newicon)
        {
            icon = newicon;
        }
        // Sets the room's boss status
        void setBoss(bool boss)
        {
            bossroom = boss;
        }

        //// USING FUNCTIONS
        // Count how many chests are still unclaimed in the room
        int countChests()
        {
            int count = 0;
            for(ex : chests)
                unless(checkChest(ex))
                    ++count;
            return count;
        }
        // Checks a single chest position in the room
        bool checkChest(int ex)
        {
            switch(ex)
            {
                case -3:
                    return scr->State[ST_BOSSCHEST];
                case -2:
                    return scr->State[ST_LOCKEDCHEST];
                case -1:
                    return scr->State[ST_CHEST];
                case 0...31:
                    return scr->ExState[ex];
            }
            return false;
        }
        // Draw the room to a bitmap
        void Draw(bitmap b, int layer, int x, int y, dmapdata dm)
        {
            // Draw tile based on visited state
            int li = Game->LItems[dm->Level];
            int tile = TILE_RM_OFFMAP;
            bool onmap = true;
            if(scr->Map == Game->CurMap && scr->Screen == Game->CurScreen)
                tile = TILE_RM_CURRENT;
            else if(dm->Charted[scr->Screen] & CHRT_VISITED)
                tile = TILE_RM_EXPLORED;
            else if((li & LI_REQUNEXPL) == LI_REQUNEXPL || !LI_REQUNEXPL)
                tile = TILE_RM_UNEXPLORED;
            else onmap = false;
            b->FastTile(layer,x,y,tile,0);

            // Draw the walls/doors
            if(onmap)
            {
                b->FastTile(layer,x,y,TILE_WALL_OUTLINE,0);
                for(int dir = 0; dir < 4; ++dir)
                {
                    tile = -1;
                    switch(doors[dir])
                    {
                        case DST_WALL:
                            tile = TILE_WALL_DIRS+dir;
                            break;
                        case DST_LOCK:
                            tile = TILE_LOCKDOOR_DIRS+dir;
                            break;
                        case DST_BOSSLOCK:
                            tile = TILE_BOSSDOOR_DIRS+dir;
                            break;
                        case DST_ONEWAY:
                            tile = TILE_ONEWAY_DIRS+dir;
                            break;
                    }
                    if(tile > -1)
                        b->FastTile(layer,x,y,tile,0);
                }
            }

            tile = -1;
            int chestCount = 0;
            if((li & LI_REQCHEST) == LI_REQCHEST || !LI_REQCHEST)
                chestCount = countChests();
            if(chestCount > 0) // Draw the chests
            {
                tile = TILE_CHEST_OVERLAY;
                if(MULTI_CHEST_TILE)
                    tile += chestCount-1;
            }
            else if((li & LI_REQICON) == LI_REQICON || !LI_REQICON)
            {
                if((li & LI_REQBOSS) == LI_REQBOSS || !LI_REQBOSS)
                {
                    bool bossDead = li&LI_BOSS;
                    if(bossroom && !bossDead)
                        tile = TILE_BOSS_OVERLAY;
                    else if(icon > -1) //Draw the custom icon
                        tile = icon;
                    else if(bossroom && bossDead)
                        tile = TILE_BOSS_DEAD_OVERLAY;
                }
                else if(icon > -1) //Draw the custom icon
                    tile = icon;
            }
            else if((li & LI_REQBOSS) == LI_REQBOSS || !LI_REQBOSS)
            {
                if(bossroom)
                    tile = (li&LI_BOSS) ? TILE_BOSS_DEAD_OVERLAY : TILE_BOSS_OVERLAY;
            }
            if(tile > -1)
                b->FastTile(layer,x,y,tile,0);
        }
        // Draw a "missing" room to a bitmap
        static void DrawNull(bitmap b, int layer, int x, int y)
        {
            b->FastTile(layer,x,y,TILE_RM_OFFMAP,0);
        }
    }
    class CMap
    {
        Room rooms[0];
        int minfloor, maxfloor;
        int curfloor;
        dmapdata floor_dmaps[0];

        // 'floors' is the total number of floors to store.
        // 'bfloors' indicates how many of those should be labelled as 'basement floors'
        CMap(int bfloors, ...int[] floorsarr)
        {
            int floors = SizeOfArray(floorsarr);
            if(floors > 0)
            {
                ResizeArray(rooms,floors*FLOORSIZE);
                ResizeArray(floor_dmaps,floors);
                
                int ind = 0;
                for(dm : floorsarr)
                    floor_dmaps[ind++] = Game->LoadDMapData(dm);
                
                if(bfloors > 0)
                {
                    minfloor = -bfloors;
                    maxfloor = floors-bfloors-1;
                }
                else maxfloor = floors-1;
            }
            else if(DEBUG)
                TraceS("ERROR: Must have at least 1 floor per map!\n");
        }
        // 'floor' should be a number between minfloor and maxfloor
        // 'scr' should be the screen number relative to the dmap (so 0x00 is the top left of the dmap)
        // only 8x8 dmaps are supported
        Room addRoom(int floor, int scr)
        {
            if(floor < minfloor || floor > maxfloor //invalid floor
                || scr < 0 || scr >= 0x80 || (scr&0x08)) //invalid screen
                return NULL;
            int ind = ((scr%8)+8*Floor(scr/16)) + ((floor-minfloor)*FLOORSIZE);
            dmapdata dmd = floor_dmaps[floor-minfloor];
            mapdata md = Game->LoadMapData(dmd->Map,scr+dmd->Offset);
            unless(rooms[ind]) // Only remake if doesn't exist!
                rooms[ind] = new Room(md);
            return rooms[ind];
        }

        // Moves the current floor, within bounds
        bool MoveFloor(int inc)
        {
            int of = curfloor;
            curfloor = Clamp(of+inc,minfloor,maxfloor);
            return curfloor != of;
        }
        bool SetFloor(int newfloor)
        {
            int of = curfloor;
            curfloor = Clamp(newfloor,minfloor,maxfloor);
            return curfloor != of;
        }
        // Draws the map, either to a bitmap or the screen
        void DrawMap(untyped bit, int layer)
        {
            bitmap b = Game->CreateBitmap(256,256);
            b->ClearToColor(0,C_BACKGROUND);

            b->DrawFrame(0,WINDOW_X,WINDOW_Y,TILE_2X2_FRAME,0,WINDOW_WID/8,WINDOW_HEI/8);
            b->DrawFrame(0,FLOORPANEL_X-8,FLOORPANEL_Y-8,TILE_2X2_FRAME,0,FLOORPANEL_WID/8+2,WINDOW_HEI/8);
            b->DrawFrame(0,MAP_X-8,MAP_Y-8,TILE_2X2_FRAME,0,MAP_SZ/8+2,MAP_SZ/8+2);

            int numfloors = maxfloor-minfloor+1;
            int topfloor = maxfloor;
            DEFINE MAXFLOORCOUNT = (8*ROOM_SZ/16);
            if(numfloors > MAXFLOORCOUNT) //Limit visible floors
            {
                numfloors = MAXFLOORCOUNT;
                topfloor = curfloor+MAXFLOORCOUNT/2;
                if(topfloor > maxfloor)
                    topfloor = maxfloor;
            }
            int floory = FLOORPANEL_Y+(MAXFLOORCOUNT-numfloors)*8;
            DEFINE FLOORCENTERX = FLOORPANEL_X+FLOORBTN_PADDING+(FLOORBTN_TILEWID*8);
            DEFINE FLOOR_TXTY = (16-Text->FontHeight(FONT_FLOORTEXT))/2;
            for(int q = 0; q < numfloors; ++q)
            {
                int f = topfloor-q;
                b->DrawTile(0,FLOORPANEL_X+FLOORBTN_PADDING,floory,f==curfloor?TILE_FLOOR_SEL_TEXTBOX:TILE_FLOOR_TEXTBOX,FLOORBTN_TILEWID,1,0);
                char32 buf[16];
                if(f < 0)
                    sprintf(buf,"B%i",-f);
                else sprintf(buf,"%i",f+1);
                b->DrawString(0,FLOORCENTERX,floory+FLOOR_TXTY,FONT_FLOORTEXT,C_FLOORTEXT,-1,TF_CENTERED,
                    buf,OP_OPAQUE,SHD_FLOOR,C_FLOORSHADOW);
                floory += 16;
            }

            if(DISPLAY_LITEMS)
            {
                int items[] = {I_MAP,I_COMPASS,I_BOSSKEY};
                int li = Game->LItems[floor_dmaps[curfloor-minfloor]->Level];
                bool states[] = {li&LI_MAP,li&LI_COMPASS,li&LI_BOSSKEY};
                DEFINE LITEM_Y = WINDOW_Y+WINDOW_HEI+4;
                int x = MAP_X;
                for(int q = 0; q < 3; ++q)
                {
                    if(states[q])
                        b->FastTile(0,x,LITEM_Y,Emily::item_tile(items[q]),Emily::item_cset(items[q]));
                    x += 16;
                }
            }

            int ind = (curfloor-minfloor)*FLOORSIZE;
            for(int y = MAP_Y; y < MAP_ENDY; y += ROOM_SZ)
                for(int x = MAP_X; x < MAP_ENDX; x += ROOM_SZ)
                {
                    Room r = rooms[ind++];
                    if(r) r->Draw(b,0,x,y,floor_dmaps[curfloor-minfloor]);
                    else Room::DrawNull(b,0,x,y);
                }

            int dy = bit==RT_SCREEN ? -56 : 0;
            b->Blit(layer, bit, 0, 0, 256, 224, 0, dy, 256, 224);
            b->Free();
        }
    }
}

namespace CustomMap //Script
{
    CMap generate_map(int mapid)
    {
        //Quick reference instructions:
        //What's automatic?
        // IF AUTODETECT_BOSSROOM: Rooms marked 'Dungeon Boss' in Screen Data are bossrooms
        // IF AUTODETECT_OPENINGS: Solidity will be used to mark default open paths
        // IF USE_NES_DOORS: NES Dungeon Doors are autodetected
        // IF USE_EXSTATE_DOORS: Lockblocks using the ExStates set for 'EX_UPDOOR' etc
        //     will be autodetected as doors
        //What's manual?
        // m = new CMap(numBasementFloors, bottomFloorDMap, nextFloorDmap, ...); //keep adding dmaps as many as you have
        // r = m->addRoom(floorNumber,dmapScreenNumber);
        // r->setChests(...); //add chests, use 0-31 for exstates, -1 for chest, -2 for lockchest, -3 for bosschest
        // r->setIcon(TILE_SOME_CONSTANT); //Add a custom icon tile to a room
        CMap m;
        switch(mapid)
        {
            case 0: //An example of a map
            {
                Room r; //dummy room pointer to reuse
                m = new CMap(0, 1); //Create a 1-floor map (floor 0)
                //(0 basement floors) (L1 = dmap 1)
                r = m->addRoom(0,0x31);
                r->setChests(-1); //Adds a chest using the 'Chest' state
                r = m->addRoom(0,0x33);
                r = m->addRoom(0,0x34);
                r = m->addRoom(0,0x36);
                r = m->addRoom(0,0x41);
                r = m->addRoom(0,0x42);
                r->setChests(4); //Adds a chest using the 'ExState 4' state
                r = m->addRoom(0,0x43);
                r->setChests(-1, 4); //Adds 2 chests using the 'Chest' and 'ExState 4' states
                r = m->addRoom(0,0x44);
                r = m->addRoom(0,0x45);
                r = m->addRoom(0,0x46);
                r = m->addRoom(0,0x51);
                r = m->addRoom(0,0x52);
                r = m->addRoom(0,0x53);
                r = m->addRoom(0,0x54);
                r = m->addRoom(0,0x55);
                r = m->addRoom(0,0x56);
                r->setChests(-1);
                break;
            }
            case 1: //An example of a map
            {
                Room r; //dummy room pointer to reuse
                m = new CMap(1, 2, 3); //Create a 2-floor map (floor -1, 0)
                //(1 basement floor) (B1 = dmap 2, L1 = dmap 3)
                r = m->addRoom(-1,0x22);
                r = m->addRoom(-1,0x23);
                r->setChests(-1);
                r = m->addRoom(-1,0x24);
                r->setChests(-1);
                r = m->addRoom(-1,0x25);
                r = m->addRoom(-1,0x32);
                r = m->addRoom(-1,0x33);
                r = m->addRoom(-1,0x34);
                r->setIcon(TILE_ICON_STAIRUP);
                r = m->addRoom(-1,0x35);
                r = m->addRoom(-1,0x42);
                r = m->addRoom(-1,0x43);
                r = m->addRoom(-1,0x44);
                r->setChests(-1);
                r = m->addRoom(-1,0x45);
                r = m->addRoom(-1,0x52);
                r = m->addRoom(-1,0x53);
                r = m->addRoom(-1,0x54);
                r = m->addRoom(-1,0x55);
                r = m->addRoom(0,0x33);
                r = m->addRoom(0,0x34);
                r->setIcon(TILE_ICON_STAIRDOWN);
                r = m->addRoom(0,0x43);
                r = m->addRoom(0,0x44);
                break;
            }
        }
        if(m && !SizeOfArray(m->rooms)) //prevent returning pointers to 0-floor maps
        {
            delete m;
            m = NULL;
        }
        return m;
    }
    @Author("EmilyV"),
    @InitD0("WhichMap"), @InitDHelp0("Which map ID from 'generate_map()' to use for this dungeon"),
    @InitD1("ThisFloor"), @InitDHelp1("Which floor (0 = L1, -1 = B1) this dmap is on the map.")
    dmapdata script CustomDungeonMap
    {
        void run(int whichMap, int whichFloor)
        {
            if(LI_REQOPEN && (Game->LItems[Game->CurLevel] & LI_REQOPEN) != LI_REQOPEN)
                return;
            CMap m = generate_map(whichMap);
            unless(m) return; //error; no map found
            m->SetFloor(whichFloor);
            until(Hero->PressMap)
            {
                bool b = false;
                if(Hero->PressUp)
                    b = m->MoveFloor(1);
                else if(Hero->PressDown)
                    b = m->MoveFloor(-1);
                if(b && SFX_FLOORSWAP)
                    Audio->PlaySound(SFX_FLOORSWAP);
                m->DrawMap(RT_SCREEN, 7);
                Waitframe();
            }
        }
    }
}

