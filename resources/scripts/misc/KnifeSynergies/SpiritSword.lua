local mod = OmoriMod
local enums = mod.Enums
local Callbacks = enums.Callbacks

---@param knife EntityEffect
function mod:SwordSwing(knife)
    local player = OmoriMod:GetKnifeOwner(knife)

    if not player then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_SPIRIT_SWORD) then return end

    local knifeData = OmoriMod.GetData(knife)
    local playerData = OmoriMod.GetData(player)

    knifeData.SwordSwing = knifeData.SwordSwing or false

    if not playerData.shinyKnifeCharge then return end
    if playerData.shinyKnifeCharge >= 10 then return end 

    if not OmoriMod:IsShootTriggered(player) then return end

    OmoriMod:InitKnifeSwing(knife)
    knifeData.AllowOriginalLogic = false
    knifeData.SwordSwing = true
end
mod:AddCallback(Callbacks.POST_KNIFE_RENDER, mod.SwordSwing)

function mod:FullChargeAttack(knife)
    local player = OmoriMod:GetKnifeOwner(knife)

    if not player then return end
    local knifeData = OmoriMod.GetData(knife)
    local playerData = OmoriMod.GetData(player)

    if not player:HasCollectible(CollectibleType.COLLECTIBLE_SPIRIT_SWORD) then return end
    if playerData.shinyKnifeCharge ~= 100 then return end

    knifeData.Damage = knifeData.Damage * 1.5
end
mod:AddCallback(Callbacks.KNIFE_HIT_ENEMY, mod.FullChargeAttack)

function mod:OnSwordFullSwinging(knife)
    local player = knife.SpawnerEntity:ToPlayer()

    if not player then return end
    local playerData = OmoriMod.GetData(player)

    if not player:HasCollectible(CollectibleType.COLLECTIBLE_SPIRIT_SWORD) then return end
    if playerData.shinyKnifeCharge ~= 100 then return end

    OmoriMod.SetKnifeSizeMult(knife, 1.5)
end
mod:AddCallback(Callbacks.KNIFE_SWING_UPDATE, mod.OnSwordFullSwinging)