local mod = OmoriMod
local enums = mod.Enums
local tables = enums.Tables
local costumes = enums.NullItemID
local callbacks = enums.Callbacks
local utils = enums.Utils
local game = utils.Game
local sfx = utils.SFX
local sounds = enums.SoundEffect
local misc = enums.Misc
local knifeType = enums.KnifeType

---comment
---@param player EntityPlayer
function mod:InitFarawayAubrey(player)
    if not mod.IsAubrey(player, true) then return end

    local playerData = mod.GetData(player)
    
    player:AddNullCostume(costumes.ID_RW_AUBREY)
    player:AddNullCostume(costumes.ID_EMOTION)

    playerData.HeadButtCooldown = mod:SecsToFrames(4)
    playerData.EmotionCounter = mod:SecsToFrames(6)
    playerData.HeadButt = false

    mod.SetEmotion(player, "Neutral")
    mod.AddEmotionGlow(player)

    mod.GiveKnife(player, knifeType.NAIL_BAT)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.InitFarawayAubrey)

---comment
---@param player EntityPlayer
function mod:FarawayAubreyUpdate(player)
    if not mod.IsAubrey(player, true) then return end
    if not player:CollidesWithGrid() then return end
    mod:TriggerHBParams(player)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.FarawayAubreyUpdate)

---comment
---@param knife EntityEffect
---@return number?
function mod:AubreyBatCharge(knife)
    local player = knife.SpawnerEntity:ToPlayer()
    if not player then return end
    if not mod.IsAubrey(player, true) then return end

    local batCharge = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 1.5 or 2
    return mod:SecsToKnifeCharge(batCharge)
end
mod:AddCallback(callbacks.PRE_KNIFE_CHARGE, mod.AubreyBatCharge)

local emotionToSet = {
    ["Neutral"] = "Angry",
    ["Angry"] = "Enraged"
}

local function thereAreEnemies()
    local bool = false
    for _, entity in ipairs(Isaac.GetRoomEntities()) do
        if entity:IsActiveEnemy() and entity:IsVulnerableEnemy() then
            bool = true
        end
    end
    return bool
end

---@param player EntityPlayer
function mod:FarawayAubreyEffectUpdate(player)
    if not OmoriMod.IsAubrey(player, true) then return end

    local emotion = OmoriMod.GetEmotion(player)
    local playerData = OmoriMod.GetData(player)
    local room = game:GetRoom()
    local emotionCounterMax = player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) and 5 or 6

    if (room:IsClear() or room:HasCurseMist() or thereAreEnemies() == false) then
        playerData.EmotionCounter = OmoriMod:SecsToFrames(emotionCounterMax)
        playerData.HeadButtCooldown = OmoriMod:SecsToFrames(4)
        return 
    end
    
    if emotion == "Angry" or emotion == "Enraged" then
        playerData.HeadButtCooldown = math.max(playerData.HeadButtCooldown - 1, 0)

        if playerData.HeadButtCooldown == 0 then
            OmoriMod:InitHeadbutt(player)
            playerData.HeadButtCooldown = OmoriMod:SecsToFrames(4)
        end

        if playerData.HeadButtCooldown <= 30 and playerData.HeadButtCooldown > 0 and playerData.HeadButtCooldown % 10 == 0 then
            player:SetColor(misc.ReadyColor, 5, -1, true, true)
            sfx:Play(sounds.SOUND_HEADBUTT_START)
        end
    end

    if emotion ~= "Enraged" then
        playerData.EmotionCounter = math.max(playerData.EmotionCounter - 1, 0)
        if playerData.EmotionCounter == 0 then
            playerData.EmotionCounter = OmoriMod:SecsToFrames(emotionCounterMax)
            OmoriMod.SetEmotion(player, emotionToSet[emotion] or "Angry")
        end

        if playerData.EmotionCounter <= 30 and playerData.EmotionCounter > 0 and playerData.EmotionCounter % 10 == 0 then
            player:SetColor(misc.AngryColor, 5, -1, true, true)
            sfx:Play(SoundEffect.SOUND_BEEP)
        end
    end
    if room:GetType() ~= RoomType.ROOM_DUNGEON then
        if playerData.HeadButt == true then
            player.Velocity = playerData.HeadButtDir
        end
    else
        if OmoriMod:GetAceleration(player) < 1 then
            if playerData.HeadButt == true then
                playerData.HeadButt = false
            end
        end
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.FarawayAubreyEffectUpdate)

---@param player EntityPlayer
function mod:FarawayAubreyHeadbuttHit(player)
    mod.SetEmotion(player, "Neutral")
end
mod:AddCallback(callbacks.HEADBUTT_ENEMY_HIT, mod.FarawayAubreyHeadbuttHit)

function mod:NullFarawayHeadbuttDamage(entity)
    local player = entity:ToPlayer()    

    if not player then return end
    if not OmoriMod.IsAubrey(player, true) then return end

    local playerData = OmoriMod.GetData(player)
    
    if playerData.HeadButt == true then return false end
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_TAKE_DMG, mod.NullFarawayHeadbuttDamage)