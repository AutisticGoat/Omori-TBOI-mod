local mod = OmoriMod
local enums = OmoriMod.Enums
local game = enums.Utils.Game
local tables = enums.Tables
local misc = enums.Misc

local funcs = {
	GetEmotion = mod.GetEmotion,
	SetEmotion = mod.SetEmotion,
	IsOmori = mod.IsOmori,
	GetData = mod.GetData,
	TriggerEmoChange = mod.IsEmotionChangeTriggered,
	Switch = mod.When,
}

local EmotionTitle = Sprite("gfx/EmotionTitle.anm2", true)

HudHelper.RegisterHUDElement({
	Name = "Emotion Title",
	Priority = HudHelper.Priority.EID,
	XPadding = 0,
	YPadding = 0,
	Condition = function(player)
		return funcs.GetEmotion(player) ~= nil
	end,
	OnRender = function(player)
		if RoomTransition:GetTransitionMode() == 3 then return end

		local emotion = funcs.GetEmotion(player)
		EmotionTitle:Play(emotion, true)
        EmotionTitle:Render(Isaac.WorldToScreen(player.Position + misc.EmotionTitleOffset), Vector.Zero, Vector.Zero)
	end,
	PreRenderCallback = true,
}, HudHelper.HUDType.EXTRA)

function mod:ChangeEmotionLogic(player)
	if not funcs.IsOmori(player, false) then return end
	local emotion = funcs.GetEmotion(player)

	if not OmoriMod:IsEmotionChangeTriggered(player) then return end
	local newEmotion = funcs.Switch(emotion, tables.EmotionToChange, "Neutral")

	funcs.SetEmotion(player, newEmotion)
	OmoriMod:ChangeEmotionEffect(player, true)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.ChangeEmotionLogic)


local EmotionColorChange = {
	["Happy"] = misc.HappyColorMod,
	["Sad"] = misc.SadColorMod,
	["Angry"] = misc.AngryColorMod,
	["Ecstatic"] = misc.HappyColorMod,
	["Depressed"] = misc.SadColorMod,
	["Enraged"] = misc.AngryColorMod,
	["Manic"] = misc.HappyColorMod,
	["Miserable"] = misc.SadColorMod,
	["Furious"] = misc.AngryColorMod,
}

---@param player EntityPlayer
---@param emotion string
function mod:OnEmotionChange(player, emotion)
	print(emotion)
	local ColorMod = funcs.Switch(emotion, EmotionColorChange)

	if not ColorMod then return end

    game:SetColorModifier(ColorMod, true, 0.3)

    Isaac.CreateTimer(function ()
        game:GetRoom():UpdateColorModifier(true, true, 0.15)
    end, 5, 1, false)
end
mod:AddCallback(enums.Callbacks.EMOTION_CHANGE_TRIGGER, mod.OnEmotionChange)

function mod:OmoriOnNewLevel()
	local players = PlayerManager.GetPlayers()
	for _, player in ipairs(players) do
		if funcs.GetEmotion(player) == nil then return end
		OmoriMod:ChangeEmotionEffect(player, false)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.OmoriOnNewLevel)