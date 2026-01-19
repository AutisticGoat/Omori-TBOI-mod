local mod = OmoriMod
local enums = mod.Enums
local tables = enums.Tables 
local emotionFrame = tables.EmotionChartFrame
local items = enums.CollectibleType
local EmotionChartSetFrame = {
	["Neutral"] = emotionFrame.Neutral,
	["Happy"] = emotionFrame.Happy,
	["Sad"] = emotionFrame.Sad,
	["Angry"] = emotionFrame.Angry,
	["Ecstatic"] = emotionFrame.Happy,
	["Depressed"] = emotionFrame.Sad,
	["Enraged"] = emotionFrame.Angry,
	["Manic"] = emotionFrame.Happy,
	["Miserable"] = emotionFrame.Sad,
	["Furious"] = emotionFrame.Angry,
}

local ChartSprite = Sprite('gfx/items/emotionChart.anm2', true)

HudHelper.RegisterHUDElement({
	ItemID = items.COLLECTIBLE_EMOTION_CHART,
	Condition = function(player)
		return OmoriMod.GetEmotion(player) ~= nil
	end,
	OnRender = function(player, _, _, position, _, scale)
		local emotion = OmoriMod.GetEmotion(player)
		local frame = OmoriMod.When(emotion, EmotionChartSetFrame, 0)
		local offset = scale == 1 and Vector(16, 16) or Vector(8,8)

		ChartSprite.Scale = Vector.One * scale
		ChartSprite:SetFrame("Idle", frame)
        ChartSprite:Render((position) + offset, Vector.Zero, Vector.Zero)
	end
}, HudHelper.HUDType.ACTIVE_ID)

---@param player EntityPlayer
---@return integer
mod:AddCallback(ModCallbacks.MC_PLAYER_GET_ACTIVE_MAX_CHARGE, function(_, _, player)
	return mod.IsOmori(player, false) and (player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 120 or 240) or 180
end, items.COLLECTIBLE_EMOTION_CHART)

local conditionMap = {
    [true] = {[true] = tables.EmotionUpgradesOmoriCarBattery, [false] = tables.EmotionUpgradesOmori},
    [false] = {[true] = tables.EmotionUpgradesCarBattery, [false] = tables.EmotionUpgrades}
}

---@param player EntityPlayer
---@param flags UseFlag
---@return table|boolean?
mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, _, _, player, flags)
	local CarBatteryUse = (flags == flags | UseFlag.USE_CARBATTERY)

	if CarBatteryUse then return end
	local HasCarBattery = player:HasCollectible(CollectibleType.COLLECTIBLE_CAR_BATTERY)
	local emotion = OmoriMod.GetEmotion(player)
	local IsMaxEmotionOrNeutral = mod.When(emotion, tables.NoDischargeEmotions, false)

	if IsMaxEmotionOrNeutral == true then return {Discharge = false} end

	local tableRef = conditionMap[OmoriMod.IsOmori(player, false)][HasCarBattery]
	local EmotionToChange = mod.When(emotion, tableRef, "Neutral")

	OmoriMod.SetEmotion(player, EmotionToChange)
	OmoriMod:ChangeEmotionEffect(player, true)

	return true
end, items.COLLECTIBLE_EMOTION_CHART)

---@param player EntityPlayer
mod:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, function(_, _, _, _, _, _, player)
	if OmoriMod.IsAnyOmori(player) then return end 
	if OmoriMod.GetEmotion(player) then return end
	OmoriMod.SetEmotion(player, enums.Emotions.HAPPY)
end, items.COLLECTIBLE_EMOTION_CHART)
