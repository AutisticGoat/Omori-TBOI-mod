local enums = OmoriMod.Enums
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local modrng = utils.RNG
local tables = enums.Tables
local players = enums.PlayerType
local HBParams = tables.AubreyHeadButtParams
local misc = enums.Misc
local sounds = enums.SoundEffect
local knifeType = enums.KnifeType
local OmoriModCallbacks = enums.Callbacks

function OmoriMod.GetScreenCenter()
	local room = game:GetRoom()
	local pos = room:WorldToScreenPosition(Vector(0,0)) - room:GetRenderScrollOffset() - game.ScreenShakeOffset	
	local rx = pos.X + 60 * 26 / 40
	local ry = pos.Y + 140 * (26 / 40)
	return Vector(rx * 2 + 13 * 26, ry * 2 + 7 * 26) / 2
end 

---@param number number	
---@param decimalPlaces integer
function OmoriMod:Round(number, decimalPlaces)
	decimalPlaces = decimalPlaces or 0
	local mult = 10 ^ (decimalPlaces)
	return math.floor(number * mult + 0.5) / mult
end

--- @param entity Entity
--- @return number
function OmoriMod:GetAceleration(entity)
	return OmoriMod:Round(entity.Velocity:Length(), 2)
end

---@param x integer
---@param y integer
---@param rng RNG
---@return integer
function OmoriMod.randomNumber(x, y, rng)
    if not y then
        y = x
        x = 1
    end
	if not rng then
		rng = RNG()
	end
    return (rng:RandomInt(y - x + 1)) + x
end

--- @param x number
--- @param y number
--- @param rng RNG
--- @return number
function OmoriMod.randomfloat(x, y, rng)
    if not y then
        y = x
        x = 0
    end
    x = x * 1000
    y = y * 1000
    if not rng then
        rng = RNG()
    end
    return math.floor((rng:RandomInt(y - x + 1)) + x) / 1000
end

--- @param player EntityPlayer
--- @param tainted boolean
--- @return boolean
function OmoriMod.IsOmori(player, tainted)
	return player:GetPlayerType() == (tainted and players.PLAYER_OMORI_B or players.PLAYER_OMORI)
end

--- @param player EntityPlayer
--- @param tainted boolean
--- @return boolean
function OmoriMod.IsAubrey(player, tainted)
	return player:GetPlayerType() == (tainted and players.PLAYER_AUBREY_B or players.PLAYER_AUBREY)
end

--- @param player EntityPlayer
--- @return boolean
function OmoriMod.IsAnyOmori(player)
	return OmoriMod.IsOmori(player, true) or OmoriMod.IsOmori(player, false)
end

--- @param player EntityPlayer
--- @return boolean
function OmoriMod.IsAnyAubrey(player)
	return OmoriMod.IsAubrey(player, true) or OmoriMod.IsAubrey(player, false)
end

---@param secs number
---@return integer
function OmoriMod:SecsToFrames(secs)
	return math.ceil(secs * 30)
end

---@param secs number
---@return number
function OmoriMod:SecsToKnifeCharge(secs)
	return 3 / secs
end

---@param player EntityPlayer
---@return boolean
function OmoriMod:IsEmotionChangeTriggered(player)
	local emotionChange =
	Input.IsButtonTriggered(Keyboard.KEY_Z, player.ControllerIndex) or
	Input.IsButtonTriggered(Keyboard.KEY_LEFT_SHIFT, player.ControllerIndex) or
	Input.IsButtonTriggered(Keyboard.KEY_RIGHT_SHIFT, player.ControllerIndex) or
	Input.IsButtonTriggered(Keyboard.KEY_RIGHT_CONTROL, player.ControllerIndex) or
	Input.IsActionTriggered(ButtonAction.ACTION_DROP, player.ControllerIndex)  
	
	return emotionChange
end

