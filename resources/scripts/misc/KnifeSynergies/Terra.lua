local mod = OmoriMod
local enums = mod.Enums
local Callbacks = enums.Callbacks

---comment
---@param knife EntityEffect
function mod:TerraKnifeHit(knife)
    local player = OmoriMod:GetKnifeOwner(knife)

    if not player then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_TERRA) then return end

    local rng = player:GetCollectibleRNG(CollectibleType.COLLECTIBLE_TERRA)
    local knifeData = mod:GetKnifeData(knife) ---@cast knifeData OmoriModKnifeData 
    local damageMult = OmoriMod.randomfloat(0.5, 2, rng)

    knifeData.SwingDamage = knifeData.SwingDamage * damageMult
end
mod:AddCallback(Callbacks.KNIFE_HIT_ENEMY, mod.TerraKnifeHit)