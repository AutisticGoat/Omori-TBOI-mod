local mod = OmoriMod
local enums = mod.Enums
local utils = enums.Utils
local tables = enums.Tables
local game = utils.Game
local modrng = utils.RNG
local misc = enums.Misc

local DBFlag = false

local funcs = {
	GetEmotion = mod.GetEmotion,
	Switch = mod.When,
	PlayerFromTear = mod.GetPlayerFromAttack,
	IsOmori = mod.IsOmori,
	ceil = math.ceil,
	RandomNumber = mod.randomNumber
}

function mod:dp_onStart()
	DBFlag = false
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.dp_onStart)

---@param player EntityPlayer
---@param damage integer
---@param flags integer
---@param source EntityRef
---@param cooldown integer
function mod:EmotionDamageManager(player, damage, flags, source, cooldown)
	local emotion = funcs.GetEmotion(player)
	local SadIgnore = funcs.Switch(emotion, tables.SadnessIgnoreDamageChance, nil)
	local AngerDouble = funcs.Switch(emotion, tables.AngerDoubleDamageChance, nil)
	
	if mod.IsOmori(player, true) and emotion ~= "Neutral" then
		if DBFlag == false then
			DBFlag = true
			player:TakeDamage(damage * 2, flags, source, cooldown)
			return false
		end
	end
	DBFlag = false

	if not SadIgnore and not AngerDouble then return end
	
	local CustomDamageTrigger = funcs.RandomNumber(1, 100, modrng)
	local hasBirthright = funcs.IsOmori(player, false) and mod:HasBirthright(player)
	local hasBlindRage = player:HasTrinket(TrinketType.TRINKET_BLIND_RAGE)
		
	if SadIgnore then
		local birthrightSadMult = hasBirthright and 1.25 or 1
		SadIgnore = funcs.ceil(SadIgnore * birthrightSadMult)	
		if CustomDamageTrigger <= SadIgnore then
			local baseiFrames = hasBlindRage and 120 or 60
			local iFramesMult = 1 + (SadIgnore / 100)
			local sadIframes = funcs.ceil(iFramesMult * baseiFrames)
			player:SetMinDamageCooldown(sadIframes)
		end
	end
	
	if AngerDouble then
		local birthrightAngryMult = hasBirthright and 1.1 or 1
		AngerDouble = math.ceil(AngerDouble * birthrightAngryMult)
		if CustomDamageTrigger <= AngerDouble then
			if DBFlag == false then
				DBFlag = true
				player:TakeDamage(damage * 2, flags, source, cooldown)
				return false
			end
		end
	end

	DBFlag = false
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, mod.EmotionDamageManager)

---@param tear EntityTear
function mod:SetSadnessKnockback(tear)
	if tear.FrameCount ~= 1 then return end

	local player = funcs.PlayerFromTear(tear)
	if not player then return end

	local emotion = funcs.GetEmotion(player)
	local SadMult = funcs.Switch(emotion, tables.SadnessKnockbackMult, nil)
	
	if not SadMult then return end

	local birthrightMult = (mod.IsOmori(player, false) and mod:HasBirthright(player)) and 1.25 or 1

	tear.Mass = tear.Mass * (1 + SadMult) * birthrightMult
end
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, mod.SetSadnessKnockback)

---@param tear EntityTear
function mod:OnShootHappyTear(tear)
	OmoriMod.DoHappyTear(tear)
end
mod:AddCallback(ModCallbacks.MC_POST_FIRE_TEAR, mod.OnShootHappyTear)

