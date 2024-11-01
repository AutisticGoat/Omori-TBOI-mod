local game = Game()
local modrng = RNG()
local sfx = SFXManager()

function OmoriMod.GetScreenCenter()
	local room = game:GetRoom()
	local pos = room:WorldToScreenPosition(Vector(0,0)) - room:GetRenderScrollOffset() - game.ScreenShakeOffset	
	local rx = pos.X + 60 * 26 / 40
	local ry = pos.Y + 140 * (26 / 40)
			
	return Vector(rx*2 + 13*26, ry*2 + 7*26) / 2
end 

function OmoriMod:Round(number, decimalPlaces)
	decimalPlaces = decimalPlaces or 0
	local mult = 10^(decimalPlaces)
	return math.floor(number * mult + 0.5) / mult
end

function OmoriMod:ExponentialFunction(number, coeffcient, power)
	if number ~= 0 then
		local xp = (coeffcient * number ^ power)/number
		return xp
	end
	return 0
end

function OmoriMod:GetAceleration(entity)
	local VelX = math.abs(entity.Velocity.X)
	local VelY = math.abs(entity.Velocity.Y)
	
	local acel = VelX + VelY
	
	return OmoriMod:Round(acel, 2)
end

function OmoriMod.SwitchCase(value, tables)
	if tables[value] then
        if type(tables[value]) == "function" then
            return tables[value]()
        else
            return tables[value]
        end
    end
    if tables["_"] then
        if type(tables["_"]) == "function" then
            return tables["_"]()
        else
            return tables["_"]
        end
    end
    return nil
end

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

function OmoriMod.tearsUp(firedelay, val, IsMult)
    local currentTears = 30 / (firedelay + 1)
    local newTears = currentTears + val
	if IsMult == true then
		newTears = currentTears * val
	end
    return math.max((30 / newTears) - 1, -0.75)
end

function OmoriMod.rangeUp(range, val)
    local currentRange = range / 40.0
    local newRange = currentRange + val
    return math.max(1.0, newRange) * 40.0
end

function OmoriMod.TearsPerSecond(player)
	return OmoriMod:Round(30 / (player.MaxFireDelay + 1), 2)
end

function OmoriMod.GetEmotion(player)
	local playerData = OmoriMod:GetData(player)
	local returnEmotion

	if player:GetPlayerType() == OmoriMod.Enums.PlayerType.PLAYER_OMORI then
		returnEmotion = playerData.OmoriCurrentEmotion 
	elseif player:GetPlayerType() == OmoriMod.Enums.PlayerType.PLAYER_OMORI_B then	
		returnEmotion = playerData.SunnyCurrentEmotion 
	else
		returnEmotion = playerData.PlayerEmotion 
	end
	
	return returnEmotion
end

function OmoriMod.DoHappyTear(tear)
	local player = OmoriMod.GetPlayerFromAttack(tear)
	local HappyTearChance = 0
	local HappyTearVelChange = 0
	local doubleHitChance = OmoriMod.randomNumber(1, 100, modrng)
	
	local birthrightDamageMult = 1
	local birthrightVelMult = 1
	
	if player:GetPlayerType() == OmoriMod.Enums.PlayerType.PLAYER_OMORI and player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
		birthrightDamageMult = 1.25
		birthrightVelMult = 1.15
	end
	
	local happyTier = {
		["Happy"] = function()
			HappyTearVelChange = 1
			HappyTearChance = 25
		end,
		["Ecstatic"] = function()
			HappyTearVelChange = 2
			HappyTearChance = 38
		end,
		["Manic"] = function()
			HappyTearVelChange = 3
			HappyTearChance = 50
		end,
	}
	local variable = OmoriMod.SwitchCase(OmoriMod.GetEmotion(player), happyTier)
	

	local newVec = {
		X = OmoriMod.randomfloat(-HappyTearVelChange, HappyTearVelChange, modrng) * birthrightVelMult,
		Y = OmoriMod.randomfloat(-HappyTearVelChange, HappyTearVelChange, modrng) * birthrightVelMult,
	}

	if HappyTearVelChange ~= 0 then
		if not player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
			tear.Velocity = tear.Velocity + Vector(newVec.X, newVec.Y)
		end
		
		if doubleHitChance <= (HappyTearChance * birthrightDamageMult) + player.Luck then
			tear.CollisionDamage = tear.CollisionDamage * 2
			tear.Color = Color(0.8, 0.8, 0.8, 1, 255/255, 200/255, 100/255)
		else
			tear.Color = Color.Default
		end
	end
