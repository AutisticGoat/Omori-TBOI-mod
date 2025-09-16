local mod = OmoriMod
local enums = mod.Enums
local utils = enums.Utils
local rng = utils.RNG
local Callbacks = enums.Callbacks

---comment
---@param p EntityPlayer
---@return number
function OmoriMod:GetTPS(p)
    return (30 / (p.MaxFireDelay + 1))
end

function mod:GetWeaponCharge(player)
    local weapon = player:GetWeapon(1)

    if not weapon then return end
    local weaponMod = weapon:GetModifiers()
    if not OmoriMod:isFlagInBitmask(weaponMod, WeaponModifier.CHOCOLATE_MILK) then return end

    local playerData = OmoriMod.GetData(player)

    playerData.ChoccyCharge = playerData.ChoccyCharge or 0

    local baseMaxCharge = 26.5
    local chargeFactor = (2.73 / OmoriMod:GetTPS(player)) -- it's not exact but it works
    local charge = weapon:GetCharge()

    if charge ~= 0 then
        playerData.ChoccyCharge = OmoriMod:Round (charge / (chargeFactor * baseMaxCharge), 2)

        if (player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) or player:HasCollectible(CollectibleType.COLLECTIBLE_ALMOND_MILK)) or playerData.ChoccyCharge >= 0.95 then
            playerData.ChoccyCharge = 1
        end
    end

    playerData.shinyKnifeCharge = (playerData.ChoccyCharge * 100)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.GetWeaponCharge)

---comment
---@param knife EntityEffect
---@param damage number
function mod:ChocolateDamage(knife, _, damage)
    local player = OmoriMod:GetKnifeOwner(knife)
    if not player then return end
    local weapon = player:GetWeapon(1)
    if not weapon then return end

    local playerData = OmoriMod.GetData(player)
    local weaponMod = weapon:GetModifiers()

    if not OmoriMod:isFlagInBitmask(weaponMod, WeaponModifier.CHOCOLATE_MILK) then return end
    local knifeData = OmoriMod.GetData(knife)
    local mult = player:HasCollectible(CollectibleType.COLLECTIBLE_MOMS_KNIFE) and 1.1 or 4

    knifeData.Damage = (damage * playerData.ChoccyCharge) * mult
end
mod:AddCallback(Callbacks.KNIFE_HIT_ENEMY, mod.ChocolateDamage)