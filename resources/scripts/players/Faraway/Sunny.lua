local mod = OmoriMod
local enums = mod.Enums
local enemyRadius = 80
local costumes = enums.NullItemID
local utils = enums.Utils
local game = utils.Game
local misc = enums.Misc
local sfx = utils.SFX
local knifeType = enums.KnifeType

local funcs = {
    GiveKnife = mod.GiveKnife,
    GetEmotion = mod.GetEmotion,
}

---@param player EntityPlayer
function mod:SunnyInit(player)
    if not OmoriMod.IsOmori(player, true) then return end

	local playerData = OmoriMod.GetData(player)
    
	playerData.AfraidCounter = playerData.AfraidCounter or 90
    playerData.StressCounter = playerData.StressCounter or 150
	
    player:AddNullCostume(costumes.ID_SUNNY)
    player:AddNullCostume(costumes.ID_EMOTION)

    OmoriMod.SetEmotion(player, "Neutral")
    OmoriMod.AddEmotionGlow(player)

    OmoriMod.GiveKnife(player, knifeType.VIOLIN_BOW)

end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.SunnyInit)

---@param player EntityPlayer
---@return boolean
function mod:AreEnemiesNearby(player)
    local nearEnemies = Isaac.FindInRadius(player.Position, enemyRadius, EntityPartition.ENEMY)
    local Bool = false
    for _, enemy in ipairs(nearEnemies) do
        if enemy:IsActiveEnemy() and enemy:IsVulnerableEnemy() then
            Bool = true
        end
    end
    return Bool
end

---@param player EntityPlayer
function mod:SunnyStressingOut(player)
    if not OmoriMod.IsOmori(player, true) then return end
    
    local emotion = funcs.GetEmotion(player)
	local playerData = OmoriMod.GetData(player)    
    local areNearEnemies = mod:AreEnemiesNearby(player)

    if areNearEnemies then
        if emotion ~= "StressedOut" then
            local counterToDecrease = emotion == "Afraid" and "StressCounter" or "AfraidCounter"
            playerData[counterToDecrease] = math.max(playerData[counterToDecrease] - 1, 0)
        end
    else
        playerData.AfraidCounter = 90
        playerData.StressCounter = 150
    end
    
    local emotions = {
        ["Afraid"] = "AfraidCounter",
        ["StressedOut"] = "StressCounter"
    }

    for emo, counter in pairs(emotions) do
        local color = (emo == "Afraid" and misc.AfraidColor) or misc.StressColor
        if playerData[counter] == 1 then
            OmoriMod.SetEmotion(player, emo)
            playerData[counter] = 0
        end

        if playerData[counter] <= 30 and playerData[counter] > 0 and playerData[counter] % 10 == 0 then
            sfx:Play(SoundEffect.SOUND_BEEP)
            player:SetColor(color, 8, -1, true, true)
        end
    end    
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.SunnyStressingOut)

function mod:UpdateSunnyColorModifier(player)
    if not OmoriMod.IsOmori(player, true) then return end  

    local emotion = funcs.GetEmotion(player)

    if emotion == "Neutral" then return end

    local targetColorMod = emotion == "Afraid" and misc.AfraidColorMod or misc.StressColorMod    
    game:SetColorModifier(targetColorMod, true, 0.3)

    Isaac.CreateTimer(function ()
        game:GetRoom():UpdateColorModifier(true, true, 1000)
    end, 0, 1, false)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.UpdateSunnyColorModifier)