end

function OmoriMod:IsShinyKnife(entity, rotation)
	return entity.Type == EntityType.ENTITY_EFFECT and entity.Variant == OmoriMod.Enums.EffectVariant.EFFECT_SHINY_KNIFE
end

function OmoriMod:GiveKnife(player, rotation)
	local playerData = OmoriMod:GetData(player)
	if OmoriMod:IsKnifeUser(player) then
        if playerData.GivenKnife ~= true then
            local knife =
                Isaac.Spawn(
                EntityType.ENTITY_EFFECT,
                OmoriMod.Enums.EffectVariant.EFFECT_SHINY_KNIFE,
                0,
                player.Position,
                Vector.Zero,
                player
            ):ToEffect()	
			local knifesprite = knife:GetSprite()
			
			OmoriMod:replaceKnifeSprite(player, knife)
			
			knifesprite.Rotation = rotation

			if player:GetHeadDirection() == 0 or player:GetHeadDirection() == 1 or knifesprite:IsPlaying("Swing") or player:IsHoldingItem() == true then
				knife.DepthOffset = -10
			else
				knife.DepthOffset = 1
			end
            playerData.GivenKnife = true
        end
    end
end

function OmoriMod:OmoriChangeEmotionEffect(player, playSound)
	playSound = playSound or false
	local newEmotion = ""
	local EmotionSoundEffect 
	local spriteRoot = "gfx/characters/costumes_Omori/"
	
	if player:GetPlayerType() ~= OmoriMod.Enums.PlayerType.PLAYER_OMORI then
		return
	end
		
	local changeEmotionBirthright = {
		["Neutral"] = function()
			newEmotion = "neutral"
			EmotionSoundEffect = OmoriMod.Enums.SoundEffect.SOUND_BACK_NEUTRAL
		end,
		["Happy"] = function()
			newEmotion = "happy"
			EmotionSoundEffect = OmoriMod.Enums.SoundEffect.SOUND_HAPPY_UPGRADE
		end,
		["Ecstatic"] = function()
			newEmotion = "ecstatic"
			EmotionSoundEffect = OmoriMod.Enums.SoundEffect.SOUND_HAPPY_UPGRADE_2
		end,
		["Manic"] = function()
			newEmotion = "manic"
			EmotionSoundEffect = OmoriMod.Enums.SoundEffect.SOUND_HAPPY_UPGRADE_3
		end,
		["Sad"] = function()
			newEmotion = "sad"
			EmotionSoundEffect = OmoriMod.Enums.SoundEffect.SOUND_SAD_UPGRADE
		end,
		["Depressed"] = function()
			newEmotion = "depressed"
			EmotionSoundEffect = OmoriMod.Enums.SoundEffect.SOUND_SAD_UPGRADE_2
		end,
		["Miserable"] = function()
			newEmotion = "miserable"
			EmotionSoundEffect = OmoriMod.Enums.SoundEffect.SOUND_SAD_UPGRADE_3
		end,
		["Angry"] = function()
			newEmotion = "angry"
			EmotionSoundEffect = OmoriMod.Enums.SoundEffect.SOUND_ANGRY_UPGRADE
		end,
		["Enraged"] = function()
			newEmotion = "enraged"
			EmotionSoundEffect = OmoriMod.Enums.SoundEffect.SOUND_ANGRY_UPGRADE_2
		end,
		["Furious"] = function()
			newEmotion = "furious"
			EmotionSoundEffect = OmoriMod.Enums.SoundEffect.SOUND_ANGRY_UPGRADE_3
		end,
	}
	OmoriMod.SwitchCase(OmoriMod.GetEmotion(player), changeEmotionBirthright)
		
	player:AddNullCostume(OmoriMod.Enums.NullItemID.ID_OMORI_EMOTION)
	
	local EmotionCostume = player:GetCostumeSpriteDescs()[3]
	
	if EmotionCostume == nil then return end
	
	local EmotionCostumeSprite = EmotionCostume:GetSprite()

	EmotionCostumeSprite:ReplaceSpritesheet(0, spriteRoot .. newEmotion .. ".png", true)
		
	if EmotionSoundEffect ~= nil and playSound == true then
		sfx:Play(EmotionSoundEffect, 2, 0, false, pitch, 0)
	end
end

function OmoriMod:playerHasTearFlag(player, TearFlag)
	return player.TearFlags == player.TearFlags | TearFlag
