local mod = OmoriMod
local enums = mod.Enums
local tables, utils = enums.Tables, enums.Utils
local sfx , rng = utils.SFX, utils.RNG
local knifeType = enums.KnifeType
local OmoriModCallbacks = enums.Callbacks
local misc = enums.Misc
local sounds = enums.SoundEffect
local debug = false

local funcs = {
	switch = mod.When,
	runcallback = Isaac.RunCallback,
	push = mod.TriggerPush,
	getemotion = mod.GetEmotion,
	isomori = mod.IsOmori,
}

---@param player EntityPlayer
---@return number
local function getWeaponDMG(player)
    local playerData = OmoriMod.GetData(player)
	local emotion = funcs.getemotion(player)
    local DamageMult = (funcs.isomori(player, true) and 2) or (funcs.isomori(player, false) and 2.5) or 3
	
	local MrPlantEgg = OmoriMod.GetKnife(player, "MrPlantEgg")

	if MrPlantEgg then
		DamageMult = 4
	end

	local angerValues = {
		["Angry"] = 1.1,
		["Enraged"] = 1.2,
		["Furious"] = 1.3,
	}

	local SunnyEmotionsMult = {
		["Neutral"] = 0,
		["Afraid"] = 1,
		["StressedOut"] = 2
	}
	
	local AngerMult = funcs.switch(emotion, angerValues, 1) 

    if funcs.isomori(player, true) then
		local isFocus = playerData.IncreasedBowDamage
		local FocusBonus = isFocus == true and 1 or 0
		local SunnyMult = funcs.switch(emotion, SunnyEmotionsMult, 0)

		DamageMult = DamageMult + SunnyMult + FocusBonus
    end
    return (player.Damage * DamageMult) * AngerMult
end

local function HasAnyMilk(player)
	return player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) or
		   player:HasCollectible(CollectibleType.COLLECTIBLE_ALMOND_MILK) or
		   player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK)
end

HudHelper.RegisterHUDElement({
	Name = "KnifeChargeBar",
	Priority = HudHelper.Priority.NORMAL,
	Condition = function(player)
		local playerData = OmoriMod.GetData(player)
		return (not HasAnyMilk(player)) and playerData.shinyKnifeCharge
	end,
	XPadding = 0,
	YPadding = 0,
	OnRender = function(player)
		local playerData = OmoriMod.GetData(player)
		if RoomTransition:GetTransitionMode() == 3 then return end

		if not playerData.KnifeChargeBar then
			playerData.KnifeChargeBar = Sprite()
			playerData.KnifeChargeBar:Load("gfx/chargebar.anm2", true)
		end
		local playerpos = Isaac.WorldToScreen(player.Position)
		local Chargebar = playerData.KnifeChargeBar
	
		HudHelper.RenderChargeBar(Chargebar, playerData.shinyKnifeCharge, 100, playerpos + Vector(0, 10))
	end
}, HudHelper.HUDType.EXTRA)

-- function mod:OnKnifeRemoving()
-- 	local players = PlayerManager.GetPlayers()
-- 	for _, player in ipairs(players) do
-- 		local playerData = OmoriMod.GetData(player)
-- 		if not OmoriMod:IsPlayerShooting(player, false) then
-- 			playerData.shinyKnifeCharge = 0
-- 		end
-- 		OmoriMod.RemoveKnife(player, "ShinyKnife")
-- 	end
-- end
-- mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.OnKnifeRemoving)

