local mod = OmoriMod
local enums = mod.Enums
local Callbacks = enums.Callbacks

local function SpawnLudoTear(player)
    local playerData = OmoriMod.GetData(player)

    if not playerData.LudoTear then
        local tear = Isaac.Spawn(EntityType.ENTITY_TEAR, 0, 0, player.Position, Vector.Zero, player):ToTear() 
        if not tear then return end
        local tearData = OmoriMod.GetData(tear)
        tearData.FakeLudo = true
        tear:AddTearFlags(player.TearFlags | TearFlags.TEAR_BOUNCE)
        playerData.LudoTear = tear
    end
end

function mod:ForceSpawnFakeLudoTear(player)
    if not player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then return end
    SpawnLudoTear(player)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.ForceSpawnFakeLudoTear)

function OmoriMod:KillLudoTear(player)
    local playerData = OmoriMod.GetData(player)

    if not playerData.LudoTear then return end
    playerData.LudoTear:Remove()
    playerData.LudoTear = nil
end

---@param tear EntityTear
function mod:LudoTearUpdate(tear)
    local tearData = OmoriMod.GetData(tear)

    if not tearData.FakeLudo then return end

    local player = OmoriMod.GetPlayerFromAttack(tear)

    if not player then return end

    tear.Height = -23

    local damageDiv = 3.5
	local multScale = math.max((player.Damage / damageDiv), 1)
				
	tear.Scale = 1.55 * multScale
	tear:AddTearFlags(player.TearFlags | TearFlags.TEAR_BOUNCE)
				
	tearData.HitByKnife = tearData.HitByKnife or false
				
	if tearData.HitByKnife == true then
		local damageCap = math.min(player.Damage * 12, player.Damage * OmoriMod:GetAceleration(tear))
        tear.CollisionDamage = damageCap
					
		if OmoriMod:GetAceleration(tear) >= 0 and OmoriMod:GetAceleration(tear) < 2 then
			tearData.HitByKnife = false
		end
		tear:MultiplyFriction(0.975)
	else
		tear:MultiplyFriction(0.7)
		tear.Velocity = tear.Velocity + (((player.Position - tear.Position):Normalized() * (player.Position - tear.Position):Length() / 40)) 
		tear.CollisionDamage = player.Damage		
		local distance = tear.Position:Distance(player.Position)
		local carajo = 0.7 * (distance / 65)
		if distance <= 65 then
			tear:MultiplyFriction(math.min(carajo, 0.95))
		end
	end
end
mod:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE, mod.LudoTearUpdate)

function mod:OnKnifeHittingLudoTear(knife, entity)
    local tear = entity:ToTear()
    if not tear then return end
    local tearData = OmoriMod.GetData(tear)
    if not tearData.FakeLudo then return end
    tearData.HitByKnife = true
    tear.Velocity = (knife.Position + tear.Position):Resized(100)
end
mod:AddCallback(Callbacks.KNIFE_ENTITY_COLLISION, mod.OnKnifeHittingLudoTear)

function mod:RoomChange()
    local players = PlayerManager.GetPlayers()

    for _, player in ipairs(players) do
        OmoriMod:KillLudoTear(player)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, mod.RoomChange)