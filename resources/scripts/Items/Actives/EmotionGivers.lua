local mod = OmoriMod
local enums = mod.Enums
local items = enums.CollectibleType
local TableItems = {
    [items.COLLECTIBLE_SPARKLER] = {
        Default = "Happy",
        Tier2 = "Ecstatic",
        Tier3 = "Manic",
    },
    [items.COLLECTIBLE_POETRY_BOOK] = {
        Default = "Sad",
        Tier2 = "Depressed",
        Tier3 = "Miserable",
    },
    [items.COLLECTIBLE_PRESENT] = {
        Default = "Angry",
        Tier2 = "Enraged",
        Tier3 = "Furious",
    },
}

---@param id CollectibleType
---@param player EntityPlayer
function mod:OnEmotionGiverUse(id, _, player)
    local tableRef = mod.When(id, TableItems)
    if not tableRef then return end
    
    mod.EmotionUpdateItem(player, TableItems, tableRef.Default, tableRef.Tier2, tableRef.Tier3)
    return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.OnEmotionGiverUse)