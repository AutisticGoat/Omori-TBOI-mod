local mod = OmoriMod
local enums = mod.Enums
local utils = enums.Utils
local sounds = enums.SoundEffect
local callbacks = enums.Callbacks
local rng = utils.RNG
local sfx = utils.SFX
local game = utils.Game
local items = enums.CollectibleType
local knifeType = enums.KnifeType

function mod:NailBatGive(_, _, _, _, _, player)
    mod.GiveKnife(player, knifeType.NAIL_BAT)
end
mod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, mod.NailBatGive, items.COLLECTIBLE_NAIL_BAT)

---@param bat EntityEffect
---@param entity Entity
---@param type KnifeType
---@return number?
function mod:NailbatHit(bat, entity, _, type)
    local player = bat.SpawnerEntity:ToPlayer()

    if not player then return end
    if type ~= knifeType.NAIL_BAT then return end

    local batData = OmoriMod.GetData(bat)

    sfx:Play(sounds.SOUND_AUBREY_HIT, 1, 2, false, 1, 0)

    local homeRunChance = OmoriMod.randomNumber(1, 100, rng)
    local maxChance = entity:IsBoss() == true and 2 or 10

    if homeRunChance <= maxChance then
        local randomNumber = OmoriMod.randomfloat(0.9, 1.1, rng)
        sfx:Play(sounds.SOUND_HOMERUN, 0.8, 0, false, randomNumber, 0)
        game:ShakeScreen(10)
        entity:AddEntityFlags(EntityFlag.FLAG_EXTRA_GORE)
        batData.Damage = math.huge
    end
end
mod:AddCallback(callbacks.KNIFE_HIT_ENEMY, mod.NailbatHit)

---@param bat EntityEffect
---@param type KnifeType
function mod:BatSwingTrigger(bat, type)
    local player = bat.SpawnerEntity:ToPlayer()

    if not player then return end
    if type ~= knifeType.NAIL_BAT then return end

    sfx:Play(sounds.SOUND_AUBREY_SWING, 0.7, 2, false, 1.5, 0)
end
mod:AddCallback(callbacks.KNIFE_SWING_TRIGGER, mod.BatSwingTrigger)