---comment
---@param player EntityPlayer
function mod:KnifeSmoothRotation(player)
	local playerData = OmoriMod.GetData(player)

	if not playerData.KnifeData then return end

	for k, v in pairs(playerData.KnifeData) do
		local knife = v
		local knifesprite = knife:GetSprite()
		local knifeData = OmoriMod.GetData(knife)
		local isShooting = OmoriMod:IsPlayerShooting(player, false)
		local aimDegrees = player:GetAimDirection():GetAngleDegrees()
		local isIdle = knifesprite:IsPlaying("Idle")
		local isMoving = OmoriMod:IsPlayerMoving(player)
	
		knife.Position = player.Position

		if k == "MrPlantEgg" then break end

		if isShooting then
			knifeData.Aiming = aimDegrees
		end

		local headDir = player:GetHeadDirection()
		local renderBelowPlayer = headDir == Direction.NO_DIRECTION or headDir == Direction.DOWN

		knife.DepthOffset = renderBelowPlayer and 1 or -10

		if isShooting then
			knife.SpriteRotation = knifeData.Aiming
		elseif isIdle then
			knife.SpriteRotation = player:GetSmoothBodyRotation()
			if not isMoving then
				knife.SpriteRotation = tables.DirectionToDegrees[headDir]
			end
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.KnifeSmoothRotation)

---@param knife EntityEffect
function mod:ShinyKnifeUpdate(knife)
	local knifesprite = knife:GetSprite()
    local player = knife.SpawnerEntity:ToPlayer()

	local knifeData = OmoriMod.GetData(knife)
	local KnifeType = knifeData.KnifeType ---@type KnifeType

	local Ret = funcs.runcallback(OmoriModCallbacks.PRE_KNIFE_UPDATE, knife, KnifeType) ---@type boolean

	if Ret == false then return end

	if not player then return end
    local playerData = OmoriMod.GetData(player)
	
	local isShooting = OmoriMod:IsPlayerShooting(player, false)	
	local multiShot = player:GetMultiShotParams(WeaponType.WEAPON_TEARS)
	local numTears = multiShot:GetNumTears()
	local isIdle = knifesprite:IsPlaying("Idle")
	local baseSwings = OmoriMod.IsOmori(player, true) and 2 or 0
	local HasMarked = player:GetMarkedTarget() ~= nil

	playerData.shinyKnifeCharge = playerData.shinyKnifeCharge or 0
	playerData.Swings = playerData.Swings or 0
			
	if isShooting then
		if player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) and isIdle then
			knifeData.HitBlacklist = {}
			OmoriMod:InitKnifeSwing(knife)	
		end

		if isIdle then
			local knifeChargeFormula = (OmoriMod.IsOmori(player, true) and (((0.05 + (OmoriMod.TearsPerSecond(player) / 50)) / 2.5)) * 100) or (((0.025 + (OmoriMod.TearsPerSecond(player) / 100)) / 2.5)) * 100
			
			local newCharge = funcs.runcallback(OmoriModCallbacks.PRE_KNIFE_CHARGE, knife, KnifeType) ---@type number

			knifeChargeFormula = newCharge or knifeChargeFormula

			playerData.shinyKnifeCharge = math.min(playerData.shinyKnifeCharge + knifeChargeFormula, 100)
			
			if playerData.shinyKnifeCharge >= 99 then playerData.shinyKnifeCharge = 100 end

			playerData.Swings = numTears + baseSwings		
			
			if not isShooting and not knifesprite:IsPlaying("Swing") and playerData.shinyKnifeCharge > 0 then
				playerData.shinyKnifeCharge = 0
			end

			if HasMarked and playerData.shinyKnifeCharge == 100 and playerData.Swings > 0 and isIdle then
				OmoriMod:InitKnifeSwing(knife)
				playerData.Swings = playerData.Swings - 1
			end
		end
	else
		if isIdle then
			if player:HasCollectible(CollectibleType.COLLECTIBLE_CHOCOLATE_MILK) and playerData.shinyKnifeCharge > 0 then
				OmoriMod:InitKnifeSwing(knife)
			end

			if playerData.shinyKnifeCharge == 100 and playerData.Swings > 0 then
				OmoriMod:InitKnifeSwing(knife)
				playerData.Swings = playerData.Swings - 1
			end 
		
			if playerData.shinyKnifeCharge ~= 100 then
				playerData.shinyKnifeCharge = 0
			end
		end
	end

	if knifesprite:IsFinished("Swing") then
		knifeData.HitBlacklist = {}
		knifesprite:Play("Idle")
		
		funcs.runcallback(OmoriModCallbacks.KNIFE_SWING_FINISH, knife, KnifeType)

		if playerData.Swings == 0 and knifesprite:IsPlaying("Idle") then
			playerData.shinyKnifeCharge = 0
		elseif playerData.Swings > 0 and knifesprite:IsPlaying("Idle") and isShooting and not knifeData.SwordSwing then
			OmoriMod:InitKnifeSwing(knife)
			playerData.Swings = playerData.Swings - 1
		end
		knifeData.IsCriticAtack = false
		knife.Color = Color.Default

		if knifeData.SwordSwing then
			knifeData.SwordSwing = false
		end

		playerData.ChoccyCharge = 0

		OmoriMod.SetKnifeSizeMult(knife, 1)
	end	

	local swingSpeed = knifeData.SwordSwing and 2.5 or ((numTears > 1 and 1.5) or 1)

	print(swingSpeed)

	knifesprite.PlaybackSpeed = swingSpeed

	funcs.runcallback(OmoriModCallbacks.POST_KNIFE_UPDATE, knife, KnifeType)
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.ShinyKnifeUpdate, OmoriMod.Enums.EffectVariant.EFFECT_SHINY_KNIFE)

