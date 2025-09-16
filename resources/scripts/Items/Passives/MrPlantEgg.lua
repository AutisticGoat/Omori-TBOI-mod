local mod = OmoriMod
local enums = mod.Enums
local utils = enums.Utils
local sfx = utils.SFX
local items = enums.CollectibleType
local knifeType = enums.KnifeType
local callbacks = enums.Callbacks

---@param player EntityPlayer
---@return boolean
function mod:IsPlayerAbleToCounterWithMrPlantEgg(player)
    return player:GetDamageCooldown() == 0
end

---@param player EntityPlayer
---@param ent Entity
function mod:TriggerMrEggplantHit(player, ent)
    if not mod:IsPlayerAbleToCounterWithMrPlantEgg(player) then return end

    OmoriMod.GiveKnife(player, knifeType.MR_PLANT_EGG)

    local MrEggplant = OmoriMod.GetKnife(player, knifeType.MR_PLANT_EGG)
    local MrESprite = MrEggplant:GetSprite()
    local MrEData = OmoriMod.GetData(MrEggplant)
    local playerPos = player.Position
    local entPos = ent.Position

    MrEData.Aiming = (entPos - playerPos):GetAngleDegrees()

    MrESprite:Play("Swing")
end

---@param entity Entity
---@param flags DamageFlag
---@param source EntityRef
function mod:PlayerTriggerMrEggplant(entity, _, flags, source)
    local player = entity:ToPlayer()    

    if not player then return end
    if not (player:HasCollectible(items.COLLECTIBLE_MR_PLANTEGG) or mod.IsAubrey(player, false)) then return end
    if source.Type == 0 then return end

    local ent = source.Entity

    if not ent or ent.Type == 0 then return end

    local enemy = ent:IsActiveEnemy() and ent:IsVulnerableEnemy()

    if not enemy then return end
    mod:TriggerMrEggplantHit(player, ent)
end
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, mod.PlayerTriggerMrEggplant)

---comment
---@param knife EntityEffect
---@param type KnifeType
function mod:RemoveMrEggPlant(knife, type)
    local player = mod:GetKnifeOwner(knife)
    if not player then return end
    if type ~= knifeType.MR_PLANT_EGG then return end
    local sprite = knife:GetSprite() 

    if sprite:IsFinished("Swing") then
        OmoriMod.RemoveKnife(player, knifeType.MR_PLANT_EGG)
    end
end
mod:AddCallback(callbacks.PRE_KNIFE_UPDATE, mod.RemoveMrEggPlant)