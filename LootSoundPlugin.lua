local addonName, addon = ...
addon.version = "1.0"

local SOUND_PATH = "Interface\\AddOns\\LootSoundPlugin\\sounds\\treasure.ogg"
local SOUND_CHANNEL = "Master"
local SOUND_VOLUME = 1.0  -- Volume level (0.0 to 1.0)

local frame = CreateFrame("Frame")

frame:RegisterEvent("LOOT_OPENED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "LOOT_OPENED" then
        -- Playing the sound using PlaySoundFile() with volume control
        PlaySoundFile(SOUND_PATH, SOUND_CHANNEL, false, false, SOUND_VOLUME)
    end
end)

-- Function to set the volume
function addon:SetVolume(volume)
    SOUND_VOLUME = math.max(0, math.min(1, volume))  -- Ensure volume is between 0 and 1
end

-- Optional: Slash command to set volume
SLASH_LOOTSOUND1 = "/lootsound"
SlashCmdList["LOOTSOUND"] = function(msg)
    local volume = tonumber(msg)
    if volume then
        addon:SetVolume(volume)
        print("LootSoundPlugin volume set to " .. SOUND_VOLUME)
    else
        print("Usage: /lootsound <volume> (0.0 to 1.0)")
    end
end