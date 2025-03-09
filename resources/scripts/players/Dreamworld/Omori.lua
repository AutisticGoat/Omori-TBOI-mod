local mod = OmoriMod
local enums = mod.Enums
local costumes = enums.NullItemID
local players = enums.PlayerType
local knifeType = enums.KnifeType

local funcs = {
	IsOmori = mod.IsOmori,
}

---@param player EntityPlayer
function mod:OmoriInit(player)
	if not funcs.IsOmori(player, false) then return end
	player:AddNullCostume(costumes.ID_OMORI)
	player:AddNullCostume(costumes.ID_EMOTION)
	OmoriMod.SetEmotion(player, "Neutral")
	OmoriMod.AddEmotionGlow(player)
	OmoriMod.GiveKnife(player, knifeType.SHINY_KNIFE)
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, mod.OmoriInit)

local modCharacters = {
	[players.PLAYER_AUBREY] = costumes.ID_DW_AUBREY,
	[players.PLAYER_AUBREY_B] = costumes.ID_RW_AUBREY,
	[players.PLAYER_OMORI] = costumes.ID_OMORI,
	[players.PLAYER_OMORI_B] = costumes.ID_SUNNY,
}

local overrideCostumes = {
	[625] = true,
	[58] = true,
	[costumes.ID_EMOTION] = true,
}

---@param itemconfig ItemConfigItem
---@param player EntityPlayer
---@return boolean?
function mod:PreAddOmoriCostume(itemconfig, player)
	local rawCostume = modCharacters[player:GetPlayerType()]

	if not rawCostume then return end

	table.insert(overrideCostumes, rawCostume)

	local costumeID = itemconfig.Costume.ID

	if costumeID == rawCostume or costumeID == costumes.ID_EMOTION or costumeID == 625 or costumeID == 58 then
		return
	end
	
	OmoriMod:ChangeEmotionEffect(player, false)

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
}

--- @param player EntityPlayer
function mod:OmoUpdate(player)
	if not OmoriMod:IsKnifeUser(player) then return end		
	local weapon = player:GetWeapon(1)
	
	if weapon == nil then return end
	local override = OmoriMod.When(weapon:GetWeaponType(), overrideWeapons, false) 

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

---@param player EntityPlayer
---@param flags CacheFlag
function mod:OmoriStats(player, flags)
	if not funcs.IsOmori(player, false) then return end

	player:AddNullCostume(costumes.ID_OMORI)
	player:AddNullCostume(costumes.ID_EMOTION)

	if flags == CacheFlag.CACHE_DAMAGE then
		player.Damage = player.Damage * 1.1
	elseif flags == CacheFlag.CACHE_SPEED then
		player.MoveSpeed = player.MoveSpeed + 0.1
	end
end
mod:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, mod.OmoriStats)