local mod = OmoriMod
local enums = mod.Enums
local Callbacks = enums.Callbacks

function mod:SpawnGodHeadAura(knife)
    local player = OmoriMod:GetKnifeOwner(knife)

    if not player then return end
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_GODHEAD) then return end
    local knifeData = OmoriMod.GetData(knife)
    local VectorAdd = Vector.FromAngle(knife.SpriteRotation)    

    knifeData.Aura = nil

    if not knifeData.Aura then
        local aura = Isaac.Spawn(
            EntityType.ENTITY_TEAR,
            0,
            0,
            knife.Position + VectorAdd:Resized(40),
            Vector.Zero,
            knife
        ):ToTear() ---@type EntityTear
        
        if not aura then return end

        aura:AddTearFlags(TearFlags.TEAR_GLOW)
        aura.Scale = 1.2
        aura.Color = Color(0,0,0,0)

        knifeData.Aura = aura
    end
end
mod:AddCallback(Callbacks.KNIFE_SWING_TRIGGER, mod.SpawnGodHeadAura)

function mod:onKnifeGodheadSwing(knife)
    local knifeData = OmoriMod.GetData(knife)
    if not knifeData.Aura then return end
    local VectorAdd = Vector.FromAngle(knife.SpriteRotation)    

    knifeData.Aura.Position = knife.Position + VectorAdd:Resized(40)
end
mod:AddCallback(Callbacks.KNIFE_SWING_UPDATE, mod.onKnifeGodheadSwing)

function mod:onKnifeGodheadSwingFinish(knife)
    local knifeData = OmoriMod.GetData(knife)

    if not knifeData.Aura then return end
    knifeData.Aura:Remove()
end
mod:AddCallback(Callbacks.KNIFE_SWING_FINISH, mod.onKnifeGodheadSwingFinish)