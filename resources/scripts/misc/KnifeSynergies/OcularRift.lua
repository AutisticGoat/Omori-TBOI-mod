local mod = OmoriMod
local enums = mod.Enums
local Callbacks = enums.Callbacks

---@param knife EntityEffect
---@param entity EntityNPC
function mod:MomsKnifeDamage(knife, entity)
    local player = OmoriMod:GetKnifeOwner(knife)
    if not player then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_OCULAR_RIFT) then return end
    if not mod.RandomBoolean(player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_OCULAR_RIFT),  1 / math.max((20 - player.Luck), 5)) then return end

    local rift = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.RIFT, 0, entity.Position, Vector.Zero, 
    player):ToEffect()

    if not rift then return end
    rift.CollisionDamage = player.Damage / 2
    rift:SetTimeout(60)
end
mod:AddCallback(Callbacks.KNIFE_HIT_ENEMY, mod.MomsKnifeDamage)