---@param knife EntityEffect
function mod:KnifeUpdate(knife)
	local knifeData = OmoriMod.GetData(knife)
	local KnifeType = knifeData.KnifeType ---@type KnifeType

	local knifeSprite = knife:GetSprite()

	if knifeSprite:IsPlaying("Swing") then
		funcs.runcallback(OmoriModCallbacks.KNIFE_SWING_UPDATE, knife, KnifeType)
	end
end
mod:AddCallback(OmoriModCallbacks.POST_KNIFE_UPDATE, mod.KnifeUpdate)

---@param knife EntityEffect
function mod:OnKnifeSwingTrigger(knife)
	local knifeData = OmoriMod.GetData(knife)
	local CriticDamageChance = OmoriMod.randomNumber(1, 100, rng) 

	local player = knife.SpawnerEntity:ToPlayer()
	
	if not player then return end
	
	if not (OmoriMod.IsAnyOmori(player) or player:HasCollectible(enums.CollectibleType.COLLECTIBLE_SHINY_KNIFE)) then return end

	local soundEffect = (OmoriMod.IsOmori(player, true) and sounds.SOUND_VIOLIN_BOW_SLASH) or sounds.SOUND_BLADE_SLASH

	local randomPitch = soundEffect == sounds.SOUND_VIOLIN_BOW_SLASH and OmoriMod.randomfloat(0.9, 1.1, rng) or 1

	sfx:Play(soundEffect, 1, 0, false, randomPitch, 0)

	if not player then return end

	local emotion = OmoriMod.GetEmotion(player)

	knifeData.IsCriticAtack = knifeData.IsCriticAtack or false

	if tables.HappinessTiers[emotion] == nil then return end
		
	local criticChance = tables.HappyKnifeCriticChance[emotion]
				
	if CriticDamageChance <= criticChance then
		knifeData.IsCriticAtack = true
		knife.Color = misc.CriticColor
	else
		knifeData.IsCriticAtack = false
	end
end
mod:AddCallback(OmoriModCallbacks.KNIFE_SWING_TRIGGER, mod.OnKnifeSwingTrigger)

if debug == true then 
	function mod:AAAA(knife)	
		for _ = 1, 2 do
			local capsule = knife:GetNullCapsule("KnifeHit" .. 2)
			local debugShape = knife:GetDebugShape()
			debugShape:Capsule(capsule)
		end
	end
	mod:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, mod.AAAA, enums.EffectVariant.EFFECT_SHINY_KNIFE)
end

