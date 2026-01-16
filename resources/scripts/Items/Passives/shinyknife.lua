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

local nonCriticalHitWeapons = {
	[knifeType.NAIL_BAT] = true,
	[knifeType.VIOLIN_BOW] = true
}

---@class OmoriModKnifeData
---@field SwingDamage number
---@field Swings integer
---@field SwingSpeed number
---@field KnifeType KnifeType
---@field KnifeCharge number
---@field HitBlackList table
---@field Aiming number
---@field IsCriticalAttack boolean
---@field IsSwordSwing boolean
---@field ChocoCharge number

local specificPlayerMults = {
	[enums.PlayerType.PLAYER_OMORI] = 2.5,
	[enums.PlayerType.PLAYER_OMORI_B] = 2
}

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

---@param player EntityPlayer
---@return number
local function getWeaponDMG(player)
    local playerData = OmoriMod.GetData(player)
	local emotion = funcs.getemotion(player)
    local DamageMult = specificPlayerMults[player:GetPlayerType()] or 3
	local knife = mod.GetKnife(player)
	local knifeData = knife and mod:GetKnifeData(knife)

	if knifeData and knifeData.KnifeType == knifeType.MR_PLANT_EGG then
		DamageMult = 4
	end

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
		local knife = mod.GetKnife(player)
		if not knife then return false end
		local knifeData = mod:GetKnifeData(knife)
		if not knifeData then return false end

		return ((not HasAnyMilk(player)) and knifeData.KnifeCharge ~= nil)
	end,
	XPadding = 0,
	YPadding = 0,
	OnRender = function(player)
		local playerData = OmoriMod.GetData(player)
		if RoomTransition:GetTransitionMode() == 3 then return end

		playerData.KnifeChargeBar = playerData.KnifeChargeBar or Sprite("gfx/chargebar.anm2", true)

		local playerpos = Isaac.WorldToScreen(player.Position)
		local Chargebar = playerData.KnifeChargeBar
	
		HudHelper.RenderChargeBar(Chargebar, playerData.shinyKnifeCharge, 100, playerpos + Vector(0, 10))
	end
}, HudHelper.HUDType.EXTRA)

---comment
---@param player EntityPlayer
function mod:KnifeSmoothRotation(player)
	local knife = mod.GetKnife(player) ---@cast knife EntityEffect
	local knifeData = mod:GetKnifeData(knife)
	local headDir = player:GetHeadDirection()
	local shouldRenderBelowPlayer = headDir == Direction.NO_DIRECTION or headDir == Direction.DOWN
	local aimDegrees = player:GetAimDirection():GetAngleDegrees()
	local isShooting = mod:IsPlayerShooting(player, false)
	local isKnifeIdle = knife:GetSprite():IsPlaying("Idle")
	local isMoving = mod:IsPlayerMoving(player)

	if not knifeData then return end

	

	knife.DepthOffset = shouldRenderBelowPlayer and 1 or -10

	if isShooting then
		knifeData.Aiming = aimDegrees
		knife.SpriteRotation = knifeData.Aiming
	elseif isKnifeIdle then
		knife.SpriteRotation = player:GetSmoothBodyRotation()
		if not isMoving then
			knife.SpriteRotation = tables.DirectionToDegrees[headDir]
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.KnifeSmoothRotation)

