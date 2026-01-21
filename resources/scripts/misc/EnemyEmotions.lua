local SEL = StatusEffectLibrary
local mod = OmoriMod
local EmotionElement = mod.Enums.EmotionElement
local emotions = {
    ["Happy"] = {
        ID = "_HAPPY",
        Sprite = Sprite("gfx/EmotionTitle.anm2", true),
        Color = Color(1, 1, 1, 1, 0.6, 0.54, 0.03)
    },
    ["Sad"] = {
        ID = "_SAD",
        Sprite = Sprite("gfx/EmotionTitle.anm2", true),
        Color = Color(0.63, 0.63, 0.63, 1, 0.03, 0, 0.4)
    },
    ["Angry"] = {
        ID = "_ANGRY",
        Sprite = Sprite("gfx/EmotionTitle.anm2", true),
        Color = Color(1, 0.87, 0.73, 1, 0.5)
    },
}

for k, v in pairs(emotions) do
    v.Sprite:Play(k)
    v.Sprite.Offset = Vector(0, -15)
    SEL.RegisterStatusEffect("OMORI_ENEMY_EMOTION" .. v.ID, v.Sprite, v.Color)
end

local flags = SEL.StatusFlag

local emotionFlags = {
    HAPPY = flags.OMORI_ENEMY_EMOTION_HAPPY,
    SAD = flags.OMORI_ENEMY_EMOTION_SAD,
    ANGRY = flags.OMORI_ENEMY_EMOTION_ANGRY,
}

local EmotionEnemyRNG = {
    EmotionInitSet = RNG(),
    HappyEnemy = RNG(),
    SadEnemy = RNG(),
}

local function OnGameStart()
    local seed = mod.Enums.Utils.Game:GetSeeds():GetStartSeed()

    for k, v in pairs(EmotionEnemyRNG) do
        v:SetSeed(seed)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, OnGameStart)

local Emotions = {
    [1] = emotionFlags.ANGRY,
    [2] = emotionFlags.SAD,
    [3] = emotionFlags.HAPPY,
}

local function OnEnemyInit(_, npc)
    local initRNG = EmotionEnemyRNG.EmotionInitSet
    if not mod.RandomBoolean(initRNG, 0.1) then return end
    local setEmotionRoll = initRNG:RandomInt(1, 3)

    -- SEL:AddStatusEffect(npc, Emotions[3], -1, EntityRef(npc))
end
mod:AddCallback(ModCallbacks.MC_POST_NPC_INIT, OnEnemyInit)

---@param npc EntityNPC 
---@return boolean
function OmoriMod:EnemyHasEmotion(npc)
    if not mod:IsEnemy(npc) then return false end

    return (SEL:HasStatusEffect(npc, emotionFlags.HAPPY) or SEL:HasStatusEffect(npc, emotionFlags.SAD) or SEL:HasStatusEffect(npc, emotionFlags.ANGRY))
end

---@param npc EntityNPC
---@param emotion integer
---@return boolean
function OmoriMod:EnemyHasEmotionFilter(npc, emotion)
    return SEL:HasStatusEffect(npc, emotion)
end

local DDFlag = false
---@param player EntityPlayer
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param cooldown integer
local function TriggerAngryEnemyDoubleDamage(_, player, amount, flags, source, cooldown)
    local enemy = source.Entity:ToNPC()

    if not enemy then return end
    if not mod:IsEnemy(enemy) then return end
    if not mod:EnemyHasEmotionFilter(enemy, emotionFlags.ANGRY) then return end

    if DDFlag == false then
        DDFlag = true
        player:TakeDamage(amount * 2, flags, source, cooldown)
        return false
    end

	DDFlag = false
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, TriggerAngryEnemyDoubleDamage)