function mod:OnKnifeSwing(knife)
	local knifeData = OmoriMod.GetData(knife)
	local KnifeType = knifeData.KnifeType ---@type KnifeType
	knifeData.HitBlacklist = knifeData.HitBlacklist or {}		
	knife.SpriteRotation = knifeData.Aiming
		
	local player = OmoriMod:GetKnifeOwner(knife)

	OmoriMod.SetKnifeSizeMult(knife, math.max((player.TearRange / 40) / 6.5, 1))

	for i = 1, 2 do
		local capsule = knife:GetNullCapsule("KnifeHit" .. i)
		for _, entity in ipairs(Isaac.FindInCapsule(capsule)) do
			if entity:ToPlayer() or entity:ToTear() then return end
			if not knifeData.HitBlacklist[GetPtrHash(entity)] then
				local isEnemy = entity:IsVulnerableEnemy() and entity:IsActiveEnemy()
				if isEnemy then
					knifeData.Damage = getWeaponDMG(player)

					local hasKnife = player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE)
					local numberHits = hasKnife and 4 or 1

					for _ = 1, numberHits do
						funcs.runcallback(OmoriModCallbacks.KNIFE_HIT_ENEMY, knife, entity, knifeData.Damage, KnifeType)
						entity:TakeDamage(knifeData.Damage, 0, EntityRef(knife), 0)
					end

					if entity.HitPoints <= knifeData.Damage then
						funcs.runcallback(OmoriModCallbacks.KNIFE_KILL_ENEMY, knife, entity, KnifeType)
					end
				else
					funcs.runcallback(OmoriModCallbacks.KNIFE_ENTITY_COLLISION, knife, entity, KnifeType)	
				end
				knifeData.HitBlacklist[GetPtrHash(entity)] = true
			end
		end
	end
end
mod:AddCallback(OmoriModCallbacks.KNIFE_SWING_UPDATE, mod.OnKnifeSwing)

---@param knife EntityEffect
---@param entity Entity
---@param damage number
---@param type KnifeType
---@return number?
function mod:OnDamagingWithShinyKnife(knife, entity, damage, type)
	local player = knife.SpawnerEntity:ToPlayer()
	local knifeData = OmoriMod.GetData(knife)
	
	if not player then return end

	local hasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
	local emotion = OmoriMod.GetEmotion(player)
	local IsHappy = tables.HappinessTiers[emotion]
	
	local Damage = damage

	if IsHappy and (type ~= knifeType.VIOLIN_BOW and type ~= knifeType.NAIL_BAT) then
		if knifeData.IsCriticAtack then
			Damage = Damage * 2
			sfx:Play(sounds.SOUND_RIGHT_IN_THE_HEART, 1, 0, false, 1, 0)
		else
			local failChance = OmoriMod.When(emotion, tables.HappinessFailChance, nil)
			if failChance and OmoriMod.randomNumber(1, 100, rng) <= failChance then
				sfx:Play(sounds.SOUND_MISS_ATTACK, 2, 0, false, 1, 0)
				Damage = 0
			end
		end
	end
	
	if Damage > 0 then 
		sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 1, 0, false, 1, 0)
	end

	knifeData.Damage = Damage
	
	local birthrightMult = (OmoriMod.IsOmori(player, false) and hasBirthright) and 1.2 or 1
	local sadKnockbackMult = OmoriMod.When(emotion, tables.SadnessKnockbackMult, 1) 
	local realSadKnockMult = sadKnockbackMult * birthrightMult
		
	local resizer = (20 * realSadKnockMult) * (player.ShotSpeed)
	entity:AddEntityFlags(EntityFlag.FLAG_KNOCKED_BACK | EntityFlag.FLAG_APPLY_IMPACT_DAMAGE)

	funcs.push(entity, player, resizer, 5, true) 
end
mod:AddCallback(OmoriModCallbacks.KNIFE_HIT_ENEMY, mod.OnDamagingWithShinyKnife)

function mod:KnifeRenderMan(knife)
	funcs.runcallback(OmoriModCallbacks.POST_KNIFE_RENDER, knife)
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, mod.KnifeRenderMan, enums.EffectVariant.EFFECT_SHINY_KNIFE)