---@param knife EntityEffect
function mod:ShinyKnifeUpdate(knife)
	local knifesprite = knife:GetSprite()
    local player = knife.SpawnerEntity:ToPlayer()
	local knifeData = mod:GetKnifeData(knife)

	if not knifeData then return end

	local KnifeType = knifeData.KnifeType ---@type KnifeType

	local Ret = funcs.runcallback(OmoriModCallbacks.PRE_KNIFE_UPDATE, knife, KnifeType) ---@type boolean

	if Ret == false then return end

	if not player then return end
    local playerData = OmoriMod.GetData(player)
	
	local isShooting = OmoriMod:IsPlayerShooting(player, true)	
	local multiShot = player:GetMultiShotParams(WeaponType.WEAPON_TEARS)
	local numTears = multiShot:GetNumTears()
	local isIdle = knifesprite:IsPlaying("Idle")
	local baseSwings = OmoriMod.IsOmori(player, true) and 2 or 0
	local HasMarked = player:GetMarkedTarget() ~= nil

	knifeData.KnifeCharge = knifeData.KnifeCharge or 0 
	knifeData.Swings = knifeData.Swings or 0
	knifeData.SwingSpeed = knifeData.SwingSpeed or 1

	if isIdle then
		if isShooting then
			if player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) then
				knifeData.HitBlackList = {}
				OmoriMod:InitKnifeSwing(knife)	
			end

			local knifeChargeFormula = (OmoriMod.IsOmori(player, true) and (((0.05 + (OmoriMod.TearsPerSecond(player) / 50)) / 2.5)) * 100) or (((0.025 + (OmoriMod.TearsPerSecond(player) / 100)) / 2.5)) * 100
			
			local newCharge = funcs.runcallback(OmoriModCallbacks.PRE_KNIFE_CHARGE, knife, KnifeType) ---@type number

			knifeChargeFormula = newCharge or knifeChargeFormula

			playerData.shinyKnifeCharge = math.min(playerData.shinyKnifeCharge + knifeChargeFormula, 100)
			
			-- if playerData.shinyKnifeCharge >= 99 then playerData.shinyKnifeCharge = 100 end

			playerData.Swings = numTears + baseSwings		
			
			if not isShooting and not knifesprite:IsPlaying("Swing") and playerData.shinyKnifeCharge > 0 then
				playerData.shinyKnifeCharge = 0
			end

			if HasMarked and playerData.shinyKnifeCharge == 100 and playerData.Swings > 0 and isIdle then
				OmoriMod:InitKnifeSwing(knife)
				playerData.Swings = playerData.Swings - 1
			end
		else
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
		knifeData.HitBlackList = {}
		knifesprite:Play("Idle")
		
		funcs.runcallback(OmoriModCallbacks.KNIFE_SWING_FINISH, knife, KnifeType)

		if playerData.Swings == 0 and knifesprite:IsPlaying("Idle") then
			playerData.shinyKnifeCharge = 0
		elseif playerData.Swings > 0 and knifesprite:IsPlaying("Idle") and isShooting and not knifeData.IsSwordSwing then
			OmoriMod:InitKnifeSwing(knife)
			playerData.Swings = playerData.Swings - 1
		end
		knifeData.IsCriticalAttack = false
		knife.Color = Color.Default

		if knifeData.IsSwordSwing then
			knifeData.IsSwordSwing = false
		end

		playerData.ChoccyCharge = 0

		OmoriMod.SetKnifeSizeMult(knife, 1)
	end	

	local swingSpeed = knifeData.SwingSpeed or knifeData.IsSwordSwing and 2.5 or ((numTears > 1 and 1.5) or 1)
	knifesprite.PlaybackSpeed = knifeData.SwingSpeed

	funcs.runcallback(OmoriModCallbacks.POST_KNIFE_UPDATE, knife, KnifeType)
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, mod.ShinyKnifeUpdate, OmoriMod.Enums.EffectVariant.EFFECT_SHINY_KNIFE)

---@param knife EntityEffect
function mod:KnifeUpdate(knife)
	local knifeData = OmoriMod.GetData(knife)
	local KnifeType = knifeData.KnifeType ---@type KnifeType
	local knifeSprite = knife:GetSprite()

	if not knifeSprite:IsPlaying("Swing") then return end
	funcs.runcallback(OmoriModCallbacks.KNIFE_SWING_UPDATE, knife, KnifeType)
end
mod:AddCallback(OmoriModCallbacks.POST_KNIFE_UPDATE, mod.KnifeUpdate)

---@param knife EntityEffect
function mod:OnKnifeSwingTrigger(knife)
	local knifeData = mod:GetKnifeData(knife)
	local player = mod:GetKnifeOwner(knife)
	
	if not player then return end
	if not knifeData then return end
	if not (mod.IsAnyOmori(player) or player:HasCollectible(enums.CollectibleType.COLLECTIBLE_SHINY_KNIFE)) then return end

	-- knifeData.SwingSpeed = 2

	local emotion = OmoriMod.GetEmotion(player)
	local soundEffect = (mod.IsOmori(player, true) and sounds.SOUND_VIOLIN_BOW_SLASH) or sounds.SOUND_BLADE_SLASH
	local randomPitch = soundEffect == sounds.SOUND_VIOLIN_BOW_SLASH and OmoriMod.randomfloat(0.9, 1.1, rng) or 1

	sfx:Play(soundEffect, 1, 0, false, randomPitch, 0)

	if tables.HappinessTiers[emotion] == nil then return end
		
	local criticalBase = tables.BaseOriginGameLuck[player:GetPlayerType()] or 0.05
	local criticalChance = (criticalBase * tables.HappyKnifeCriticalHitMult[emotion]) + (player.Luck / 100)

	knifeData.IsCriticalAttack = mod.RandomBoolean(utils.RNG, criticalChance)

	if knifeData.IsCriticalAttack then
		knife.Color = misc.CriticColor
	end
