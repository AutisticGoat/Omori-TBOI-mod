local mod = OmoriMod
local enums = mod.Enums
local items = enums.CollectibleType
local TableItems = {
    [items.COLLECTIBLE_CONFETTI] = {
        Default = "Happy",
    },
    [items.COLLECTIBLE_RAIN_CLOUD] = {
        Default = "Sad",
    },
    [items.COLLECTIBLE_AIR_HORN] = {
        Default = "Angry",
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