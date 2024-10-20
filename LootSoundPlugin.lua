local addonName, addon = ...
addon.version = "1.0"

local playerGUID = UnitGUID("player")
local SOUND_PATH = "Interface\\AddOns\\LootSoundPlugin\\sounds\\treasure.ogg"
local SOUND_CHANNEL = "Master"

local frame = CreateFrame("Frame")

frame:RegisterEvent("LOOT_OPENED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "LOOT_OPENED" then
        -- Playing the sound using PlaySoundFile()
        PlaySoundFile(SOUND_PATH, SOUND_CHANNEL)
    end
end)