end
mod:AddCallback(OmoriModCallbacks.KNIFE_SWING_TRIGGER, mod.OnKnifeSwingTrigger)

if debug == true then 
	function mod:DebugRender(knife)	
		for _ = 1, 2 do
			local capsule = knife:GetNullCapsule("KnifeHit" .. 2)
			local debugShape = knife:GetDebugShape()
			debugShape:Capsule(capsule)
		end
	end
	mod:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, mod.DebugRender, enums.EffectVariant.EFFECT_SHINY_KNIFE)
end

---@param knife EntityEffect
function mod:OnKnifeSwing(knife)
	local knifeData = OmoriMod:GetKnifeData(knife) --[[@as OmoriModKnifeData]]
	local player = OmoriMod:GetKnifeOwner(knife)

	if not player then return end

	knifeData.HitBlackList = knifeData.HitBlackList or {}		
	knife.SpriteRotation = knifeData.Aiming

	OmoriMod.SetKnifeSizeMult(knife, math.max((player.TearRange / 40) / 6.5, 1))

	for i = 1, 2 do
		local capsule = knife:GetNullCapsule("KnifeHit" .. i)
		for _, ent in ipairs(Isaac.FindInCapsule(capsule)) do
			if ent:ToPlayer() then goto continue end
			if knifeData.HitBlackList[GetPtrHash(ent)] then goto continue end

			local isEnemy =  mod:IsEnemy(ent)

			if not isEnemy then
				funcs.runcallback(OmoriModCallbacks.KNIFE_ENTITY_COLLISION, knife, ent)	
				goto continue
			end

			local hasKnife = player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE)
			local numberHits = hasKnife and 4 or 1	
			knifeData.SwingDamage = getWeaponDMG(player)

			for _ = 1, numberHits do
				funcs.runcallback(OmoriModCallbacks.KNIFE_HIT_ENEMY, knife, ent)
				ent:TakeDamage(knifeData.SwingDamage, 0, EntityRef(knife), 0)
			end

			knifeData.HitBlackList[GetPtrHash(ent)] = true
			::continue::
		end
	end
end
mod:AddCallback(OmoriModCallbacks.KNIFE_SWING_UPDATE, mod.OnKnifeSwing)

---@param player EntityPlayer
---@param knifeData OmoriModKnifeData
local function HappyHitManager(player, knifeData)
	if mod.When(knifeData.KnifeType, nonCriticalHitWeapons, false) then return end
	
	local emotion = OmoriMod.GetEmotion(player)
	local isCritHit = knifeData.IsCriticalAttack

	if not tables.HappinessTiers[emotion] then return end

	local Failed = not isCritHit and mod.RandomBoolean(utils.RNG, tables.HappinessFailChance[emotion])

	local CriticalDamageFormula = (knifeData.SwingDamage * 1.5) + 2

	knifeData.SwingDamage = (isCritHit and CriticalDamageFormula) or (Failed and 0) or knifeData.SwingDamage

	if knifeData.IsCriticalAttack then
		sfx:Play(sounds.SOUND_RIGHT_IN_THE_HEART, 1)
	elseif Failed then
		sfx:Play(sounds.SOUND_MISS_ATTACK, 2)
	end
end

---@param knife EntityEffect
---@param entity Entity
---@param type KnifeType
---@return number?
function mod:OnDamagingWithShinyKnife(knife, entity, type)
	local player = knife.SpawnerEntity:ToPlayer()
	local knifeData = mod:GetKnifeData(knife)
	
	if not player then return end
	if not knifeData then return end

	local hasBirthright = mod:HasBirthright(player)
	local emotion = OmoriMod.GetEmotion(player)
	
	HappyHitManager(player, knifeData)
	
	if knifeData.SwingDamage > 0 then 
		sfx:Play(SoundEffect.SOUND_MEATY_DEATHS, 1, 0, false, 1, 0)
	end
	
	local birthrightMult = (OmoriMod.IsOmori(player, false) and hasBirthright) and 1.2 or 1
	local sadKnockbackMult = OmoriMod.When(emotion, tables.SadnessKnockbackMult, 1) * birthrightMult
	local resizer = (20 * sadKnockbackMult) * player.ShotSpeed
	entity:AddEntityFlags(EntityFlag.FLAG_KNOCKED_BACK | EntityFlag.FLAG_APPLY_IMPACT_DAMAGE --[[@as EntityFlag]])

	funcs.push(entity, player, resizer, 5, true) 