---@param player EntityPlayer
---@param changeEmotion boolean?
---@param SetEmotionCounter boolean?
function OmoriMod:TriggerHBParams(player, changeEmotion, SetEmotionCounter)
    changeEmotion = changeEmotion or false
    SetEmotionCounter = SetEmotionCounter or false
    local emotion = OmoriMod.GetEmotion(player)
    local playerData = OmoriMod.GetData(player) 

	if playerData.HeadButt == false then return end

    playerData.HeadButtCounter = HBParams[emotion].HeadButtCooldown or HBParams["Neutral"].HeadButtCooldown
    playerData.FixedDir = nil

    if SetEmotionCounter == true then
        playerData.EmotionCounter = HBParams[emotion].EmotionCooldown or HBParams["Neutral"].EmotionCooldown
    end

    if changeEmotion == true then
        OmoriMod.SetEmotion(player, HBParams[emotion].Emotion)
        player:SetColor(misc.AngryColor, 8, -1, true, true)
    end

	game:ShakeScreen(10)
	player:SetMinDamageCooldown(60)
	playerData.HeadButt = false
end

---@param knife EntityEffect
---@return EntityPlayer
function OmoriMod:GetKnifeOwner(knife)
	return knife.SpawnerEntity:ToPlayer() ---@type EntityPlayer
end

local function AreOppositeMovingDirectionPressed(player)
	return (
		Input.IsActionPressed(ButtonAction.ACTION_RIGHT, player.ControllerIndex) and 
		Input.IsActionPressed(ButtonAction.ACTION_LEFT, player.ControllerIndex)
	) or
	(
		Input.IsActionPressed(ButtonAction.ACTION_UP, player.ControllerIndex) and
		Input.IsActionPressed(ButtonAction.ACTION_DOWN, player.ControllerIndex)
	)
end

---@param player EntityPlayer
function OmoriMod:InitHeadbutt(player)
    local playerData = OmoriMod.GetData(player)
	if playerData.HeadButt == true then return end

    sfx:Play(sounds.SOUND_HEADBUTT_START)

    playerData.HeadButt = true

	playerData.FixedDir = (OmoriMod:IsPlayerMoving(player, true) and not AreOppositeMovingDirectionPressed(player)) and player:GetMovementInput():Normalized() or (OmoriMod:IsPlayerShooting(player) and player:GetShootingInput()) or tables.DirectionToVector[player:GetHeadDirection()]

	if OmoriMod:IsPlayerMoving(player) and OmoriMod:IsPlayerShooting(player) then
		playerData.FixedDir = player:GetShootingInput():Normalized()
	end
    playerData.HeadButtDir = (playerData.FixedDir):Resized(12)

	if game:GetRoom():GetType() == RoomType.ROOM_DUNGEON then
		player.Velocity = playerData.FixedDir:Resized(30)
	end

	player:SetColor(misc.ReadyColor, 5, -1, true, true)
end

---I mean, just swings the knife, there's not much science here
---@param knife EntityEffect
function OmoriMod:InitKnifeSwing(knife)
	local sprite = knife:GetSprite() ---@type Sprite
	local knifeData = OmoriMod.GetData(knife)

	local type = knifeData.KnifeType
	
	if sprite:IsPlaying("Swing") then return end
	sprite:Play("Swing")

	Isaac.RunCallback(OmoriModCallbacks.KNIFE_SWING_TRIGGER, knife, type)
end	

---Sets `knife` hitbox size
---@param knife EntityEffect
---@param sizeMult number
function OmoriMod.SetKnifeSizeMult(knife, sizeMult)
	knife.SpriteScale = Vector.One * (sizeMult or 1)
end

---comment
---@param firedelay number
---@param val number
---@param IsMult boolean
---@return number
function OmoriMod.tearsUp(firedelay, val, IsMult)
    local currentTears = 30 / (firedelay + 1)
    local newTears = currentTears + val 
	if IsMult == true then
		newTears = currentTears * val
	end
    return math.max((30 / newTears) - 1, -0.75)
end

