local mod = OmoriMod
local enums = mod.Enums
local enemyRadius = 80
local costumes = enums.NullItemID
local utils = enums.Utils
local game = utils.Game
local misc = enums.Misc
local knifeType = enums.KnifeType

local emotions = {
    ["Neutral"] =  {
        Counter = "AfraidCounter",
        Color = misc.AfraidColor,
        Emotion = "Afraid",
    },
    ["Afraid"] = {
        Counter = "StressCounter",
        Color = misc.StressColor,
        Emotion = "StressedOut"
    },
}

local colorMods = {
    ["Afraid"] = misc.AfraidColorMod,
    ["StressedOut"] = misc.StressColorMod,
}

local swingSpeed = {
    ["Neutral"] = 1.25,
    ["Afraid"] = 1.375,
    ["StressedOut"] = 1.5
}
---@param player EntityPlayer
function mod:SunnyInit(player)
    if not mod.IsOmori(player, true) then return end

	local playerData = mod.GetData(player)
    
	playerData.AfraidCounter = playerData.AfraidCounter or 60
    playerData.StressCounter = playerData.StressCounter or 90
	
    player:AddNullCostume(costumes.ID_SUNNY)
    player:AddNullCostume(costumes.ID_EMOTION)

    mod.SetEmotion(player, "Neutral")
    mod.AddEmotionGlow(player)
    mod.GiveKnife(player, knifeType.VIOLIN_BOW)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.SunnyInit)

---@param player EntityPlayer
---@return boolean
local function AreEnemiesNearby(player)
    for _, enemy in ipairs(Isaac.FindInRadius(player.Position, enemyRadius, EntityPartition.ENEMY)) do
        if enemy:IsActiveEnemy() and enemy:IsVulnerableEnemy() then return true end
    end
    return false
end

---@param player EntityPlayer
function mod:SunnyStressingOut(player)
    if not mod.IsOmori(player, true) then return end

    local emotion = mod.GetEmotion(player)
    local emotionData = emotions[emotion]
    if not emotionData then return end

    local playerData = mod.GetData(player)
    local counter = emotionData.Counter
    local dataColor = emotionData.Color
    local dataCounter = playerData[counter]

    if emotionData and AreEnemiesNearby(player) and emotion ~= "StressedOut" then
        playerData[counter] = math.max(dataCounter - 1, 0)
    else
        playerData.AfraidCounter = 60
        playerData.StressCounter = 90
    end

    if dataCounter == 1 then
        mod.SetEmotion(player, emotionData.Emotion)
        playerData[counter] = 0
    end

    mod:TriggerPlayerFlash(player, dataCounter, dataColor, SoundEffect.SOUND_BEEP)
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.SunnyStressingOut)

---@param knife EntityEffect
function mod:OnSunnyBowUpdate(knife)
    local knifeData = mod:GetKnifeData(knife)
    local player = mod:GetKnifeOwner(knife)

    if not player then return end
    if not knifeData then return end

    knifeData.SwingSpeed = swingSpeed[mod.GetEmotion(player)]
end
mod:AddCallback(enums.Callbacks.POST_KNIFE_UPDATE, mod.OnSunnyBowUpdate)

function mod:UpdateSunnyColorModifier(player)
    if not mod.IsOmori(player, true) then return end  

    local emotion = mod.GetEmotion(player)
    local colorMod = colorMods[emotion]

    if not colorMod then return end

    game:SetColorModifier(colorMod, true, 0.3)
    Isaac.CreateTimer(function()
        game:GetRoom():UpdateColorModifier(true, true, 1000)
    end, 0, 1, false)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.UpdateSunnyColorModifier)