-- local mod = OmoriMod
-- local enums = mod.Enums
-- local items = enums.CollectibleType

-- local TableItems = {
--     [items.COLLECTIBLE_CONFETTI] = "Happy",
--     [items.COLLECTIBLE_RAIN_CLOUD] = "Sad",
--     [items.COLLECTIBLE_AIR_HORN] = "Angry",
-- }

-- ---@param id CollectibleType
-- ---@param player EntityPlayer
-- function mod:OnEmotionGiverUse(id, _, player)
--     local tableRef = mod.When(id, TableItems)
--     if not tableRef then return end

--     for _, enemy in ipairs(Isaac.GetRoomEntities()) do
--         if not mod:IsEnemy(enemy) then goto continue end
        
--         ::continue::
--     end

--     return true
-- end
-- mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.OnEmotionGiverUse)