---comment
---@param range number
---@param val number
---@return number
function OmoriMod.rangeUp(range, val)
    local currentRange = range / 40.0
    local newRange = currentRange + val
    return math.max(1.0, newRange) * 40.0
end

---comment
---@param player EntityPlayer
---@return number
function OmoriMod.TearsPerSecond(player)
	return OmoriMod:Round(30 / (player.MaxFireDelay + 1), 2)
end

---@param tear EntityTear
function OmoriMod.DoHappyTear(tear)
	local player = OmoriMod.GetPlayerFromAttack(tear)
	if not player then return end

	local color = tear.Color

	local emotion = OmoriMod.GetEmotion(player)
	local isHappy = OmoriMod.When(emotion, tables.HappinessFailChance, nil)
	if not isHappy then return end

	local hasBirthright = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT)
	local isOmori = OmoriMod.IsOmori(player, false)

	local doubleHitChance = OmoriMod.randomNumber(1, 100, modrng)
	local birthrightDamageMult = (hasBirthright and isOmori) and 1.25 or 1
	local birthrightVelMult = (hasBirthright and isOmori) and 1.15 or 1

	local happyTier = {
		["Happy"] = {VelMult = 1, HappyChance = 25},
		["Ecstatic"] = {VelMult = 2, HappyChance = 38},
		["Manic"] = {VelMult = 3, HappyChance = 50},
	}

	local switch = OmoriMod.When(emotion, happyTier)
	local velChange = switch.VelMult
	local happyCritChance = switch.HappyChance

	if not player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
		tear.Velocity = tear.Velocity + (RandomVector() * velChange) * birthrightVelMult
	end

	if doubleHitChance <= (happyCritChance * birthrightDamageMult) + player.Luck then
		tear.CollisionDamage = tear.CollisionDamage * 2
		tear.Color = Color(0.8, 0.8, 0.8, 1, 255 / 255, 200 / 255, 100 / 255)
	else
		tear.Color = color
	end
end

local KnifeSprites = {
	[knifeType.SHINY_KNIFE] = "ShinyKnife",
	[knifeType.VIOLIN_BOW] = "ViolinBow",
	[knifeType.MR_PLANT_EGG] = "MrEggplant",
	[knifeType.NAIL_BAT] = "Nailbat",
}

---@param player EntityPlayer
---@param knife EntityEffect
---@param Type KnifeType
function OmoriMod:ReplaceKnifeSprite(player, knife, Type)
	local knifesprite = knife:GetSprite()	
	local knifeReplaceSprite = OmoriMod.When(Type, KnifeSprites, "ShinyKnife")

	if Type == knifeType.SHINY_KNIFE and player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) then
		knifeReplaceSprite = "RedKnife"
	end

	for i = 0, 1 do
		knifesprite:ReplaceSpritesheet(i, "gfx/effects/" .. knifeReplaceSprite .. ".png", true)
	end
end

