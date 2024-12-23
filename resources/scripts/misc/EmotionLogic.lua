local mod = OmoriMod
local enums = OmoriMod.Enums
local utils = enums.Utils
local tables = enums.Tables
local modrng = utils.RNG

local DBFlag = false

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
	local emotion = OmoriMod.GetEmotion(player)
	
	local SadIgnore = tables.SadnessIgnoreDamageChance[emotion]
	local AngerDouble = tables.AngerDoubleDamageChance[emotion]
	
	if not SadIgnore and not AngerDouble then return end
	
	local CustomDamageTrigger = OmoriMod.randomNumber(1, 100, modrng)
	local hasBirthright = OmoriMod:IsOmori(player, false) and player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
	local hasBlindRage = player:HasTrinket(TrinketType.TRINKET_BLIND_RAGE)
		
	if SadIgnore then
		local birthrightSadMult = hasBirthright and 1.25 or 1
		SadIgnore = math.ceil(SadIgnore * birthrightSadMult)	
		if CustomDamageTrigger <= SadIgnore then
			local baseiFrames = hasBlindRage and 120 or 60
			local iFramesMult = 1 + (SadIgnore / 100)
			local sadIframes = math.ceil(iFramesMult * baseiFrames)
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

---comment
---@param tear EntityTear
function mod:SetSadnessKnockback(tear)
	local player = OmoriMod.GetPlayerFromAttack(tear)
	if not player then return end

	local emotion = OmoriMod.GetEmotion(player)
	local SadMult = tables.SadnessKnockbackMult[emotion]
	
	if not SadMult then return end

	local birthrightMult = (OmoriMod:IsOmori(player, false) and player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)) and 1.25 or 1

	if tear.FrameCount == 1 then		
		tear.Mass = tear.Mass * (1 + SadMult) * birthrightMult
	end
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
	local currentEmotion = OmoriMod.GetEmotion(player)
	local hasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
	local isOmori = OmoriMod:IsOmori(player, false)

	if not OmoriMod:IsOmori(player, true) then
		if flag == CacheFlag.CACHE_DAMAGE then
			local DamageEmotion = tables.DamageAlterEmotions[currentEmotion]
			
			if not DamageEmotion then return end
						
			local EmotionDamageMult = DamageEmotion.EmotionDamageMult
			local damageMult = DamageEmotion.damageMult
			local birthrightMult = DamageEmotion.birthrightMult
				
			local baseDamage = player.Damage

			if isOmori then
				local birthrightMultiplier = hasBirthright and birthrightMult or 1
				player.Damage = (baseDamage * damageMult * EmotionDamageMult * birthrightMultiplier)
			else
				player.Damage = baseDamage * EmotionDamageMult
			end
		elseif flag == CacheFlag.CACHE_FIREDELAY then
			local TearsEmotion = tables.TearsAlterEmotions[currentEmotion]
				
			if not TearsEmotion then return end
				
			local tearsMult = TearsEmotion.tearsMult
			local birthrightMult = TearsEmotion.birthrightMult
			
			if OmoriMod:IsAnyAubrey(player) and tearsMult < 1 then return end

			if isOmori then
				local birthrightMultiplier = hasBirthright and birthrightMult or 1
				player.MaxFireDelay = OmoriMod.tearsUp(player.MaxFireDelay, tearsMult * birthrightMultiplier, true)
			else
				player.MaxFireDelay = OmoriMod.tearsUp(player.MaxFireDelay, tearsMult, true)
			end	
		elseif flag == CacheFlag.CACHE_SPEED then
			local SpeedEmotion = tables.SpeedAlterEmotions[currentEmotion] 
			
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
			local LuckAdded = tables.LuckAlterEmotions[currentEmotion] 
			local birthrightAdd = (isOmori and hasBirthright and 1) or 0
			
			if not LuckAdded then return end
			
			player.Luck = player.Luck + (LuckAdded + birthrightAdd)			
		end
	else
		if currentEmotion == "Neutral" or currentEmotion == nil then return end

		local emotionAlter = tables.SunnyEmotionAlter[currentEmotion]
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