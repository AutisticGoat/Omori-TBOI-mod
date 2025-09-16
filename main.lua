-- Omori Mod's (Totally Not Lifted) Code. (Thanks Sag)-

-- Rework trabajado por Kotry / Rework made by Kotry 

OmoriMod = RegisterMod("Omori", 1)

local font = Font()
font:Load("font/pftempestasevencondensed.fnt")

-- if REPENTANCE_PLUS then
--     OmoriMod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
--         local text = "Repentance+ is unsuported at the moment"
--         local text2 = "Downgrade to Repentance"
--         font:DrawStringScaledUTF8(text, Isaac.GetScreenWidth()/1.1 - font:GetStringWidthUTF8(text)/2, Isaac.GetScreenHeight()/1.2, 1, 1, KColor(2,.5,.5,1), 1, true )
--         font:DrawStringScaledUTF8(text2, Isaac.GetScreenWidth()/1.1 - font:GetStringWidthUTF8(text2)/2, Isaac.GetScreenHeight()/1.2 + 8, 1, 1, KColor(2,.5,.5,1), 1, true )
--     end)
--     return
-- end

if not REPENTOGON then 
    OmoriMod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        local text = "REPENTOGON is missing"
        local text2 = "check repentogon.com"
        font:DrawStringScaledUTF8(text, Isaac.GetScreenWidth()/1.1 - font:GetStringWidthUTF8(text)/2, Isaac.GetScreenHeight()/1.2, 1, 1, KColor(2,.5,.5,1), 1, true )
        font:DrawStringScaledUTF8(text2, Isaac.GetScreenWidth()/1.1 - font:GetStringWidthUTF8(text2)/2, Isaac.GetScreenHeight()/1.2 + 8, 1, 1, KColor(2,.5,.5,1), 1, true )
    end)
    return
end

OmoriMod.saveManager = require("resources.scripts.misc.save_manager")
OmoriMod.saveManager.Init(OmoriMod)

include("include")
include("resources/scripts/dss/deadseascrolls")