--[[Perform a Switch/Case-like selection.  
    `value` is used to index `cases`.  
    When `value` is `nil`, returns `default`.  
    **Note:** Type inference on this function is decent, but not perfect.
    You might want to use things such as [casting](https://luals.github.io/wiki/annotations/#as)
    the returned value.
    ]]
---@generic In, Out, Default
---@param value?    In
---@param cases     { [In]: Out }
---@param default?  Default
---@return Out|Default
function OmoriMod.When(value, cases, default)
    return value and cases[value] or default
end

--[[Perform a Switch/Case-like selection, like @{edithMod.When}, but takes a
    table of functions and runs the found matching case to return its result.  
    `value` is used to index `cases`.
    When `value` is `nil`, returns `default`, or runs it and returns its value if
    it is a function.  
    **Note:** Type inference on this function is decent, but not perfect.
    You might want to use things such as [casting](https://luals.github.io/wiki/annotations/#as)
    the returned value.
    ]]
---@generic In, Out, Default
---@param value?    In
---@param cases     { [In]: fun(): Out }
---@param default?  fun(): Default
---@return Out|Default
function OmoriMod.WhenEval(value, cases, default)
    local f = OmoriMod.When(value, cases)
    local v = (f and f()) or (default and default())
    return v
end

---Brings an Omori mod's knife entity to the player
---@param player EntityPlayer
---@param Type KnifeType
function OmoriMod.GiveKnife(player, Type)
	local playerData = OmoriMod.GetData(player)

	if not playerData.KnifeData then
		playerData.KnifeData = {}
	end		
	
	if OmoriMod.GetKnife(player, Type) then return end

	local knifeData = playerData.KnifeData

	local knife = Isaac.Spawn(
		EntityType.ENTITY_EFFECT,
		OmoriMod.Enums.EffectVariant.EFFECT_SHINY_KNIFE,
		0,
		player.Position,
		Vector.Zero,
		player
	):ToEffect()

	local knifeTypes = {
		[knifeType.SHINY_KNIFE] = function() knifeData.ShinyKnife = knife end,
		[knifeType.VIOLIN_BOW] = function() knifeData.ViolinBow = knife end,
		[knifeType.MR_PLANT_EGG] = function() knifeData.MrPlantEgg = knife end,
		[knifeType.NAIL_BAT] = function() knifeData.BaseballBat = knife end,
	}

	if not knife then return end

	knife:AddEntityFlags(EntityFlag.FLAG_PERSISTENT)

	KnifeData = OmoriMod.GetData(knife)
	KnifeData.KnifeType = Type

	OmoriMod:ReplaceKnifeSprite(player, knife, Type)
	OmoriMod.When(Type, knifeTypes)()
end

---Returns a mod's Knife entity depending on its type
---@param player EntityPlayer
---@param type KnifeType
---@return EntityEffect
function OmoriMod.GetKnife(player, type)
	local playerData = OmoriMod.GetData(player)
	local knifeData = playerData.KnifeData

	local cases = {
		[knifeType.SHINY_KNIFE] = knifeData.ShinyKnife,
		[knifeType.VIOLIN_BOW] = knifeData.ViolinBow,
		[knifeType.MR_PLANT_EGG] = knifeData.MrPlantEgg,
		[knifeType.NAIL_BAT] = knifeData.BaseballBat,
	}

	return OmoriMod.When(type, cases)
end

---Removes mod's knife of given `type` from player
---@param player EntityPlayer
---@param type KnifeType
function OmoriMod.RemoveKnife(player, type)
	local playerData = OmoriMod.GetData(player)
	local knifeData = playerData.KnifeData

	if not knifeData then return end

	local knife = OmoriMod.GetKnife(player, type)

	if not knife then return end

	local cases = {
		[knifeType.SHINY_KNIFE] = function() knifeData.ShinyKnife:Remove(); knifeData.ShinyKnife = nil end,
		[knifeType.VIOLIN_BOW] = function() knifeData.ViolinBow:Remove(); knifeData.ViolinBow = nil end,
		[knifeType.MR_PLANT_EGG] = function() knifeData.MrPlantEgg:Remove(); knifeData.MrPlantEgg = nil end,
		[knifeType.NAIL_BAT] = function() knifeData.BaseballBat:Remove(); knifeData.BaseballBat = nil end,
	}

	OmoriMod.WhenEval(type, cases)
end

---@param player EntityPlayer
---@return Vector
function OmoriMod:GetAimingDirection(player)
    if player:HasCollectible(CollectibleType.COLLECTIBLE_MARKED) or
            player:HasCollectible(CollectibleType.COLLECTIBLE_ANALOG_STICK) or
            player:HasCollectible(CollectibleType.COLLECTIBLE_EYE_OF_THE_OCCULT) or
            player:HasCollectible(CollectibleType.COLLECTIBLE_EPIC_FETUS) or
            player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE)
    then
        return player:GetAimDirection()
    end
    return tables.DirectionToVector[player:GetFireDirection()]
end

---@param player EntityPlayer
---@param CheckInput? boolean
---@return boolean
function OmoriMod:IsPlayerShooting(player, CheckInput)
	CheckInput = CheckInput or false
	if CheckInput then
		return (
			Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, player.ControllerIndex) or
			Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, player.ControllerIndex) or
			Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, player.ControllerIndex) or
			Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, player.ControllerIndex) 
		)
	else
		local aim = OmoriMod:GetAimingDirection(player)
		return aim.X ~= 0 or aim.Y ~= 0
	end
