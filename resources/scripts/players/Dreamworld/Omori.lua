local mod = OmoriMod

local enums = OmoriMod.Enums
local costumes = enums.NullItemID

---comment
---@param player EntityPlayer
function mod:OmoriInit(player)
	if OmoriMod:IsOmori(player, false) then
		player:AddNullCostume(costumes.ID_OMORI)
		player:AddNullCostume(costumes.ID_EMOTION)
		OmoriMod.SetEmotion(player, "Neutral")
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.OmoriInit)

---comment
---@param itemconfig ItemConfigItem
---@param player EntityPlayer
---@return boolean
function mod:PreAddOmoriCostume(itemconfig, player)	
	if not OmoriMod:IsOmori(player, false) then return end

	local costume = itemconfig.Costume
	local ID = costume.ID
		
	if ID == costumes.ID_OMORI or ID == costumes.ID_EMOTION then return end
	
	return true
end
mod:AddCallback(ModCallbacks.MC_PRE_PLAYER_ADD_COSTUME, mod.PreAddOmoriCostume)
	
local overrideWeapons = {
	[WeaponType.WEAPON_BRIMSTONE] = true,
	[WeaponType.WEAPON_KNIFE] = true,
	[WeaponType.WEAPON_LASER] = true,
	[WeaponType.WEAPON_BOMBS] = true,
	[WeaponType.WEAPON_ROCKETS] = true,
	[WeaponType.WEAPON_TECH_X] = true,
	[WeaponType.WEAPON_SPIRIT_SWORD] = true,
	-- [WeaponType.WEAPON_LUDOVICO_TECHNIQUE] = true,
}

function mod:OmoriUpdate(player)
	if not OmoriMod:IsOmori(player, false) then return end

	OmoriMod:GiveKnife(player)
end
mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, mod.OmoriUpdate)

--- comment
--- @param player EntityPlayer
function mod:OmoUpdate(player)
	if not OmoriMod:IsKnifeUser(player) then return end		
	local weapon = player:GetWeapon(1)
	
	if weapon == nil then return end

	local override = overrideWeapons[weapon:GetWeaponType()] or false

	if override == true then
		local newWeapon = Isaac.CreateWeapon(WeaponType.WEAPON_TEARS, player)
		Isaac.DestroyWeapon(weapon)


		player:EnableWeaponType(WeaponType.WEAPON_TEARS, true)
		player:SetWeapon(newWeapon, 1)
	end

	if weapon:GetWeaponType() == WeaponType.WEAPON_LUDOVICO_TECHNIQUE then
		Isaac.DestroyWeapon(weapon)
	end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.OmoUpdate)

---comment
---@param player EntityPlayer
---@param flags CacheFlag
function mod:OmoriStats(player, flags)
	if not OmoriMod:IsOmori(player, false) then return end
	if flags == CacheFlag.CACHE_DAMAGE then
		player.Damage = player.Damage * 1.1
	elseif flags == CacheFlag.CACHE_SPEED then
		player.MoveSpeed = player.MoveSpeed + 0.1
	end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.OmoriStats)