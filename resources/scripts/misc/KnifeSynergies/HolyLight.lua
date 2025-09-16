local mod = OmoriMod
local enums = mod.Enums
local utils = enums.Utils
local rng = utils.RNG
local Callbacks = enums.Callbacks

function mod:KnifeHolyLightHit(knife, entity, damage)
    local player = OmoriMod:GetKnifeOwner(knife)

    if not player then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_HOLY_LIGHT) then return end
    if not mod.RandomBoolean(player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_HOLY_LIGHT), 1 / math.max((10 - (player.Luck * 0.9)), 2)) then return end
    
    local light = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CRACK_THE_SKY, 10, entity.Position, Vector.Zero, player):ToEffect()

    if not light then return end
    entity:TakeDamage(damage * 3, DamageFlag.DAMAGE_LASER, EntityRef(player), 0)
end
mod:AddCallback(Callbacks.KNIFE_HIT_ENEMY, mod.KnifeHolyLightHit)