end

---@param player EntityPlayer
---@return boolean
function OmoriMod:IsShootTriggered(player)
	return (
		Input.IsActionTriggered(ButtonAction.ACTION_SHOOTDOWN, player.ControllerIndex) or
		Input.IsActionTriggered(ButtonAction.ACTION_SHOOTLEFT, player.ControllerIndex) or
		Input.IsActionTriggered(ButtonAction.ACTION_SHOOTRIGHT, player.ControllerIndex) or
		Input.IsActionTriggered(ButtonAction.ACTION_SHOOTUP, player.ControllerIndex) 
	)
end

---@param player EntityPlayer
---@param CheckInput boolean?
---@return boolean
function OmoriMod:IsPlayerMoving(player, CheckInput)
	CheckInput = CheckInput or false
	if CheckInput then
		return (
			Input.IsActionPressed(ButtonAction.ACTION_DOWN, player.ControllerIndex) or
			Input.IsActionPressed(ButtonAction.ACTION_UP, player.ControllerIndex) or
			Input.IsActionPressed(ButtonAction.ACTION_LEFT, player.ControllerIndex) or
			Input.IsActionPressed(ButtonAction.ACTION_RIGHT, player.ControllerIndex) 
		)
	else
		local mov = player:GetMovementVector()
		return mov.X ~= 0 or mov.Y ~= 0
	end
end

local spriteRoot = "gfx/characters/costumes_"
local OmoriEmotionChange = {
	["Neutral"] = {suffix = "neutral", sound = sounds.SOUND_BACK_NEUTRAL},
	["Happy"] = {suffix = "happy", sound = sounds.SOUND_HAPPY_UPGRADE},
	["Ecstatic"] = {suffix = "ecstatic", sound = sounds.SOUND_HAPPY_UPGRADE_2},
	["Manic"] = {suffix = "manic", sound = sounds.SOUND_HAPPY_UPGRADE_3},
	["Sad"] = {suffix = "sad", sound = sounds.SOUND_SAD_UPGRADE},
	["Depressed"] = {suffix = "depressed", sound = sounds.SOUND_SAD_UPGRADE_2},
	["Miserable"] = {suffix = "miserable", sound = sounds.SOUND_SAD_UPGRADE_3},
	["Angry"] = {suffix = "angry", sound = sounds.SOUND_ANGRY_UPGRADE},
	["Enraged"] = {suffix = "enraged", sound = sounds.SOUND_ANGRY_UPGRADE_2},
	["Furious"] = {suffix = "furious", sound = sounds.SOUND_ANGRY_UPGRADE_3},
}

local characterFolder = {
	[players.PLAYER_OMORI] = "Omori/",
	[players.PLAYER_AUBREY] = "DW_Aubrey/",
	[players.PLAYER_AUBREY_B] = "RW_Aubrey/",
}

---Triggers all emotion SFX and VFX from `OmoriMod.SetEmotion()`, Is preferable to be used in tandem with that function but can be used alone if needed
---@param player EntityPlayer
---@param playSound? boolean
function OmoriMod:ChangeEmotionEffect(player, playSound)
	if OmoriMod.IsOmori(player, true) then return end

	playSound = playSound or false

	local emotion = OmoriMod.GetEmotion(player)
	local charFolderTarget = OmoriMod.When(player:GetPlayerType(), characterFolder)
	local emotionTable = OmoriMod.When(emotion, OmoriEmotionChange)
	local EmotionSuffix = emotionTable.suffix
	local EmotionSound = emotionTable.sound	
	local EmotionCostume = player:GetCostumeSpriteDescs()[3]

	if EmotionCostume then  
		local EmotionCostumeSprite = EmotionCostume:GetSprite()
		EmotionCostumeSprite:ReplaceSpritesheet(0, spriteRoot .. charFolderTarget .. EmotionSuffix .. ".png", true)
	end

	if player.FrameCount == 0 or playSound == false then return end
	sfx:Play(EmotionSound, 2, 0, false, 1, 0)
