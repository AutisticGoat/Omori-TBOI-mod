local mod = OmoriMod
local enums = mod.Enums
local Callbacks = enums.Callbacks

function mod:KnifeDamageAdders(knife, _, damage)
    local player = OmoriMod:GetKnifeOwner(knife)
    local knifeData = OmoriMod.GetData(knife)
    local adders = {
        ---@param rng RNG
        [CollectibleType.COLLECTIBLE_APPLE] = function(rng)
            if not mod.RandomBoolean(rng, 1 / math.max(15 - player.Luck, 1)) then return end
            knifeData.Damage = damage * 4
        end,
        ---@param rng RNG
        [CollectibleType.COLLECTIBLE_TOUGH_LOVE] = function(rng)
            if not mod.RandomBoolean(rng, 1 / math.max(10 - player.Luck, 1)) then return end
            knifeData.Damage = damage * 3.2
        end,
        ---@param rng RNG
        [CollectibleType.COLLECTIBLE_STYE] = function(rng)
            if not mod.RandomBoolean(rng) then return end
            knifeData.Damage = damage * 1.28
        end,
        ---@param rng RNG
        [CollectibleType.COLLECTIBLE_BLOOD_CLOT] = function(rng)
            if not mod.RandomBoolean(rng) then return end
            knifeData.Damage = damage * 1.1
        end,
    }

    for item, funct in pairs(adders) do
        if not player:HasCollectible(item) then goto Continue end
        funct(player:GetCollectibleRNG(item))
        ::Continue::
    end
end
mod:AddCallback(Callbacks.KNIFE_HIT_ENEMY, mod.KnifeDamageAdders)