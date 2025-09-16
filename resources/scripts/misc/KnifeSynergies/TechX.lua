local mod = OmoriMod
local enums = mod.Enums
local Callbacks = enums.Callbacks

function mod:TechXSwingTrigger(knife)
    local player = OmoriMod:GetKnifeOwner(knife)
    local knifeData = OmoriMod.GetData(knife)

    if not player then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_TECH_X) then return end

    local techX = player:FireTechXLaser(
        knife.Position + Vector.FromAngle(knifeData.Aiming):Resized(30 * knife.SpriteScale.X),
        Vector.Zero,
        30 * knife.SpriteScale.X,
        player,
        1
    ):ToLaser()

    if not techX then return end

    techX:AddTearFlags(player.TearFlags)
    techX:SetTimeout(8)
end
mod:AddCallback(Callbacks.KNIFE_SWING_TRIGGER, mod.TechXSwingTrigger)