end

function OmoriMod:EmotionEffectCall()
	local players = PlayerManager.GetPlayers()
	for _, player in pairs(players) do
		local emotion = OmoriMod.GetEmotion(player)
		if not emotion then return end
		OmoriMod:ChangeEmotionEffect(player)
	end	
end
OmoriMod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, OmoriMod.EmotionEffectCall)

---@param flag1 integer
---@param flag2 integer
---@return boolean
function OmoriMod:isFlagInBitmask(flag1, flag2)
    return flag1 & flag2 > 0
end

---@param player EntityPlayer
---@param TearFlag TearFlags
function OmoriMod:playerHasTearFlag(player, TearFlag)
	return player.TearFlags == player.TearFlags | TearFlag
end

---@param player EntityPlayer
---@return boolean
function OmoriMod:IsKnifeUser(player)
	return player:HasCollectible(OmoriMod.Enums.CollectibleType.COLLECTIBLE_SHINY_KNIFE) or OmoriMod.IsAnyOmori(player)
end

local SunnyEmotionChange = {
	["Neutral"] = {suffix = "neutral", sound = sounds.SOUND_BACK_NEUTRAL, pitch = 1},
	["Afraid"] = {suffix = "afraid", sound = sounds.SOUND_OMORI_FEAR, pitch = 1},
	["StressedOut"] = {suffix = "stressedout", sound = sounds.SOUND_OMORI_FEAR, pitch = 0.8},
}
local sunnyEmotionSpriteRoot = "gfx/characters/costumes_Sunny/"
local sunnyBodyRoot = "gfx/characters/players/costume_omori_body2"
local sunnyHairRoot = "gfx/characters/players/costume_omori_head2"

---comment
---@param player EntityPlayer
function OmoriMod:SunnyChangeEmotionEffect(player)
	if not OmoriMod.IsOmori(player, true) then return end
	local emotion = OmoriMod.GetEmotion(player)
	local emotionTable = SunnyEmotionChange[emotion]
	local playerSprite = player:GetSprite()
	local Suffix = emotionTable.suffix
	local Sound = emotionTable.sound
	local Pitch = emotionTable.pitch
	local EmotionSpriteDesc = player:GetCostumeSpriteDescs()[3]
	local EmotionSprite = EmotionSpriteDesc:GetSprite()
	local color = emotion ~= "Neutral" and "_bw" or ""
	
	for i = 1, 2 do
		local SunnySpriteDesc = player:GetCostumeSpriteDescs()[i]
		local SunnySprite = SunnySpriteDesc:GetSprite()
		local path = (i == 1 and sunnyBodyRoot or sunnyHairRoot) .. color .. ".png"
		for j = 0, 1 do
			SunnySprite:ReplaceSpritesheet(j, path, true)
		end
	end

	EmotionSprite:ReplaceSpritesheet(0, sunnyEmotionSpriteRoot .. Suffix .. ".png", true)

	for i = 0, 14 do
		playerSprite:ReplaceSpritesheet(i, "gfx/characters/players/player_omori2" .. color .. ".png", true)
	end

	if player.FrameCount == 0 then return end
	sfx:Play(Sound, 1, 0, false, Pitch, 0)
end