end
mod:AddCallback(OmoriModCallbacks.KNIFE_HIT_ENEMY, mod.OnDamagingWithShinyKnife)

function mod:KnifeRenderMan(knife)
	funcs.runcallback(OmoriModCallbacks.POST_KNIFE_RENDER, knife)
end
mod:AddCallback(ModCallbacks.MC_POST_EFFECT_RENDER, mod.KnifeRenderMan, enums.EffectVariant.EFFECT_SHINY_KNIFE)

local happyTier = {
	["Happy"] = 0.1,
	["Ecstatic"] = 0.15,
	["Manic"] = 0.2,
} 

local PickupSpawn = {
	[1] = PickupVariant.PICKUP_HEART,
	[2] = PickupVariant.PICKUP_COIN,
	[3] = PickupVariant.PICKUP_KEY,
	[4] = PickupVariant.PICKUP_BOMB
}

function mod:ShinyKnifeKill(knife, enemy)
	local knifeData = mod:GetKnifeData(knife)
	local player = knife.SpawnerEntity:ToPlayer()
	local emotion = OmoriMod.GetEmotion(player)
	local MaxSpawnPickupChance = funcs.switch(emotion, happyTier)

	if not player then return end
	if not knifeData then return end
	if not knifeData.IsCriticalAttack then return end
	if not MaxSpawnPickupChance then return end
	if not mod.RandomBoolean(nil, MaxSpawnPickupChance + (player.Luck / 10)) then return end

	local pickupToSpawn = funcs.switch(OmoriMod.randomNumber(1, 4, rng), PickupSpawn, 1)

	Isaac.Spawn(
		EntityType.ENTITY_PICKUP,
		pickupToSpawn,
		0,
		enemy.Position,
		Vector.Zero,
		nil
	)
end
mod:AddCallback(OmoriModCallbacks.KNIFE_KILL_ENEMY, mod.ShinyKnifeKill)

---comment
---@param knife EntityEffect
---@param entity Entity
function mod:KnifeCollidingNonEnemies(knife, entity)
	local player = OmoriMod:GetKnifeOwner(knife)

	if not player then return end

	local playerData = OmoriMod.GetData(player)
	local var = entity.Variant
	local type = entity.Type

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

			if isBlacklistedFireplace then return end
			entity:Kill()
		end,
		[EntityType.ENTITY_PICKUP] = function()
			local isBlackListedPickup = funcs.switch(var, tables.PickupBlacklist, false)

			if isBlackListedPickup then return end
			player:ForceCollide(entity, true)
		end,
		[EntityType.ENTITY_PROJECTILE] = function()
			local projectile = entity:ToProjectile()
			if not projectile then return end
			if not player:HasCollectible(CollectibleType.COLLECTIBLE_SPIRIT_SWORD) then return end
			if playerData.shinyKnifeCharge < 100 then return end
			projectile:AddProjectileFlags(ProjectileFlags.HIT_ENEMIES | ProjectileFlags.CANT_HIT_PLAYER)
			funcs.push(entity, player, 20, 2, false)

			if not player:HasCollectible(CollectibleType.COLLECTIBLE_LOST_CONTACT) then return end
			projectile:Kill()
		end,
		[EntityType.ENTITY_STONEY] = function()
			funcs.push(entity, player, 30, 2, false)
		end,
	}

	if not NonEnemyEntities[type] then return end
	funcs.switch(type, NonEnemyEntities)()
end
mod:AddCallback(OmoriModCallbacks.KNIFE_ENTITY_COLLISION, mod.KnifeCollidingNonEnemies)

---@param player EntityPlayer
---@param flag CacheFlag
function mod:tearsAdjustment(player, flag)
    if not OmoriMod:IsKnifeUser(player) then return end
	if not (player:HasCollectible(CollectibleType.COLLECTIBLE_BRIMSTONE) and (player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) or player:HasCollectible(CollectibleType.COLLECTIBLE_SPIRIT_SWORD))) then return end
	player.MaxFireDelay = OmoriMod.tearsUp(player.MaxFireDelay, 1/3, true)
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.tearsAdjustment, CacheFlag.CACHE_FIREDELAY)