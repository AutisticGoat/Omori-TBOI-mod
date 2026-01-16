local mod = OmoriMod
local enums = mod.Enums
local utils = enums.Utils
local sfx = utils.SFX
local sounds = enums.SoundEffect
local game = utils.Game
local OmoriCallbacks = enums.Callbacks
local HeadButtAOE = 40
local debugRender = false

---@param player EntityPlayer
function mod:AubreyInputs(player)
    if not OmoriMod.IsAnyAubrey(player) then return end
    local playerData = mod.GetData(player) ---@type table
    
    if OmoriMod:IsEmotionChangeTriggered(player) then 
        if playerData.HeadButtCounter ~= 0 then return end
        mod:InitHeadbutt(player)
    end
    
    if not playerData.HeadButt then return end

    local capsule = Capsule(player.Position, Vector.One, 0, 20)

    if player:CollidesWithGrid() then
        mod:TriggerHBParams(player, true, true)
        game:ShakeScreen(10)
        sfx:Play(sounds.SOUND_HEADBUTT_KILL)
        player:SetMinDamageCooldown(40)
    end

    if debugRender == true then
        local DebugShape = DebugRenderer.Get(1, true)    
        DebugShape:Capsule(capsule)
    end

    local enemies = Isaac.FindInCapsule(capsule, EntityPartition.ENEMY)
    local playerRef = EntityRef(player)

    for _, ent in pairs(enemies) do
        playerData.HeadButtDamage = 0
        Isaac.RunCallback(OmoriCallbacks.HEADBUTT_ENEMY_HIT, player, ent)
        
        ent:TakeDamage(playerData.HeadButtDamage, 0, playerRef, 0)
        sfx:Play(sounds.SOUND_HEADBUTT_HIT)
        
        local nearbyEnemies = Isaac.FindInRadius(player.Position, HeadButtAOE, EntityPartition.ENEMY)
        for _, entity in ipairs(nearbyEnemies) do
            if GetPtrHash(ent) ~= GetPtrHash(entity) then
                entity:TakeDamage(playerData.HeadButtDamage * 0.75, 0, playerRef, 0)
            end

            if entity.HitPoints <= playerData.HeadButtDamage then
                Isaac.RunCallback(OmoriCallbacks.HEADBUTT_ENEMY_KILL, player, ent)
            end
            mod.TriggerPush(entity, player, 20, 5, true)
        end

        mod:TriggerHBParams(player, false, false)
    end
end
mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, mod.AubreyInputs)