local EmotionColor = {
	["Neutral"] = misc.NeutralColor,
	["Happy"] = misc.HappyColor,
	["Ecstatic"] = misc.HappyColor,
	["Manic"] = misc.HappyColor,
	["Sad"] = misc.SadColor,
	["Depressed"] = misc.SadColor,
	["Miserable"] = misc.SadColor,
	["Angry"] = misc.AngryColor,
	["Enraged"] = misc.AngryColor,
	["Furious"] = misc.AngryColor,
	["Afraid"] = misc.NeutralColor,
	["StressedOut"] = misc.StressColor,
}

---@param player EntityPlayer
function OmoriMod.AddEmotionGlow(player)
	local playerData = OmoriMod.GetData(player)
	local emotionGlow = playerData.EmotionGlow
	
	if OmoriMod.GetEmotion(player) == nil then return end
	if emotionGlow then return end

	playerData.EmotionGlow = Isaac.Spawn(
		EntityType.ENTITY_EFFECT, 
		OmoriMod.Enums.EffectVariant.EFFECT_EMOTION_GLOW, 
		0, 
		player.Position, 
		Vector.Zero, 
		player
	):ToEffect()
	playerData.EmotionGlow.DepthOffset = -10
	playerData.EmotionGlow:FollowParent(player)

	playerData.EmotionGlow:AddEntityFlags(EntityFlag.FLAG_PERSISTENT)
	OmoriMod.ReplaceGlowSprite(player, playerData.EmotionGlow)
end

--- Changes player's Emotion
--- @param player EntityPlayer
--- @param emotion string
function OmoriMod.SetEmotion(player, emotion)
	local playerData = OmoriMod.GetData(player)
	if type(emotion) ~= "string" then return end
	
	playerData.PlayerEmotion = emotion

	OmoriMod:ChangeEmotionEffect(player)
	OmoriMod:SunnyChangeEmotionEffect(player)

	local AffectedFlags = CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_SPEED | CacheFlag.CACHE_FIREDELAY | CacheFlag.CACHE_LUCK ---@type CacheFlag|integer
	player:AddCacheFlags(AffectedFlags, true)

	OmoriMod.ReplaceGlowSprite(player, playerData.EmotionGlow)

	Isaac.RunCallback(OmoriModCallbacks.EMOTION_CHANGE_TRIGGER, player, emotion)

	if player.FrameCount == 0 then return end
	player:SetColor(EmotionColor[emotion], 8, -1, true, true)
end

---@param player EntityPlayer
---@return string
function OmoriMod.GetEmotion(player)
	local playerData = OmoriMod.GetData(player)
	return playerData.PlayerEmotion 
end

local LINE_SPRITE = Sprite("gfx/1000.021_tiny bug.anm2", true)
LINE_SPRITE:SetFrame("Dead", 0)

local MAX_POINTS = 32
local ANGLE_SEPARATION = 360 / MAX_POINTS

---@param entity Entity
---@param AreaSize number
function RenderAreaOfEffect(entity, AreaSize)
	local hitboxPosition = entity.Position
	local renderPosition = Isaac.WorldToScreen(hitboxPosition) - Game().ScreenShakeOffset
	local offset = Isaac.WorldToScreen(hitboxPosition + Vector(0, AreaSize)) - renderPosition + Vector(0, 1)
	local segmentSize = offset:Distance(offset:Rotated(ANGLE_SEPARATION))
	LINE_SPRITE.Scale = Vector(segmentSize * 2 / 3, 0.5)
	
	for i = 1, MAX_POINTS do
		local angle = ANGLE_SEPARATION * i
		LINE_SPRITE.Rotation = angle
		LINE_SPRITE.Offset = offset:Rotated(angle)
		LINE_SPRITE:Render(renderPosition)
	end
end

---@param x number
---@return Vector
function OmoriMod.MakeVector(x)
	return Vector(math.cos(math.rad(x)),math.sin(math.rad(x)))
end

