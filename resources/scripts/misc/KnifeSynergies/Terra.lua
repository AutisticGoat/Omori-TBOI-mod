local mod = OmoriMod
local enums = mod.Enums
local Callbacks = enums.Callbacks

---comment
---@param knife EntityEffect
---@param damage number
function mod:TerraKnifeHit(knife, _, damage)
    local player = OmoriMod:GetKnifeOwner(knife)

    if not player then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_TERRA) then return end

    local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_TERRA)
    local knifeData = OmoriMod.GetData(knife)
    local damageMult = OmoriMod.randomfloat(0.5, 2, rng)

    knifeData.Damage = damage * damageMult
end
mod:AddCallback(Callbacks.KNIFE_HIT_ENEMY, mod.TerraKnifeHit)