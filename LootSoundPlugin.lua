local addonName, addon = ...
addon.version = "1.1.3"

-- Configuration
local Config = {
    SOUND_PATHS = {
        TREASURE = "Interface\\AddOns\\lootsoundplugin\\sounds\\treasure.ogg",
        WOW = "Interface\\AddOns\\lootsoundplugin\\sounds\\wow.ogg",
        TRADE = "Interface\\AddOns\\lootsoundplugin\\sounds\\quitpoking.ogg",
        VENDOR = {
            "Interface\\AddOns\\lootsoundplugin\\sounds\\bringbackmoreshinythings.ogg",
            "Interface\\AddOns\\lootsoundplugin\\sounds\\ifindmorestuff.ogg",
            "Interface\\AddOns\\lootsoundplugin\\sounds\\noaskwhereigotit.ogg",
            "Interface\\AddOns\\lootsoundplugin\\sounds\\someonepicky.ogg",
            "Interface\\AddOns\\lootsoundplugin\\sounds\\uneedigot.ogg"
        }
    },
    DEFAULTS = {
        SOUND_CHANNEL = "Master",
        SOUND_VOLUME = 0.7,
        LOOT_SOUND = "TREASURE"
        DEBUG_MODE =  false
    }
}

-- State management
local State = {
    currentVolume = Config.DEFAULTS.SOUND_VOLUME,
    currentLootSound = Config.DEFAULTS.LOOT_SOUND,
    currentChannel = Config.DEFAULTS.SOUND_CHANNEL,
    totalSold = 0,
    isEnabled = true,
    sounds = {
        loot = true,
        vendor = true,
        trade = true
    }
}

-- Utility functions
local Utils = {
    validateSoundFile = function(path)
        if not path then 
            print("|cFFFF0000[LootSound Debug]|r Sound path is nil")
            return false 
        end
        if type(path) ~= "string" then
            print("|cFFFF0000[LootSound Debug]|r Sound path is not a string:", type(path))
            return false
        end
        if not path:match("%.ogg$") then
            print("|cFFFF0000[LootSound Debug]|r Sound file is not .ogg:", path)
            return false
        end
        return true
    end,
    
    printMessage = function(msg, isError)
        local prefix = isError and "|cFFFF0000[LootSound]|r " or "|cFF00FF00[LootSound]|r "
        print(prefix .. msg)
    end,
    
    validateVolume = function(volume)
        if type(volume) ~= "number" then return false end
        return volume >= 0 and volume <= 1
    end,

    getToggleState = function(state)
        return state and "|cFF00FF00enabled|r" or "|cFFFF0000disabled|r"
    end,

    debugPrint = function(...)
        if not State.isDebug then return end -- If debug mode is off, do nothing.
        print("|cFFFFFF00[LootSound Debug]|r", ...)
    end
}