end

function OmoriMod:IsKnifeUser(player)
	return 
	player:HasCollectible(OmoriMod.Enums.CollectibleType.COLLECTIBLE_SHINY_KNIFE) or player:GetPlayerType() == OmoriMod.Enums.PlayerType.PLAYER_OMORI or 
	player:GetPlayerType() == OmoriMod.Enums.PlayerType.PLAYER_OMORI_B

end

function OmoriMod:SunnyChangeEmotionEffect(player, playSound)
	playSound = playSound or false
	local color = "" 
	local playerSprite = player:GetSprite()
	local pitch = 1
	
	local emotionCostume = ""
	local emotionspriteRoot = "gfx/characters/costumes_Sunny/"
	
	if player:GetPlayerType() ~= OmoriMod.Enums.PlayerType.PLAYER_OMORI_B then
		return
	end
	
	local changeEmotionBirthright = {
		["Neutral"] = function()
			emotionCostume = "neutral"
			EmotionSoundEffect = OmoriMod.Enums.SoundEffect.SOUND_BACK_NEUTRAL
			pitch = 1
		end,
		["Afraid"] = function()
			emotionCostume = "afraid_bw"
			EmotionSoundEffect = OmoriMod.Enums.SoundEffect.SOUND_OMORI_FEAR
			pitch = 1
		end,
		["StressedOut"] = function()
			emotionCostume = "stressedout_bw"
			EmotionSoundEffect = OmoriMod.Enums.SoundEffect.SOUND_OMORI_FEAR
			pitch = 0.8
		end, 
	}
		
	OmoriMod.SwitchCase(OmoriMod.GetEmotion(player), changeEmotionBirthright)
		
	player:AddNullCostume(OmoriMod.Enums.NullItemID.ID_SUNNY_EMOTION)
		
	if EmotionSoundEffect ~= nil and playSound == true then
		sfx:Play(EmotionSoundEffect, 2, 0, false, pitch, 0)
	end
		
	if OmoriMod.GetEmotion(player) ~= "Neutral" then
		color = "_bw"
	end
		
	local playerSpriteRoot = "gfx/characters/players/"
	local suffix = ""
		
	for i = 1, 3 do
		local costumeSpriteDesc = player:GetCostumeSpriteDescs()[i]
		local costumeSprite = costumeSpriteDesc:GetSprite()
			
		local iterator = {
			[1] = function()
				suffix = "costume_omori_body2"
				for i = 0, 1 do
					costumeSprite:ReplaceSpritesheet(i, playerSpriteRoot .. suffix .. color .. ".png", true)
				end
			end,
			[2] = function()
				suffix = "costume_omori_head2"
				for i = 0, 1 do
					costumeSprite:ReplaceSpritesheet(i, playerSpriteRoot .. suffix .. color .. ".png", true)
				end
			end,
			[3] = function()
				costumeSprite:ReplaceSpritesheet(0, emotionspriteRoot .. emotionCostume .. ".png", true)
			end	
		}
		OmoriMod.SwitchCase(i, iterator)
	end
		
	for i = 0, 14 do
		playerSprite:ReplaceSpritesheet(i, "gfx/characters/players/player_omori2" .. color .. ".png", true)
	end
end

function OmoriMod.SetEmotion(player, emotion, playSound)
	playSound = playSound or true

	local playerData = OmoriMod:GetData(player)
	if type(emotion) == "string" then
		if player:GetPlayerType() == OmoriMod.Enums.PlayerType.PLAYER_OMORI then
			playerData.OmoriCurrentEmotion = emotion
		elseif player:GetPlayerType() == OmoriMod.Enums.PlayerType.PLAYER_OMORI_B then	
			playerData.SunnyCurrentEmotion = emotion
		else
			playerData.PlayerEmotion = emotion
		end
		
		player:AddCacheFlags(CacheFlag.CACHE_DAMAGE | CacheFlag.CACHE_SPEED | CacheFlag.CACHE_FIREDELAY | CacheFlag.CACHE_LUCK, true)
	else
		return nil
	end
end

local LINE_SPRITE = Sprite()
LINE_SPRITE:Load("gfx/1000.021_tiny bug.anm2", true)
LINE_SPRITE:SetFrame("Dead", 0)

local MAX_POINTS = 32
local ANGLE_SEPARATION = 360 / MAX_POINTS

