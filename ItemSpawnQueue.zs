@Author("EmilyV")
generic script ItemSpawnQueue
{
    genericdata gd;
    void run()
    {
        while(true)
        {
            while(this->DataSize)
            {
                int ind = this->DataSize-2;
                itemsprite itm = Screen->CreateItem(this->Data[ind]);
                itm->Pickup = this->Data[ind+1] | IP_ALWAYSGRAB;
                this->DataSize -= 2;
            }
            Waitframe();
        }
    }
    bool init()
    {
        if(gd) return true;
        if(int scr = CheckGenericScript("ItemSpawnQueue"))
        {
            gd = Game->LoadGenericData(scr);
            gd->Running = true;
            return true;
        }
        return false;
    }
    void add(int id, int pflags)
    {
        unless(init()) return;
        int ind = gd->DataSize;
        gd->DataSize += 2;
        gd->Data[ind] = id;
        gd->Data[ind+1] = pflags;
    }
}

