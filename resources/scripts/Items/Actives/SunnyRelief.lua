local mod = OmoriMod
local enums = OmoriMod.Enums
local sound = enums.SoundEffect
local utils = enums.Utils
local sfx = utils.SFX
local items = enums.CollectibleType
local calmDown = items.COLLECTIBLE_CALM_DOWN
local overcome = items.COLLECTIBLE_OVERCOME

---@param player EntityPlayer
---@return boolean|table?
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function (_, ID, _, player)
	if not (ID == calmDown or ID == overcome) then return end
	if mod.GetEmotion(player) == "Neutral" then return {Discharge = false} end
	
	local isOvercome = ID == overcome
	local itemSound = isOvercome and sound.SOUND_OVERCOME or sound.SOUND_CALM_DOWN
	local hearts = isOvercome and 4 or 2

	OmoriMod:ResetSunnyEmotion(player, hearts, isOvercome)
	sfx:Play(itemSound)
	return true
end)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, function (_, _, _, _, _, _, player)
	if not mod.IsOmori(player, true) then return end
	if player:HasCollectible(overcome) then return end

	player:AddCollectible(overcome, 120, true, ActiveSlot.SLOT_POCKET)
end, CollectibleType.COLLECTIBLE_BIRTHRIGHT)

---@param player EntityPlayer
---@param ID CollectibleType
mod:AddCallback(ModCallbacks.MC_POST_TRIGGER_COLLECTIBLE_REMOVED, function(_, player, ID)
	if not mod.IsOmori(player, true) then return end
	if not player:HasCollectible(overcome) then return end

	player:AddCollectible(calmDown, 180, true, ActiveSlot.SLOT_POCKET)
end, CollectibleType.COLLECTIBLE_BIRTHRIGHT)