---@param npc EntityNPC
---@param player EntityPlayer
local function OnKillingAngryEnemy(npc, player)
    if not mod:EnemyHasEmotionFilter(npc, emotionFlags.ANGRY) then return end

    StatConfigs = {
        Amount = 5,
        Duration = 90,
        Stat = CacheFlag.CACHE_DAMAGE,
        Identifier = "'mierdamierdamierda"

    } --[[@as TempStatConfig]]

    if not player then return end
    include("resources.scripts.misc.TempStatsLib")(function(player)
        return mod.saveManager.GetRunSave(player)
    end)

    TempStatLib:AddTempStat(player, StatConfigs)
end

---@param npc EntityNPC
---@param player EntityPlayer
local function OnKillingSadEnemy(npc, player)
    if not mod:EnemyHasEmotionFilter(npc, emotionFlags.SAD) then return end
    if not mod.RandomBoolean(EmotionEnemyRNG.SadEnemy, 0.2) then return end

    player:AddActiveCharge(1, ActiveSlot.SLOT_PRIMARY, true, true, true)
end

local PickupSpawn = {
	[1] = PickupVariant.PICKUP_HEART,
	[2] = PickupVariant.PICKUP_COIN,
	[3] = PickupVariant.PICKUP_KEY,
	[4] = PickupVariant.PICKUP_BOMB
}

---@param npc EntityNPC
local function OnKillingHappyEnemy(npc)
    if not mod:EnemyHasEmotionFilter(npc, emotionFlags.HAPPY) then return end
    if not mod.RandomBoolean(EmotionEnemyRNG.HappyEnemy, 0.5) then return end

    local pickupToSpawn = mod.When(OmoriMod.randomNumber(1, 4, EmotionEnemyRNG.HappyEnemy), PickupSpawn, 1)

	Isaac.Spawn(
		EntityType.ENTITY_PICKUP,
		pickupToSpawn,
		0,
		npc.Position,
		Vector.Zero,
		nil
	)
end

local function EmotionEnemyKillManager(_, npc, source)
    local player = mod.GetPlayerFromRef(source)
    if not player then return end

    OnKillingAngryEnemy(npc, player)
    OnKillingSadEnemy(npc, player)
    OnKillingHappyEnemy(npc)
end
mod:AddCallback(PRE_NPC_KILL.ID, EmotionEnemyKillManager)

local EmotionFlagToString = {
    [emotionFlags.HAPPY] = "Happy",
    [emotionFlags.SAD] = "Sad",
    [emotionFlags.ANGRY] = "Angry",
}

---@param npc EntityNPC
local function OnEnemyUpdate(_, npc)
    mod.GetData(npc).EnemyEmotion = (
        SEL:HasStatusEffect(npc, emotionFlags.HAPPY) and "Happy" or
        SEL:HasStatusEffect(npc, emotionFlags.SAD) and "Sad" or
        SEL:HasStatusEffect(npc, emotionFlags.ANGRY) and "Angry"
    )

    local velMult = (
        (mod:EnemyHasEmotionFilter(npc, emotionFlags.SAD) and 0.8) or
        (mod:EnemyHasEmotionFilter(npc, emotionFlags.HAPPY) and 1.1))

        if not velMult then return end

    npc.Velocity = npc.Velocity * velMult
end
mod:AddCallback(ModCallbacks.MC_NPC_UPDATE, OnEnemyUpdate)



---@param ent Entity
---@param effect integer
local function OnEnemyEmotionAssignement(_, ent, effect)
    
end
mod:AddCallback(mod, OnEnemyEmotionAssignement)

---@param ent Entity
---@return string
local function GetEnemyEmotion(ent)
    return mod.GetData(ent).EnemyEmotion
end

--[[
    - Cuando un enemigo con emoción recibe daño de un jugador con emoción:
        - Si la emoción del jugador es más fuerte, recibe daño extra
        - Si la emoción del jugador es más débil, recibe daño reducido
        - Para mantener las cosas simples, el ajuste de daño será el mismo independientemente de la potencia de emoción
            Fuerte: x1.5
            Débil: x0.5

    - Cuando un jugador con emoción recibe daño de un enemigo con emoción:
        - El mejor approach que se me ocurre es modificar los i-frames al recibir daño:
        - Como los enemigos sólo pueden tener la primer fase de emoción:
            - Fuerte: División sobre 1.5
            - Débil: División sobre 0.8
]]