local ResetColor = Color(1, 1, 1, 1, 0.6, 0.6, 0.6)
---@param player EntityPlayer
---@param healAmount integer
---@param focus? boolean
function OmoriMod:ResetSunnyEmotion(player, healAmount, focus)
	if not OmoriMod.IsOmori(player, true) then return end
	local playerData = OmoriMod.GetData(player)

	focus = focus or false

	OmoriMod.SetEmotion(player, "Neutral")
				
	playerData.AfraidCounter = 90
	playerData.StressCounter = 150
	playerData.TriggerAfraid = false
	playerData.TriggerStress = false
	player:AddHearts(healAmount)
	
	player:SetColor(ResetColor, 8, -1, true, true)
	playerData.IncreasedBowDamage = focus
end

---
---@param entity Entity
---@return EntityPlayer?
function OmoriMod.GetPlayerFromAttack(entity)
	for i=1, 3 do
		local check = nil
		if i == 1 then
			check = entity.Parent
		elseif i == 2 then
			check = entity.SpawnerEntity
		end
		if check then
			if check.Type == EntityType.ENTITY_PLAYER then
				return OmoriMod.GetPtrHashEntity(check):ToPlayer()
			elseif check.Type == EntityType.ENTITY_FAMILIAR and check.Variant == FamiliarVariant.INCUBUS
			
			then
				local data = OmoriMod.GetData(entity)
				data.IsIncubusTear = true
				return check:ToFamiliar().Player:ToPlayer()
			end
		end
	end
	return nil
end

local GlowRoot = "gfx/effects/glow_"
local emotionGlow = {
	["Neutral"] = "Neutral",
	["Happy"] = "Happy",
	["Ecstatic"] = "Happy",
	["Manic"] = "Happy",
	["Sad"] = "Sad",
	["Depressed"] = "Sad",
	["Miserable"] = "Sad",
	["Angry"] = "Angry",
	["Enraged"] = "Angry",
	["Furious"] = "Angry",
	["Afraid"] = "Afraid",
	["StressedOut"] = "StressedOut",
}

---@param player EntityPlayer
---@param effect EntityEffect
function OmoriMod.ReplaceGlowSprite(player, effect)
	if not effect then return end

	local glowSprite = effect:GetSprite()
	local emotion = OmoriMod.GetEmotion(player)
	local Glow = emotionGlow[emotion] 
	glowSprite:ReplaceSpritesheet(0, GlowRoot .. Glow .. ".png", true)
end

---Triggers a push from
---@param pushed Entity
---@param pusher Entity
---@param strength number
---@param duration integer
---@param impactDamage boolean
function OmoriMod.TriggerPush(pushed, pusher, strength, duration, impactDamage)
	local dir = ((pusher.Position - pushed.Position) * -1):Resized(strength)
	pushed:AddKnockback(EntityRef(pusher), dir, duration, impactDamage)
end

---@param player EntityPlayer
---@param emotionTable table
---@param DefaultEmotion string
---@param Tier2Emotion string
---@param Tier3Emotion string
function OmoriMod.EmotionUpdateItem(player, emotionTable, DefaultEmotion ,Tier2Emotion, Tier3Emotion)
    local emotion = OmoriMod.GetEmotion(player)

    if not emotion then OmoriMod.SetEmotion(player, "Neutral") end

    local newEmotion = OmoriMod.When(emotion, emotionTable, DefaultEmotion)
    local maxEmotion = OmoriMod.IsOmori(player, false) and Tier3Emotion or Tier2Emotion
    if emotion == maxEmotion then return end

    OmoriMod.SetEmotion(player, newEmotion)
    OmoriMod:ChangeEmotionEffect(player, true)
end

-----------------------------------
--Helper Functions (thanks piber)--
-----------------------------------

---@param entity Entity
function OmoriMod.GetPtrHashEntity(entity)
	for _, matchEntity in pairs(Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, false)) do
		if GetPtrHash(entity) == GetPtrHash(matchEntity) then
			return matchEntity
		end
	end
end

---comment
---@param entity Entity
---@return table
function OmoriMod.GetData(entity)
	local data = entity:GetData()
	data.OmoriMod = data.OmoriMod or {}
	return data.OmoriMod
end