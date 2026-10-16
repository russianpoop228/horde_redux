function HORDE:IsPurismMode()
    if HORDE.purism_mode == true then return true end
    local name = HORDE.difficulty_text and HORDE.difficulty_text[HORDE.difficulty]
    return name == "PURISM"
end

function HORDE:IsPassiveGadgetClass(class)
    local def = HORDE.gadgets and HORDE.gadgets[class]
    return not (def and def.Active == true)
end

function HORDE:IsPurismBlockedShopItem(item)
    if not HORDE:IsPurismMode() or not item then return false end
    local is_gadget = (item.category == "Gadget")
        or (item.entity_properties ~= nil and item.entity_properties.type == HORDE.ENTITY_PROPERTY_GADGET)
    return is_gadget and HORDE:IsPassiveGadgetClass(item.class)
end