function RenderAreaOfEffect(entity, AreaSize) -- Took from Melee lib and tweaked a little bit
    local hitboxPosition = entity.Position
    local renderPosition = Isaac.WorldToScreen(hitboxPosition) - Game().ScreenShakeOffset
    local hitboxSize = AreaSize
    local offset = Isaac.WorldToScreen(hitboxPosition + Vector(0, hitboxSize)) - renderPosition + Vector(0, 1)
    local offset2 = offset:Rotated(ANGLE_SEPARATION)
    local segmentSize = offset:Distance(offset2)
    LINE_SPRITE.Scale = Vector(segmentSize * 2 / 3, 0.5)
    for i = 1, MAX_POINTS do
        local angle = ANGLE_SEPARATION * i
        LINE_SPRITE.Rotation = angle
        LINE_SPRITE.Offset = offset:Rotated(angle)
        LINE_SPRITE:Render(renderPosition)
    end
end

function OmoriMod.PlayerHasTearFlags(player, flag)
	return player.TearFlags == player.TearFlags | flag
end

function OmoriMod.MakeVector(x)
	return Vector(math.cos(math.rad(x)),math.sin(math.rad(x)))
end

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
				return OmoriMod:GetPtrHashEntity(check):ToPlayer()
			elseif check.Type == EntityType.ENTITY_FAMILIAR and check.Variant == FamiliarVariant.INCUBUS then
				local data = OmoriMod:GetData(entity)
				data.IsIncubusTear = true
				return check:ToFamiliar().Player:ToPlayer()
			end
		end
	end
	return nil
end

function OmoriMod:ReplaceGlowSprite(player, effect)
	local glowSprite = effect:GetSprite()
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
	local Glow = OmoriMod.SwitchCase(OmoriMod.GetEmotion(player), emotionGlow) or "Neutral"
	glowSprite:ReplaceSpritesheet(0, GlowRoot .. Glow .. ".png", true)
end


-----------------------------------
--Helper Functions (thanks piber)--
-----------------------------------

function OmoriMod:GetPlayers(ignoreCoopBabies)

	if ignoreCoopBabies == nil then
		ignoreCoopBabies = true
	end

	local players = {}

	for i = 0, Game():GetNumPlayers() - 1, 1 do
		local player = Game():GetPlayer(i)

		if not ignoreCoopBabies or player.Variant ~= 1 then
			table.insert(players, player)
		end
	end

	return players
	
end

function OmoriMod:GetPtrHashEntity(entity)
	if entity then
		if entity.Entity then
			entity = entity.Entity
		end
		for _, matchEntity in pairs(Isaac.FindByType(entity.Type, entity.Variant, entity.SubType, false, false)) do
			if GetPtrHash(entity) == GetPtrHash(matchEntity) then
				return matchEntity
			end
		end
	end
	return nil
end

---comment
---@param entity Entity
---@return table
function OmoriMod:GetData(entity)
	if entity and entity.GetData then
		local data = entity:GetData()
		if not data.OmoriMod then
			data.OmoriMod = {}
		end
		return data.OmoriMod
	end
	return nil
end

function OmoriMod:Contains(list, x)
	for _, v in pairs(list) do
		if v == x then return true end
	end
	return false
end

--ripairs stuff from revel
function ripairs_it(t,i)
	i=i-1
	local v=t[i]
	if v==nil then return v end
	return i,v
end
function ripairs(t)
	return ripairs_it, t, #t+1
end

--- Executes a function for each key-value pair of a table
function OmoriMod:ForEach(toIterate, funct)
	for index, value in pairs(toIterate) do
		funct(index, value)
	end
end

--filters a table given a predicate
function OmoriMod:Filter(toFilter, predicate)
	local filtered = {}

	for index, value in pairs(toFilter) do
		if predicate(index, value) then
			filtered[#filtered+1] = value
		end
	end

	return filtered
end

--returns a list of all players that have a certain item
function OmoriMod:GetPlayersByCollectible(collectibleId)
	local players = OmoriMod:GetPlayers()

	return OmoriMod:Filter(players, function(_, player)
		return player:HasCollectible(collectibleId)
	end)
end

--returns a list of all players that have a certain item effect (useful for actives)
function OmoriMod:GetPlayersWithCollectibleEffect(collectibleId)
	local players = OmoriMod:GetPlayers()

	return OmoriMod:Filter(players, function(_, player)
		return player:GetEffects():HasCollectibleEffect(collectibleId)
	end)
end