/** INSTRUCTIONS:
 * Set this on the subscreen 'ItemSlot' as the 'Selection' script,
 *     with 'Non-Equippable' and 'No Interact Without Item' checked.
 * Set the InitD[] as the help text instructs.
 * The ItemSlot widget should also have an Item Override that matches the provided item ID.
 */

@Author("EmilyV"),
@InitD0("Item Class"), @InitDHelp0("The itemclass to equip for"),
@InitD1("Item ID"), @InitDHelp1("The item ID to equip of the itemclass. Should match the 'Item Override:' field."),
@InitD2("Unequipable?"), @InitDHelp2("If the itemclass can be unequipped altogether")
generic script ItemEquipper
{
    void run(int itemclass, int itemid, bool allowUnequip)
    {
        itemdata id = Game->LoadItemData(itemid);
        if(id->Family != itemclass)
        {
            printf("ERROR: The provided item ID must be of the correct itemclass!\n");
            return;
        }
        if(allowUnequip && Game->OverrideItems[itemclass] == itemid)
            Game->OverrideItems[itemclass] = -1;
        else Game->OverrideItems[itemclass] = itemid;
    }
}