-- Sound handling
local SoundManager = {
    playRandomVendorSound = function()
        if not State.sounds.vendor then return end
        local paths = Config.SOUND_PATHS.VENDOR
        if #paths == 0 then return end
        local randomIndex = math.random(1, #paths)
        PlaySoundFileWithVolume(paths[randomIndex], State.currentChannel, State.currentVolume)
    end,
    
    getCurrentLootSound = function()
        return Config.SOUND_PATHS[State.currentLootSound]
    end,

    testSounds = function()
        Utils.debugPrint("Starting sound system test...")
        
        Utils.printMessage("Playing treasure sound...")
        PlaySoundFileWithVolume(Config.SOUND_PATHS.TREASURE, State.currentChannel, State.currentVolume)
        
        C_Timer.After(2, function()
            Utils.printMessage("Playing wow sound...")
            PlaySoundFileWithVolume(Config.SOUND_PATHS.WOW, State.currentChannel, State.currentVolume)
        end)
        
        C_Timer.After(4, function()
            Utils.printMessage("Playing vendor sound...")
            SoundManager.playRandomVendorSound()
        end)
        
        C_Timer.After(6, function()
            Utils.printMessage("Playing trade sound...")
            PlaySoundFileWithVolume(Config.SOUND_PATHS.TRADE, State.currentChannel, State.currentVolume)
        end)
    end
}

-- Event handling
local EventManager = CreateFrame("Frame")
EventManager:RegisterEvent("LOOT_OPENED")
EventManager:RegisterEvent("MERCHANT_SHOW")
EventManager:RegisterEvent("MERCHANT_CLOSED")
EventManager:RegisterEvent("TRADE_SHOW")
EventManager:RegisterEvent("PLAYER_LOGIN")

EventManager:SetScript("OnEvent", function(self, event, ...)
  Utils.debugPrint("Event fired:", event)
    
  if not State.isEnabled then 
    Utils.debugPrint("Addon disabled, ignoring event")
    return
  end
    
  if event == "PLAYER_LOGIN" then
    -- First-time setup: If LootSoundDB doesn't exist or is empty, populate it.
    LootSoundDB = LootSoundDB or {}
    LootSoundDB.volume = LootSoundDB.volume or Config.DEFAULTS.SOUND_VOLUME
    LootSoundDB.lootSound = LootSoundDB.lootSound or Config.DEFAULTS.LOOT_SOUND
    LootSoundDB.channel = LootSoundDB.channel or Config.DEFAULTS.SOUND_CHANNEL
    LootSoundDB.isEnabled = LootSoundDB.isEnabled == nil and true or LootSoundDB.isEnabled
    LootSoundDB.sounds = LootSoundDB.sounds or { loot = true, vendor = true, trade = true }
    LootSoundDB.isDebug = LootSoundDB.isDebug == nil and Config.DEFAULTS.DEBUG_MODE or LootSoundDB.isDebug

    -- Now, apply the loaded/default settings to the addon's current state
    State.currentVolume = LootSoundDB.volume
    State.currentLootSound = LootSoundDB.lootSound
    State.currentChannel = LootSoundDB.channel
    State.isEnabled = LootSoundDB.isEnabled
    State.sounds = LootSoundDB.sounds
    State.isDebug = LootSoundDB.isDebug


    Utils.printMessage(string.format("Addon v%s loaded! Type /lootsound help for commands.", addon.version))
    self:UnregisterEvent("PLAYER_LOGIN") -- No need to run this again this session
  elseif event == "LOOT_OPENED" then
    -- Check if sounds are enabled and loot sound is toggled on
    if State.isEnabled and State.sounds.loot then
      PlaySoundFileWithVolume(SoundManager.getCurrentLootSound(), State.currentChannel, State.currentVolume)
    end
  elseif event == "MERCHANT_SHOW" then
    -- Check if sounds are enabled and vendor sound is toggled on
    if State.isEnabled and State.sounds.vendor then
      SoundManager.playRandomVendorSound()
    end
    State.totalSold = GetMoney()
    self:RegisterEvent("BAG_UPDATE_DELAYED")
  elseif event == "MERCHANT_CLOSED" then
    self:UnregisterEvent("BAG_UPDATE_DELAYED")
  elseif event == "TRADE_SHOW" then
    if State.isEnabled and State.sounds.trade and C_TradeInfo then
      local target = C_TradeInfo.GetTradeTargetToken()
      if target then
        C_ChatInfo.SendAddonMessage("LootSoundPlugin", "PLAY_TRADE_SOUND", "WHISPER", target)
      end
    end
  end
end)

-- Addon API
function addon:SetVolume(volume)
    if not Utils.validateVolume(volume) then
        Utils.printMessage("Invalid volume value. Please use a number between 0 and 1.", true)
        return
    end
    State.currentVolume = volume
    LootSoundDB.volume = volume
    Utils.printMessage(string.format("Volume set to %.2f", volume))
end

function addon:SetChannel(channel)
    channel = string.upper(channel)
    if channel ~= "MASTER" and channel ~= "SFX" then
        Utils.printMessage("Invalid channel. Use 'master' or 'sfx'.", true)
        return
    end
    State.currentChannel = channel
    LootSoundDB.channel = channel
    Utils.printMessage("Sound channel set to " .. channel)
end

function addon:SetLootSound(soundType)
    soundType = string.upper(soundType)
    if not Config.SOUND_PATHS[soundType] then
        Utils.printMessage("Invalid sound type. Use 'wow' or 'treasure'.", true)
        return
    end
    State.currentLootSound = soundType
    LootSoundDB.lootSound = soundType
    Utils.printMessage("Loot sound set to " .. soundType)
end

function addon:ToggleAddon(enabled)
    State.isEnabled = enabled
    LootSoundDB.isEnabled = enabled
    Utils.printMessage(enabled and "Addon enabled" or "Addon disabled")
end

function addon:ToggleSound(soundType)
    soundType = string.lower(soundType)

    Utils.debugPrint("Attempting to toggle:", soundType)
    Utils.debugPrint("Current state:", State.sounds[soundType])
    
    if not State.sounds[soundType] and State.sounds[soundType] ~= false then
        Utils.printMessage("Invalid sound type. Use 'loot', 'vendor', or 'trade'.", true)
        return
    end
    
    State.sounds[soundType] = not State.sounds[soundType]

    LootSoundDB.sounds[soundType] = State.sounds[soundType]
    
    Utils.debugPrint("New state:", State.sounds[soundType])
    
    Utils.printMessage(string.format("%s sounds %s", 
        soundType:gsub("^%l", string.upper),
        Utils.getToggleState(State.sounds[soundType])
    ))
end

function addon:ToggleDebug(enabled)
    State.isDebug = enabled
    LootSoundDB.isDebug = enabled
    Utils.printMessage("Debug mode " .. Utils.getToggleState(enabled))
end

-- Slash commands
local function HandleSlashCommands(msg)
    local args = {}
    for arg in msg:gmatch("%S+") do
        table.insert(args, string.lower(arg))
    end
    
    if #args == 0 or args[1] == "help" then
        Utils.printMessage("Available commands:")
        Utils.printMessage("/lootsound volume <0.0 to 1.0> - Set sound volume")
        Utils.printMessage("/lootsound channel <master|sfx> - Set sound channel")
        Utils.printMessage("/lootsound sound <wow|treasure> - Set loot sound")
        Utils.printMessage("/lootsound toggle - Enable/disable all sounds")
        Utils.printMessage("/lootsound loot - Toggle loot sounds")
        Utils.printMessage("/lootsound vendor - Toggle vendor sounds")
        Utils.printMessage("/lootsound trade - Toggle trade sounds")
        Utils.printMessage("/lootsound test - Test all sounds")
        Utils.printMessage("/lootsound status - Show current settings")
        Utils.printMessage("/lootsound debug - Toggles debug messages")
        return
    end
    
    if args[1] == "volume" and args[2] then
        addon:SetVolume(tonumber(args[2]))
    elseif args[1] == "channel" and args[2] then
        addon:SetChannel(args[2])
    elseif args[1] == "sound" and args[2] then
        addon:SetLootSound(args[2])
    elseif args[1] == "toggle" then
        addon:ToggleAddon(not State.isEnabled)
    elseif args[1] == "test" then
        Utils.printMessage("Testing all sounds...")
        SoundManager.testSounds()
    elseif args[1] == "loot" or args[1] == "vendor" or args[1] == "trade" then
        addon:ToggleSound(args[1])
    elseif args[1] == "status" then
        Utils.printMessage(string.format("Addon: %s", Utils.getToggleState(State.isEnabled)))
        Utils.printMessage(string.format("Volume: %.2f", State.currentVolume))
        Utils.printMessage(string.format("Channel: %s", State.currentChannel))
        Utils.printMessage(string.format("Sound: %s", State.currentLootSound))
        Utils.printMessage(string.format("Loot sounds: %s", Utils.getToggleState(State.sounds.loot)))
        Utils.printMessage(string.format("Vendor sounds: %s", Utils.getToggleState(State.sounds.vendor)))
        Utils.printMessage(string.format("Trade sounds: %s", Utils.getToggleState(State.sounds.trade)))
    elseif args[1] == "debug" then
        addon:ToggleDebug(not State.isDebug)
    else
        Utils.printMessage("Unknown command. Type /lootsound help for usage.", true)
    end
end

SLASH_LOOTSOUND1 = "/lootsound"
SlashCmdList["LOOTSOUND"] = HandleSlashCommands

-- Register addon message handling
C_ChatInfo.RegisterAddonMessagePrefix("LootSoundPlugin")

local messageFrame = CreateFrame("Frame")
messageFrame:RegisterEvent("CHAT_MSG_ADDON")
messageFrame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
    if event == "CHAT_MSG_ADDON" and prefix == "LootSoundPlugin" and message == "PLAY_TRADE_SOUND" then
        Utils.debugPrint("Received trade sound request from:", sender)
        if State.isEnabled and State.sounds.trade then
            PlaySoundFileWithVolume(Config.SOUND_PATHS.TRADE, State.currentChannel, State.currentVolume)
    end
end)