local weakStrongEmotions = {
    Player = {
        [EmotionElement.HAPPINESS] = {
            Weak = "Sad", -- A qué emoción es más suceptible
            Strong = "Angry", -- A qué emoción le hace más daño
        },
        [EmotionElement.SADNESS] = {
            Weak = "Angry", -- A qué emoción es más suceptible
            Strong = "Happy", -- A qué emoción le hace más daño
        },
        [EmotionElement.ANGER] = {
            Weak = "Happy", -- A qué emoción es más suceptible
            Strong = "Sad", -- A qué emoción le hace más daño
        }
    },
    Enemy = {
        ["Happy"] = {
            Weak = EmotionElement.SADNESS, -- A qué emoción es más suceptible
            Strong = EmotionElement.ANGER, -- A qué emoción le hace más daño
        },
        ["Sad"] = {
            Weak = EmotionElement.ANGER, -- A qué emoción es más suceptible
            Strong = EmotionElement.HAPPINESS, -- A qué emoción le hace más daño
        },
        ["Angry"] = {
            Weak = EmotionElement.HAPPINESS, -- A qué emoción es más suceptible
            Strong = EmotionElement.SADNESS, -- A qué emoción le hace más daño
        }
    },
}

local flag = false

---@param ref EntityRef
local function getNpcFromSource(ref)
    local ent = ref.Entity

    if ent and mod:IsEnemy(ent) then
        return ent:ToNPC()
    end
end


---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param cooldown integer
local function EmotionEnemyDamageManager(_, entity, amount, flags, source, cooldown)
    local player = mod.GetPlayerFromRef(source)

    if not player then return end
    if flag then return end
    if mod.GetEmotion(player) == "Neutral" then return end

    local EmotionElement = mod.GetEmotionElement(player)
    local tableRef = weakStrongEmotions.Player[EmotionElement]
    local StrongEmotion = tableRef and tableRef.Strong
    local WeakEmotion = tableRef and tableRef.Weak
    local EnemyEmotion = GetEnemyEmotion(entity)
    local Damage = amount

    if EnemyEmotion == StrongEmotion then
        Damage = Damage * 1.5
    elseif EnemyEmotion == WeakEmotion then
        Damage = Damage * 0.5
    end

    flag = true
    entity:TakeDamage(Damage, flags, source, cooldown)
    flag = false
    return false
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, EmotionEnemyDamageManager)

local postFlag = false

---@param entity Entity
---@param amount number
---@param flags DamageFlag
---@param source EntityRef
---@param cooldown integer
local function OnPlayerGettingDamage(_, entity, amount, flags, source, cooldown)
    local player = entity:ToPlayer()

    if not player then return end
    if mod.GetEmotion(player) == "Neutral" then return end
    if not source.Entity then return end
    if not mod:IsEnemy(source.Entity) then return end

    local damageCooldown = player:GetDamageCooldown() 
    local enemyEmotion = GetEnemyEmotion(source.Entity)
    local emotionData = mod.When(enemyEmotion, weakStrongEmotions.Enemy)
    local WeakEmotion = emotionData.Weak
    local StrongEmotion = emotionData.Strong
    local playerEmotionElement = mod.GetEmotionElement(player)

    if playerEmotionElement == StrongEmotion then
        damageCooldown = damageCooldown * 0.5
    elseif playerEmotionElement == WeakEmotion then
        damageCooldown = damageCooldown * 1.5
    end

    player:ResetDamageCooldown()
    player:SetMinDamageCooldown(damageCooldown)
end
mod:AddCallback(ModCallbacks.MC_POST_ENTITY_TAKE_DMG, OnPlayerGettingDamage)