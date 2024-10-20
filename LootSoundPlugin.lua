local addonName, addon = ...
addon.version = "1.0"

local TREASURE_SOUND_PATH = "Interface\\AddOns\\LootSoundPlugin\\sounds\\treasure.ogg"
local JUNK_SOUND_PATH = "Interface\\AddOns\\LootSoundPlugin\\sounds\\junk.ogg"
local SOUND_CHANNEL = "Master"
local SOUND_VOLUME = 1.0  -- Initial volume level (From 0.0 to 1.0)

local frame = CreateFrame("Frame")

frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("MERCHANT_SHOW")

local function PlaySound(soundPath)
    PlaySoundFile(soundPath, SOUND_CHANNEL, false, false, SOUND_VOLUME)
end

local totalSold = 0

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "LOOT_OPENED" then
        PlaySound(TREASURE_SOUND_PATH)
    elseif event == "MERCHANT_SHOW" then
        -- Reset the total sold amount when the merchant window opens
        totalSold = 0
        -- Register for the BAG_UPDATE_DELAYED event to catch item sales
        self:RegisterEvent("BAG_UPDATE_DELAYED")
    elseif event == "BAG_UPDATE_DELAYED" then
        local newTotal = GetMoney()
        if newTotal > totalSold then
            -- Money increased, so assume something was sold
            PlaySound(JUNK_SOUND_PATH)
        end
        totalSold = newTotal
    end
end)

-- Function to set the volume
function addon:SetVolume(volume)
    SOUND_VOLUME = math.max(0, math.min(1, volume))  -- Ensure volume is between 0 and 1
end

-- Admin control: Slash command to set volume
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

-- Unregister BAG_UPDATE_DELAYED when the merchant window closes
local merchantFrame = CreateFrame("Frame")
merchantFrame:RegisterEvent("MERCHANT_CLOSED")
merchantFrame:SetScript("OnEvent", function(self, event)
    if event == "MERCHANT_CLOSED" then
        frame:UnregisterEvent("BAG_UPDATE_DELAYED")
    end
end)