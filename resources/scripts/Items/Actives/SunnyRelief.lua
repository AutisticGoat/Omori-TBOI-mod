local mod = OmoriMod
local enums = OmoriMod.Enums
local sound = enums.SoundEffect
local utils = enums.Utils
local sfx = utils.SFX
local items = enums.CollectibleType
local calmDown = items.COLLECTIBLE_CALM_DOWN
local overcome = items.COLLECTIBLE_OVERCOME

local function IsSunnyReliefItem(ID)
	return ID == calmDown or ID == overcome
end

---@param player EntityPlayer
---@return boolean|table?
function mod:ReliefSunny(ID, _, player)
	if not (ID == calmDown or ID == overcome) then return end
	if mod.GetEmotion(player) == "Neutral" then return {Discharge = false} end
	
	local isOvercome = ID == overcome
	local itemSound = isOvercome and sound.SOUND_OVERCOME or sound.SOUND_CALM_DOWN
	local hearts = isOvercome and 4 or 2

	OmoriMod:ResetSunnyEmotion(player, hearts, isOvercome)
	sfx:Play(itemSound)
	return true
end
mod:AddCallback(ModCallbacks.MC_USE_ITEM, mod.ReliefSunny)

---@param player EntityPlayer
function mod:OnTakingBirthright(_, _, _, _, _, player)
	if not mod.IsOmori(player, true) then return end
	if player:HasCollectible(overcome) then return end

	player:AddCollectible(overcome, 120, true, ActiveSlot.SLOT_POCKET)
end
mod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, mod.OnTakingBirthright, CollectibleType.COLLECTIBLE_BIRTHRIGHT)

---@param player EntityPlayer
---@param ID CollectibleType
function mod:OnLosingBirthright(player, ID)
	if not mod.IsOmori(player, true) then return end
	if not player:HasCollectible(overcome) then return end

	player:AddCollectible(calmDown, 180, true, ActiveSlot.SLOT_POCKET)
end
mod:AddCallback(ModCallbacks.MC_POST_TRIGGER_COLLECTIBLE_REMOVED, mod.OnLosingBirthright, CollectibleType.COLLECTIBLE_BIRTHRIGHT)
-- ---@param player EntityPlayer
-- function mod:ReplaceCalmDown(player)
-- 	if not OmoriMod.IsOmori(player, true) then return end
	
-- 	local hasBirthright = mod:HasBirthright(player)
-- 	local slot = ActiveSlot.SLOT_POCKET

-- 	if hasBirthright then
-- 		if player:HasCollectible(calmDown) then
-- 			player:RemoveCollectible(calmDown, false, slot)
-- 			player:AddCollectible(overcome, 2, true, slot)
-- 		end
-- 	elseif player:HasCollectible(overcome) then
-- 		player:RemoveCollectible(overcome, false, slot)
-- 		player:AddCollectible(calmDown, 2, true, slot)
-- 	end
-- end
-- mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.ReplaceCalmDown)