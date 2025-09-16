local mod = OmoriMod
local enums = mod.Enums
local Callbacks = enums.Callbacks

function mod:KnifeJacobsLadderHit(knife, entity, damage)
    local player = OmoriMod:GetKnifeOwner(knife)

    if not player then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_JACOBS_LADDER) then return end

    local jacobs = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.CHAIN_LIGHTNING, 0, entity.Position, Vector.Zero, player):ToEffect()
	jacobs.CollisionDamage = player.Damage
end
mod:AddCallback(Callbacks.KNIFE_HIT_ENEMY, mod.KnifeJacobsLadderHit)
