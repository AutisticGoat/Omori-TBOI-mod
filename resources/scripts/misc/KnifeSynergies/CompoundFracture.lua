local mod = OmoriMod
local enums = mod.Enums
local utils = enums.Utils
local rng = utils.RNG
local Callbacks = enums.Callbacks

---comment
---@param knife EntityEffect
---@param entity Entity
---@param dmg number
function mod:TechnologyHit(knife, entity, dmg)
    local player = OmoriMod:GetKnifeOwner(knife)

    if not player then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_COMPOUND_FRACTURE) then return end

    local bonesSpawn = OmoriMod.randomNumber(2, 4, rng)

    for _ = 1, bonesSpawn do        
        player:FireTear(entity.Position, RandomVector() * 10, true, true, false, player, 1)
    end
end
mod:AddCallback(Callbacks.KNIFE_KILL_ENEMY, mod.TechnologyHit)
