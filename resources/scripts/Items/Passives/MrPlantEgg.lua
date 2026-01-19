local mod = OmoriMod
local enums = mod.Enums
local items = enums.CollectibleType
local knifeType = enums.KnifeType
local callbacks = enums.Callbacks

---@param player EntityPlayer
---@param ent Entity
local function TriggerMrEggplantHit(player, ent)
    if player:GetDamageCooldown() ~= 0 then return end

    OmoriMod.GiveKnife(player, knifeType.MR_PLANT_EGG)

    local MrEggplant = OmoriMod.GetKnife(player)
    if not MrEggplant then return end

    local MrESprite = MrEggplant:GetSprite()
    local MrEData = OmoriMod.GetData(MrEggplant)
    local playerPos = player.Position
    local entPos = ent.Position

    MrEData.Aiming = (entPos - playerPos):GetAngleDegrees()

    MrESprite:Play("Swing")
end

---@param entity Entity
---@param source EntityRef
mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, function (_, entity, _, _, source)
    local player = entity:ToPlayer()    

    if not player then return end
    if not (player:HasCollectible(items.COLLECTIBLE_MR_PLANTEGG) or mod.IsAubrey(player, false)) then return end
    if source.Type == 0 then return end

    local ent = source.Entity

    if not ent or ent.Type == 0 then return end

    local enemy = ent:IsActiveEnemy() and ent:IsVulnerableEnemy()

    if not enemy then return end
    TriggerMrEggplantHit(player, ent)
end)

---@param knife EntityEffect
---@param type KnifeType
mod:AddCallback(callbacks.PRE_KNIFE_UPDATE, function (_, knife, type)
    local player = mod:GetKnifeOwner(knife)
    if not player then return end
    if type ~= knifeType.MR_PLANT_EGG then return end
    local sprite = knife:GetSprite() 

    if sprite:IsFinished("Swing") then
        OmoriMod.RemoveKnife(player)
    end
end)