function mod:ShinyKnifeKill(knife, enemy)
	local knifeData = OmoriMod.GetData(knife)
	local player = knife.SpawnerEntity:ToPlayer()
	local emotion = OmoriMod.GetEmotion(player)
	if not knifeData.IsCriticAtack then return end

	local happyTier = {
		["Happy"] = 10,
		["Ecstatic"] = 15,
		["Manic"] = 20,
	} 

	local SpawnPickupChance = OmoriMod.randomNumber(1, 100, rng)
	local MaxSpawnPickupChance = happyTier[emotion]

	if not MaxSpawnPickupChance then return end

	if SpawnPickupChance <= MaxSpawnPickupChance + (player.Luck) then
		local PickupSpawn = {
			[1] = PickupVariant.PICKUP_HEART,
			[2] = PickupVariant.PICKUP_COIN,
			[3] = PickupVariant.PICKUP_KEY,
			[4] = PickupVariant.PICKUP_BOMB
		}

		local pickupToSpawn = PickupSpawn[OmoriMod.randomNumber(1, 4, rng)]

		Isaac.Spawn(
			EntityType.ENTITY_PICKUP,
			pickupToSpawn,
			0,
			enemy.Position,
			Vector.Zero,
			nil
		)
	end
end
mod:AddCallback(OmoriModCallbacks.KNIFE_KILL_ENEMY, mod.ShinyKnifeKill)

---comment
---@param knife EntityEffect
---@param entity Entity
function mod:KnifeCollidingNonEnemies(knife, entity)
	local player = OmoriMod:GetKnifeOwner(knife)
	local playerData = OmoriMod.GetData(player)

	local var = entity.Variant -- Entity's Variant
	local type = entity.Type -- Entity's Type

	local NonEnemyEntities = {
		[EntityType.ENTITY_FAMILIAR] = function()
			if var ~= FamiliarVariant.PUNCHING_BAG and var ~= FamiliarVariant.CUBE_BABY then return end
			if var == FamiliarVariant.CUBE_BABY then
				local familiar = entity:ToFamiliar()
				if familiar then
					familiar:Shoot()
				end
			end

			funcs.push(entity, player, 30, 2, false)
		end,
		[EntityType.ENTITY_BOMB] = function()
			funcs.push(entity, player, 30, 2, false)
		end,
		[EntityType.ENTITY_FIREPLACE] = function()
			local isBlacklistedFireplace = funcs.switch(var, tables.BlacklistedFireplaces, false)

			if isBlacklistedFireplace == true then return end
			entity:Kill()
		end,
		[EntityType.ENTITY_PICKUP] = function()
			local isBlackListedPickup = funcs.switch(var, tables.PickupBlacklist, false)

			if isBlackListedPickup == true then return end
			player:ForceCollide(entity, true)
		end,
		[EntityType.ENTITY_PROJECTILE] = function()
			local projectile = entity:ToProjectile()
			if not projectile then return end
			if not player:HasCollectible(CollectibleType.COLLECTIBLE_SPIRIT_SWORD) then return end
			if playerData.shinyKnifeCharge < 100 then return end
			projectile:AddProjectileFlags(ProjectileFlags.HIT_ENEMIES | ProjectileFlags.CANT_HIT_PLAYER)
			projectile.Damage = player.Damage * 2
			funcs.push(entity, player, 20, 2, false)

			if not player:HasCollectible(CollectibleType.COLLECTIBLE_LOST_CONTACT) then return end
			projectile:Kill()
		end,
		[EntityType.ENTITY_STONEY] = function()
			funcs.push(entity, player, 30, 2, false)
		end,
	}

	if not NonEnemyEntities[type] then return end
	funcs.switch(type, NonEnemyEntities, 2)()
end
mod:AddCallback(OmoriModCallbacks.KNIFE_ENTITY_COLLISION, mod.KnifeCollidingNonEnemies)

---@param player EntityPlayer
---@param flag CacheFlag
function mod:tearsAdjustment(player, flag)
    if OmoriMod:IsKnifeUser(player) then
        if player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) and (player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) or player:HasCollectible(CollectibleType.COLLECTIBLE_SPIRIT_SWORD)) then
            if flag == CacheFlag.CACHE_FIREDELAY then
                player.MaxFireDelay = OmoriMod.tearsUp(player.MaxFireDelay, 1 / 3, true)
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.tearsAdjustment)