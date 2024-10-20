local addonName, addon = ...
addon.version = "1.1"

local TREASURE_SOUND_PATH = "Interface\\AddOns\\lootsoundplugin\\sounds\\treasure.ogg"
local WOW_SOUND_PATH = "Interface\\AddOns\\lootsoundplugin\\sounds\\wow.ogg"
--local JUNK_SOUND_PATH = "Interface\\AddOns\\lootsoundplugin\\sounds\\junk.ogg"
local TRADE_SOUND_PATH = "Interface\\AddOns\\lootsoundplugin\\sounds\\quitpoking.ogg"
local VENDOR_SOUND_PATHS = {
    "Interface\\AddOns\\lootsoundplugin\\sounds\\bringbackmoreshinythings.ogg",
    "Interface\\AddOns\\lootsoundplugin\\sounds\\ifindmorestuff.ogg",
    "Interface\\AddOns\\lootsoundplugin\\sounds\\noaskwhereigotit.ogg",
    "Interface\\AddOns\\lootsoundplugin\\sounds\\someonepicky.ogg",
    "Interface\\AddOns\\lootsoundplugin\\sounds\\uneedigot.ogg"
}

local SOUND_CHANNEL = "Master"
local SOUND_VOLUME = 1.0  -- Volume level (0.0 to 1.0)
local LOOT_SOUND = TREASURE_SOUND_PATH  -- Default loot sound

local frame = CreateFrame("Frame")
frame:RegisterEvent("LOOT_OPENED")
frame:RegisterEvent("MERCHANT_SHOW")
frame:RegisterEvent("TRADE_SHOW")

local function PlaySound(soundPath)
    PlaySoundFile(soundPath, SOUND_CHANNEL, false, false, SOUND_VOLUME)
end

local function PlayRandomVendorSound()
    local randomIndex = math.random(1, #VENDOR_SOUND_PATHS)
    PlaySound(VENDOR_SOUND_PATHS[randomIndex])
end

local function PlayTradeSound()
    PlaySound(TRADE_SOUND_PATH)
end

local totalSold = 0

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "LOOT_OPENED" then
        PlaySound(LOOT_SOUND)
    elseif event == "MERCHANT_SHOW" then
        PlayRandomVendorSound()
        totalSold = GetMoney()
        self:RegisterEvent("BAG_UPDATE_DELAYED")
    elseif event == "BAG_UPDATE_DELAYED" then
        local newTotal = GetMoney()
        if newTotal > totalSold then
            PlaySound(JUNK_SOUND_PATH)
        end
        totalSold = newTotal
    elseif event == "TRADE_SHOW" then
        if C_TradeInfo then
            local target = C_TradeInfo.GetTradeTargetToken()
            if target then
                C_ChatInfo.SendAddonMessage("LootSoundPlugin", "PLAY_TRADE_SOUND", "WHISPER", target)
            end
        end
    end
end)

-- Function to set the volume
function addon:SetVolume(volume)
    SOUND_VOLUME = math.max(0, math.min(1, volume))  -- Ensure volume is between 0 and 1
end

-- Function to set the loot sound
function addon:SetLootSound(soundType)
    if soundType == "wow" then
        LOOT_SOUND = WOW_SOUND_PATH
        print("Loot sound set to 'Wow'")
    else
        LOOT_SOUND = TREASURE_SOUND_PATH
        print("Loot sound set to 'Treasure'")
    end
end

-- Slash command to set volume and loot sound
SLASH_LOOTSOUND1 = "/lootsound"
SlashCmdList["LOOTSOUND"] = function(msg)
    local command, value = msg:match("^(%S*)%s*(.-)$")
    
    if command == "volume" then
        local volume = tonumber(value)
        if volume then
            addon:SetVolume(volume)
            print("LootSoundPlugin volume set to " .. SOUND_VOLUME)
        else
            print("Usage: /lootsound volume <0.0 to 1.0>")
        end
    elseif command == "loot" then
        if value == "wow" or value == "treasure" then
            addon:SetLootSound(value)
        else
            print("Usage: /lootsound loot <wow|treasure>")
        end
    else
        print("Usage:")
        print("/lootsound volume <0.0 to 1.0>")
        print("/lootsound loot <wow|treasure>")
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

-- Register addon message prefix
C_ChatInfo.RegisterAddonMessagePrefix("LootSoundPlugin")

-- Create a frame to listen for addon messages
local messageFrame = CreateFrame("Frame")
messageFrame:RegisterEvent("CHAT_MSG_ADDON")
messageFrame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
    if event == "CHAT_MSG_ADDON" and prefix == "LootSoundPlugin" and message == "PLAY_TRADE_SOUND" then
        PlayTradeSound()
    end
end)