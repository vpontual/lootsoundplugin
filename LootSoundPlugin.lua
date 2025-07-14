local addonName, addon = ...
addon.version = "2.1.0"

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
        LOOT_SOUND = "TREASURE",
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
    isDebug = false, -- Initialized from LootSoundDB on PLAYER_LOGIN
    sounds = {
        loot = true,
        vendor = true,
        trade = true
    }
}

-- Utility functions
local Utils = {
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
        if #paths == 0 then 
            Utils.debugPrint("No vendor sound paths configured.")
            return 
        end
        local randomIndex = math.random(1, #paths)
        -- Corrected API call
        PlaySoundFile(paths[randomIndex], State.currentChannel, nil, State.currentVolume)
    end,
    
    getCurrentLootSound = function()
        return Config.SOUND_PATHS[State.currentLootSound]
    end,

    testSounds = function()
        Utils.debugPrint("Starting sound system test...")
        
        Utils.printMessage("Playing treasure sound...")
        -- Corrected API call
        PlaySoundFile(Config.SOUND_PATHS.TREASURE, State.currentChannel, nil, State.currentVolume)
        
        C_Timer.After(2, function()
            Utils.printMessage("Playing wow sound...")
            -- Corrected API call
            PlaySoundFile(Config.SOUND_PATHS.WOW, State.currentChannel, nil, State.currentVolume)
        end)
        
        C_Timer.After(4, function()
            Utils.printMessage("Playing vendor sound...")
            SoundManager.playRandomVendorSound() -- This will use the corrected call internally
        end)
        
        C_Timer.After(6, function()
            Utils.printMessage("Playing trade sound...")
            -- Corrected API call
            PlaySoundFile(Config.SOUND_PATHS.TRADE, State.currentChannel, nil, State.currentVolume)
        end)
    end
}

-- Event handling
local EventManager = CreateFrame("Frame")
EventManager:RegisterEvent("PLAYER_LOGIN") 
EventManager:RegisterEvent("LOOT_OPENED")
EventManager:RegisterEvent("MERCHANT_SHOW")
EventManager:RegisterEvent("MERCHANT_CLOSED")
EventManager:RegisterEvent("TRADE_ACCEPT_UPDATE")
EventManager:RegisterEvent("TRADE_CLOSED")


EventManager:SetScript("OnEvent", function(self, event, ...)
    Utils.debugPrint("Event fired:", event)

    if event == "PLAYER_LOGIN" then
        LootSoundDB = LootSoundDB or {} 
        LootSoundDB.volume = LootSoundDB.volume or Config.DEFAULTS.SOUND_VOLUME
        LootSoundDB.lootSound = LootSoundDB.lootSound or Config.DEFAULTS.LOOT_SOUND
        LootSoundDB.channel = LootSoundDB.channel or Config.DEFAULTS.SOUND_CHANNEL
        LootSoundDB.isEnabled = LootSoundDB.isEnabled == nil and true or LootSoundDB.isEnabled 
        LootSoundDB.sounds = LootSoundDB.sounds or { loot = true, vendor = true, trade = true }
        LootSoundDB.isDebug = LootSoundDB.isDebug == nil and Config.DEFAULTS.DEBUG_MODE or LootSoundDB.isDebug

        State.currentVolume = LootSoundDB.volume
        State.currentLootSound = LootSoundDB.lootSound
        State.currentChannel = LootSoundDB.channel
        State.isEnabled = LootSoundDB.isEnabled
        State.sounds = LootSoundDB.sounds
        State.isDebug = LootSoundDB.isDebug

        addon.tradeAcceptedByBoth = false

        if State.isEnabled then
            Utils.printMessage(string.format("Addon v%s loaded! Type /lootsound help for commands.", addon.version))
        else
            Utils.printMessage(string.format("Addon v%s loaded! (Currently disabled)", addon.version))
        end
        self:UnregisterEvent("PLAYER_LOGIN") 
        return 
    end

    if not State.isEnabled then 
        Utils.debugPrint("Addon disabled, ignoring event:", event)
        return 
    end
    
    if event == "LOOT_OPENED" then
        if State.sounds.loot then
            -- Corrected API call
            PlaySoundFile(SoundManager.getCurrentLootSound(), State.currentChannel, nil, State.currentVolume)
        end

    elseif event == "MERCHANT_SHOW" then
        if State.sounds.vendor then
            SoundManager.playRandomVendorSound() -- Uses corrected call internally
        end

    elseif event == "MERCHANT_CLOSED" then
        Utils.debugPrint("Merchant window closed.")

    elseif event == "TRADE_ACCEPT_UPDATE" then
        local playerAccepted, targetAccepted = ...
        Utils.debugPrint("Trade accept status updated:", "Player:", playerAccepted, "Target:", targetAccepted)
        if playerAccpeted == 1 and targetAccepted == 1 then
            addon.tradeAcceptedByBoth = true
            Utils.debugPrint("Both parties have accepted the trade.")
        else
            addon.tradeAcceptedByBoth = false
        end
    
    elseif event == "TRADE_CLOSED" then
        if addon.tradeAcceptedByBoth then
            Utils.debugPrint("Trade successful, playing sound.")
            if State.sounds.trade then
                PlaySoundFile(Config.SOUND_PATHS.TRADE, State.currentChannel, nil, State.currentVolume)
            end
        else
            Utils.debugPrint("Trade cancelled or closed before full acceptance.")
        end
        addon.tradeAcceptedByBoth = false 
    end
end)

-- Addon API
function addon:SetVolume(volume)
    if not Utils.validateVolume(volume) then
        Utils.printMessage("Invalid volume value. Please use a number between 0 and 1.", true)
        return
    end
    State.currentVolume = volume
    if LootSoundDB then LootSoundDB.volume = volume end
    Utils.printMessage(string.format("Volume set to %.2f", volume))
end

function addon:SetChannel(channel)
    channel = string.upper(channel)
    if channel ~= "MASTER" and channel ~= "SFX" then
        Utils.printMessage("Invalid channel. Use 'master' or 'sfx'.", true)
        return
    end
    State.currentChannel = channel
    if LootSoundDB then LootSoundDB.channel = channel end
    Utils.printMessage("Sound channel set to " .. channel)
end

function addon:SetLootSound(soundType)
    soundType = string.upper(soundType)
    if not Config.SOUND_PATHS[soundType] then
        Utils.printMessage("Invalid sound type. Use 'wow' or 'treasure'.", true)
        return
    end
    State.currentLootSound = soundType
    if LootSoundDB then LootSoundDB.lootSound = soundType end
    Utils.printMessage("Loot sound set to " .. soundType)
end

function addon:ToggleAddon(enabled)
    State.isEnabled = enabled
    if LootSoundDB then LootSoundDB.isEnabled = enabled end
    Utils.printMessage(string.format("Addon %s", Utils.getToggleState(enabled)))
end

function addon:ToggleSound(soundType)
    soundType = string.lower(soundType)
    if State.sounds[soundType] == nil then 
        Utils.printMessage("Invalid sound type. Use 'loot', 'vendor', or 'trade'.", true)
        return
    end
    
    State.sounds[soundType] = not State.sounds[soundType]
    if LootSoundDB and LootSoundDB.sounds then LootSoundDB.sounds[soundType] = State.sounds[soundType] end
    
    Utils.printMessage(string.format("%s sounds %s", 
        soundType:gsub("^%l", string.upper), 
        Utils.getToggleState(State.sounds[soundType])
    ))
end

function addon:ToggleDebug(enabled)
    State.isDebug = enabled
    if LootSoundDB then LootSoundDB.isDebug = enabled end
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
        Utils.printMessage("/lootsound channel <master or sfx> - Set sound channel")
        Utils.printMessage("/lootsound sound <wow or treasure> - Set loot sound")
        Utils.printMessage("/lootsound toggle - Enable or disable all sounds")
        Utils.printMessage("/lootsound loot - Toggle loot sounds")
        Utils.printMessage("/lootsound vendor - Toggle vendor sounds")
        Utils.printMessage("/lootsound trade - Toggle trade sounds")
        Utils.printMessage("/lootsound test - Test all sounds")
        Utils.printMessage("/lootsound status - Show current settings")
        Utils.printMessage("/lootsound debug - Toggles debug messages")
        return
    end
    
    local command = args[1]
    local value = args[2] 

    if command == "volume" and value then
        addon:SetVolume(tonumber(value))
    elseif command == "channel" and value then
        addon:SetChannel(value)
    elseif command == "sound" and value then
        addon:SetLootSound(value)
    elseif command == "toggle" then
        addon:ToggleAddon(not State.isEnabled)
    elseif command == "test" then
        SoundManager.testSounds()
    elseif command == "loot" or command == "vendor" or command == "trade" then
        addon:ToggleSound(command) 
    elseif command == "status" then
        Utils.printMessage(string.format("Addon: %s", Utils.getToggleState(State.isEnabled)))
        Utils.printMessage(string.format("Volume: %.2f", State.currentVolume))
        Utils.printMessage(string.format("Channel: %s", State.currentChannel))
        Utils.printMessage(string.format("Loot Sound: %s", State.currentLootSound))
        Utils.printMessage(string.format("Loot sounds: %s", Utils.getToggleState(State.sounds.loot)))
        Utils.printMessage(string.format("Vendor sounds: %s", Utils.getToggleState(State.sounds.vendor)))
        Utils.printMessage(string.format("Trade sounds: %s", Utils.getToggleState(State.sounds.trade)))
        Utils.printMessage(string.format("Debug mode: %s", Utils.getToggleState(State.isDebug)))
    elseif command == "debug" then
        addon:ToggleDebug(not State.isDebug)
    else
        Utils.printMessage("Unknown command. Type /lootsound help for usage.", true)
    end
end

SLASH_LOOTSOUND1 = "/lootsound" 
SlashCmdList["LOOTSOUND"] = HandleSlashCommands