---@param player EntityPlayer
---@param flag CacheFlag
function mod:OmoStats(player, flag)
	local Emotion = funcs.GetEmotion(player)
	local hasBirthright = mod:HasBirthright(player)
	local isOmori = funcs.IsOmori(player, false)

	if not funcs.IsOmori(player, true) then
		if flag == CacheFlag.CACHE_DAMAGE then
			local DamageEmotion = tables.DamageAlterEmotions[Emotion]

			if not DamageEmotion then return end

			local baseDamage = player.Damage
			local EmotionDamageMult = DamageEmotion.EmotionDamageMult
			local damageMult = DamageEmotion.damageMult
			local birthrightMult = DamageEmotion.birthrightMult

			if isOmori then
				local birthrightMultiplier = hasBirthright and birthrightMult or 1
				player.Damage = (baseDamage * damageMult * EmotionDamageMult * birthrightMultiplier)
			else
				player.Damage = baseDamage * EmotionDamageMult
			end
		elseif flag == CacheFlag.CACHE_FIREDELAY then
			local TearsEmotion = tables.TearsAlterEmotions[Emotion]
				
			if not TearsEmotion then return end
				
			local tearsMult = TearsEmotion.tearsMult
			local birthrightMult = TearsEmotion.birthrightMult
			
			if OmoriMod.IsAnyAubrey(player) and tearsMult < 1 then return end

			if isOmori then
				local birthrightMultiplier = hasBirthright and birthrightMult or 1
				player.MaxFireDelay = OmoriMod.tearsUp(player.MaxFireDelay, tearsMult * birthrightMultiplier, true)
			else
				player.MaxFireDelay = OmoriMod.tearsUp(player.MaxFireDelay, tearsMult, true)
			end	
		elseif flag == CacheFlag.CACHE_SPEED then
			local SpeedEmotion = tables.SpeedAlterEmotions[Emotion] 
			
			if not SpeedEmotion then return end
			
			local speedMult = SpeedEmotion.speedMult
			local birthrightMult = SpeedEmotion.birthrightMult
			
			if isOmori then
				local birthrightMultiplier = hasBirthright and birthrightMult or 1
				player.MoveSpeed = (player.MoveSpeed * speedMult) * birthrightMultiplier
			else
				player.MoveSpeed = (player.MoveSpeed * speedMult)
			end	
		elseif flag == CacheFlag.CACHE_LUCK then
			local LuckAdded = tables.LuckAlterEmotions[Emotion] 
			local birthrightAdd = (isOmori and hasBirthright and 1) or 0
			
			if not LuckAdded then return end
			
			player.Luck = player.Luck + (LuckAdded + birthrightAdd)			
		end
	else
		if Emotion == "Neutral" or Emotion == nil then return end

		local emotionAlter = mod.When(Emotion, tables.SunnyEmotionAlter) 
		if flag == CacheFlag.CACHE_DAMAGE then
			player.Damage = player.Damage * emotionAlter.DamageMult
		elseif flag == CacheFlag.CACHE_FIREDELAY then
			player.MaxFireDelay = OmoriMod.tearsUp(player.MaxFireDelay, emotionAlter.FireDelayMult, true)
		elseif flag == CacheFlag.CACHE_RANGE then
			player.TearRange = OmoriMod.rangeUp(player.TearRange, emotionAlter.RangeReduction)
		elseif flag == CacheFlag.CACHE_SPEED then
			player.MoveSpeed = player.MoveSpeed * emotionAlter.SpeedMult
		end
	end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.OmoStats)

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
	local ColorMod = funcs.Switch(emotion, EmotionColorChange)

	if not ColorMod then return end

    game:SetColorModifier(ColorMod, true, 0.3)

    Isaac.CreateTimer(function ()
        game:GetRoom():UpdateColorModifier(true, true, 0.15)
    end, 5, 1, false)
end
mod:AddCallback(enums.Callbacks.EMOTION_CHANGE_TRIGGER, mod.OnEmotionChange)

function mod:OmoriOnNewLevel()
	for _, player in ipairs(PlayerManager.GetPlayers()) do
		if not funcs.GetEmotion(player) then goto continue end
		OmoriMod:ChangeEmotionEffect(player, false)
	    ::continue::
	end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, mod.OmoriOnNewLevel)