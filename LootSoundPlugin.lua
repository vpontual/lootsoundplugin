local addonName, addon = ...
addon.version = "2.2.0"

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
        SOUND_VOLUME = 0.5,  -- 50% volume for sane default
        LOOT_SOUND = "TREASURE",
        DEBUG_MODE = false
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

-- Forward declaration for settings panel (defined at end of file)
local RegisterSettingsPanel

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
    activeSounds = {},

    -- Helper to play sound with volume control
    -- Uses CVar workaround since PlaySoundFile doesn't support volume parameter
    playSoundWithVolume = function(soundPath, channel, volume)
        if not soundPath then
            Utils.debugPrint("Error: No sound path provided")
            return false, nil
        end

        channel = channel or "Master"
        volume = volume or 1.0

        -- Clamp volume to valid range
        volume = math.max(0, math.min(1, volume))

        -- Map channel to CVar name
        local cvarMap = {
            Master = "Sound_MasterVolume",
            SFX = "Sound_SFXVolume",
            Music = "Sound_MusicVolume",
            Ambience = "Sound_AmbienceVolume",
            Dialog = "Sound_DialogVolume"
        }

        local cvarName = cvarMap[channel]
        if not cvarName then
            Utils.debugPrint("Invalid channel:", channel, "- using Master")
            cvarName = "Sound_MasterVolume"
            channel = "Master"
        end

        -- Store original volume
        local originalVolume = tonumber(GetCVar(cvarName)) or 1.0

        -- Set desired volume
        SetCVar(cvarName, volume)

        -- Play sound (only 2 parameters: sound, channel)
        local willPlay, soundHandle = PlaySoundFile(soundPath, channel)

        if willPlay and soundHandle then
            -- Track this sound to restore volume when it finishes
            SoundManager.activeSounds[soundHandle] = { vol = originalVolume, cvar = cvarName }
            Utils.debugPrint(string.format("Playing sound %s (handle: %s) on channel %s.", soundPath, soundHandle, channel))
        else
            -- Sound didn't play, restore volume immediately
            Utils.debugPrint("Warning: Sound did not play -", soundPath, "Restoring volume immediately.")
            SetCVar(cvarName, originalVolume)
        end

        return willPlay, soundHandle
    end,

    playRandomVendorSound = function()
        if not State.sounds.vendor then return end
        local paths = Config.SOUND_PATHS.VENDOR
        if #paths == 0 then
            Utils.debugPrint("No vendor sound paths configured.")
            return
        end
        local randomIndex = math.random(1, #paths)
        SoundManager.playSoundWithVolume(paths[randomIndex], State.currentChannel, State.currentVolume)
    end,

    getCurrentLootSound = function()
        return Config.SOUND_PATHS[State.currentLootSound]
    end,

    testSounds = function()
        Utils.debugPrint("Starting sound system test...")

        Utils.printMessage("Playing treasure sound...")
        SoundManager.playSoundWithVolume(Config.SOUND_PATHS.TREASURE, State.currentChannel, State.currentVolume)

        C_Timer.After(2, function()
            Utils.printMessage("Playing wow sound...")
            SoundManager.playSoundWithVolume(Config.SOUND_PATHS.WOW, State.currentChannel, State.currentVolume)
        end)

        C_Timer.After(4, function()
            Utils.printMessage("Playing vendor sound...")
            SoundManager.playRandomVendorSound()
        end)

        C_Timer.After(6, function()
            Utils.printMessage("Playing trade sound...")
            SoundManager.playSoundWithVolume(Config.SOUND_PATHS.TRADE, State.currentChannel, State.currentVolume)
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
EventManager:RegisterEvent("SOUNDKIT_FINISHED")


EventManager:SetScript("OnEvent", function(self, event, ...)
    Utils.debugPrint("Event fired:", event)

    if event == "PLAYER_LOGIN" then
        LootSoundDB = LootSoundDB or {} 
        
        -- Validate and load settings with type checking
        LootSoundDB.volume = (type(LootSoundDB.volume) == "number") and LootSoundDB.volume or Config.DEFAULTS.SOUND_VOLUME
        LootSoundDB.lootSound = (type(LootSoundDB.lootSound) == "string") and LootSoundDB.lootSound or Config.DEFAULTS.LOOT_SOUND
        LootSoundDB.channel = (type(LootSoundDB.channel) == "string") and LootSoundDB.channel or Config.DEFAULTS.SOUND_CHANNEL
        LootSoundDB.isEnabled = (LootSoundDB.isEnabled ~= nil) and LootSoundDB.isEnabled or true
        LootSoundDB.isDebug = (LootSoundDB.isDebug ~= nil) and LootSoundDB.isDebug or Config.DEFAULTS.DEBUG_MODE
        
        -- Validate sound table
        if type(LootSoundDB.sounds) ~= "table" then
            LootSoundDB.sounds = { loot = true, vendor = true, trade = true }
        else
            LootSoundDB.sounds.loot = (LootSoundDB.sounds.loot ~= nil) and LootSoundDB.sounds.loot or true
            LootSoundDB.sounds.vendor = (LootSoundDB.sounds.vendor ~= nil) and LootSoundDB.sounds.vendor or true
            LootSoundDB.sounds.trade = (LootSoundDB.sounds.trade ~= nil) and LootSoundDB.sounds.trade or true
        end

        State.currentVolume = LootSoundDB.volume
        State.currentLootSound = LootSoundDB.lootSound
        State.currentChannel = LootSoundDB.channel
        State.isEnabled = LootSoundDB.isEnabled
        State.sounds = LootSoundDB.sounds
        State.isDebug = LootSoundDB.isDebug

        addon.tradeAcceptedByBoth = false
        
        -- Register the settings panel now that the DB is loaded
        RegisterSettingsPanel()

        if State.isEnabled then
            Utils.printMessage(string.format("Addon v%s loaded! Type /lootsound help for commands.", addon.version))
        else
            Utils.printMessage(string.format("Addon v%s loaded! (Currently disabled)", addon.version))
        end
        self:UnregisterEvent("PLAYER_LOGIN") 
        return 
    end

    if event == "SOUNDKIT_FINISHED" then
        local soundHandle = ...
        local soundData = SoundManager.activeSounds[soundHandle]
        if soundData then
            Utils.debugPrint(string.format("Sound handle %s finished. Restoring volume on %s to %.2f.", soundHandle, soundData.cvar, soundData.vol))
            SetCVar(soundData.cvar, soundData.vol)
            SoundManager.activeSounds[soundHandle] = nil -- Clean up
        end
        return
    end

    if not State.isEnabled then 
        Utils.debugPrint("Addon disabled, ignoring event:", event)
        return 
    end
    
    if event == "LOOT_OPENED" then
        if State.sounds.loot then
            SoundManager.playSoundWithVolume(SoundManager.getCurrentLootSound(), State.currentChannel, State.currentVolume)
        end

    elseif event == "MERCHANT_SHOW" then
        if State.sounds.vendor then
            SoundManager.playRandomVendorSound()
        end

    elseif event == "MERCHANT_CLOSED" then
        Utils.debugPrint("Merchant window closed.")

    elseif event == "TRADE_ACCEPT_UPDATE" then
        local playerAccepted, targetAccepted = ...
        Utils.debugPrint("Trade accept status updated:", "Player:", playerAccepted, "Target:", targetAccepted)
        if playerAccepted == 1 and targetAccepted == 1 then
            addon.tradeAcceptedByBoth = true
            Utils.debugPrint("Both parties have accepted the trade.")
        else
            addon.tradeAcceptedByBoth = false
        end

    elseif event == "TRADE_CLOSED" then
        if addon.tradeAcceptedByBoth then
            Utils.debugPrint("Trade successful, playing sound.")
            if State.sounds.trade then
                SoundManager.playSoundWithVolume(Config.SOUND_PATHS.TRADE, State.currentChannel, State.currentVolume)
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

function addon:ResetToDefaults()
    State.currentVolume = Config.DEFAULTS.SOUND_VOLUME
    State.currentLootSound = Config.DEFAULTS.LOOT_SOUND
    State.currentChannel = Config.DEFAULTS.SOUND_CHANNEL
    State.isEnabled = true
    State.sounds = { loot = true, vendor = true, trade = true }
    State.isDebug = Config.DEFAULTS.DEBUG_MODE

    if LootSoundDB then
        LootSoundDB.volume = State.currentVolume
        LootSoundDB.lootSound = State.currentLootSound
        LootSoundDB.channel = State.currentChannel
        LootSoundDB.isEnabled = State.isEnabled
        LootSoundDB.sounds = State.sounds
        LootSoundDB.isDebug = State.isDebug
    end

    Utils.printMessage("Settings reset to defaults")
    Utils.printMessage("Please reload UI (/reload) to refresh settings panel")
end

-- Slash commands
local function HandleSlashCommands(msg)
    local args = {}
    for arg in msg:gmatch("%S+") do
        table.insert(args, string.lower(arg))
    end
    
    if #args == 0 or args[1] == "help" then
        Utils.printMessage("Available commands:")
        Utils.printMessage("Tip: You can also access settings via ESC > Interface > AddOns > LootSound")
        Utils.printMessage("/lootsound config - Open settings panel")
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
        Utils.printMessage("/lootsound reset - Reset all settings to defaults")
        return
    end

    local command = args[1]
    local value = args[2]

    if command == "config" or command == "settings" or command == "options" then
        -- Open settings panel
        if addon.settingsCategory then
            Settings.OpenToCategory(addon.settingsCategory:GetID())
        else
            -- Fallback for legacy or if registration failed
            if Settings and Settings.OpenToCategory then
                 Settings.OpenToCategory("LootSound")
            elseif InterfaceOptionsFrame_OpenToCategory then
                 InterfaceOptionsFrame_OpenToCategory("LootSound")
            end
        end
    elseif command == "volume" and value then
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
        Utils.printMessage(string.format("Volume: %.2f (%.0f%%)", State.currentVolume, State.currentVolume * 100))
        Utils.printMessage(string.format("Channel: %s", State.currentChannel))
        Utils.printMessage(string.format("Loot Sound: %s", State.currentLootSound))
        Utils.printMessage(string.format("Loot sounds: %s", Utils.getToggleState(State.sounds.loot)))
        Utils.printMessage(string.format("Vendor sounds: %s", Utils.getToggleState(State.sounds.vendor)))
        Utils.printMessage(string.format("Trade sounds: %s", Utils.getToggleState(State.sounds.trade)))
        Utils.printMessage(string.format("Debug mode: %s", Utils.getToggleState(State.isDebug)))
    elseif command == "debug" then
        addon:ToggleDebug(not State.isDebug)
    elseif command == "reset" then
        addon:ResetToDefaults()
    else
        Utils.printMessage("Unknown command. Type /lootsound help for usage.", true)
    end
end

SLASH_LOOTSOUND1 = "/lootsound"
SlashCmdList["LOOTSOUND"] = HandleSlashCommands

-- Settings Panel
RegisterSettingsPanel = function()
    -- 1. Create the Panel Frame
    local panel = CreateFrame("Frame", "LootSoundSettingsPanel")
    panel.name = "LootSound"
    
    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("LootSound Plugin Settings")

    -- Version
    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    version:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    version:SetText("Version " .. addon.version)

    -- Enable Checkbox
    local enabledCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    enabledCheckbox:SetPoint("TOPLEFT", version, "BOTTOMLEFT", 0, -16)
    enabledCheckbox.Text:SetText("Enable LootSound")
    enabledCheckbox:SetChecked(State.isEnabled)
    enabledCheckbox:SetScript("OnClick", function(self) addon:ToggleAddon(self:GetChecked()) end)

    -- Volume Slider
    local volumeSlider = CreateFrame("Slider", "LootSoundVolumeSlider", panel, "OptionsSliderTemplate")
    volumeSlider:SetPoint("TOPLEFT", enabledCheckbox, "BOTTOMLEFT", 0, -32)
    volumeSlider:SetWidth(200)
    volumeSlider:SetMinMaxValues(0, 1)
    volumeSlider:SetValue(State.currentVolume)
    volumeSlider:SetObeyStepOnDrag(true)
    volumeSlider:SetValueStep(0.05)
    _G[volumeSlider:GetName() .. 'Low']:SetText('0%')
    _G[volumeSlider:GetName() .. 'High']:SetText('100%')
    _G[volumeSlider:GetName() .. 'Text']:SetText('Volume: ' .. math.floor(State.currentVolume * 100) .. '%')
    volumeSlider:SetScript("OnValueChanged", function(self, value)
        addon:SetVolume(value)
        _G[self:GetName() .. 'Text']:SetText('Volume: ' .. math.floor(value * 100) .. '%')
    end)

    -- Channel Dropdown (Modern API)
    local channelLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    channelLabel:SetPoint("TOPLEFT", volumeSlider, "BOTTOMLEFT", 0, -24)
    channelLabel:SetText("Sound Channel:")

    local channelDropdown = CreateFrame("DropdownButton", nil, panel, "WowStyle1DropdownTemplate")
    channelDropdown:SetPoint("LEFT", channelLabel, "RIGHT", 10, 0)
    channelDropdown:SetSize(150, 25)
    channelDropdown:SetText(State.currentChannel)
    channelDropdown:SetupMenu(function(dropdown, rootDescription)
        rootDescription:CreateButton("Master", function() 
            addon:SetChannel("Master")
            dropdown:SetText("Master")
        end)
        rootDescription:CreateButton("SFX", function() 
            addon:SetChannel("SFX")
            dropdown:SetText("SFX")
        end)
    end)

    -- Loot Sound Dropdown (Modern API)
    local lootSoundLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lootSoundLabel:SetPoint("TOPLEFT", channelLabel, "BOTTOMLEFT", 0, -32)
    lootSoundLabel:SetText("Loot Sound:")

    local lootSoundDropdown = CreateFrame("DropdownButton", nil, panel, "WowStyle1DropdownTemplate")
    lootSoundDropdown:SetPoint("LEFT", lootSoundLabel, "RIGHT", 10, 0)
    lootSoundDropdown:SetSize(150, 25)
    lootSoundDropdown:SetText(State.currentLootSound:lower():gsub("^%l", string.upper))
    lootSoundDropdown:SetupMenu(function(dropdown, rootDescription)
        rootDescription:CreateButton("Treasure", function() 
            addon:SetLootSound("Treasure")
            dropdown:SetText("Treasure")
        end)
        rootDescription:CreateButton("Wow", function() 
            addon:SetLootSound("Wow") 
            dropdown:SetText("Wow")
        end)
    end)
    
    -- Sound Types
    local soundTypesLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    soundTypesLabel:SetPoint("TOPLEFT", lootSoundLabel, "BOTTOMLEFT", 0, -32)
    soundTypesLabel:SetText("Sound Types:")

    local lootSoundsCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    lootSoundsCheckbox:SetPoint("TOPLEFT", soundTypesLabel, "BOTTOMLEFT", 0, -8)
    lootSoundsCheckbox.Text:SetText("Loot sounds")
    lootSoundsCheckbox:SetChecked(State.sounds.loot)
    lootSoundsCheckbox:SetScript("OnClick", function(self) addon:ToggleSound("loot") end)

    local vendorSoundsCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    vendorSoundsCheckbox:SetPoint("TOPLEFT", lootSoundsCheckbox, "BOTTOMLEFT", 0, -8)
    vendorSoundsCheckbox.Text:SetText("Vendor sounds")
    vendorSoundsCheckbox:SetChecked(State.sounds.vendor)
    vendorSoundsCheckbox:SetScript("OnClick", function(self) addon:ToggleSound("vendor") end)

    local tradeSoundsCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    tradeSoundsCheckbox:SetPoint("TOPLEFT", vendorSoundsCheckbox, "BOTTOMLEFT", 0, -8)
    tradeSoundsCheckbox.Text:SetText("Trade sounds")
    tradeSoundsCheckbox:SetChecked(State.sounds.trade)
    tradeSoundsCheckbox:SetScript("OnClick", function(self) addon:ToggleSound("trade") end)
    
    -- Actions & Debug
    local actionsLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    actionsLabel:SetPoint("TOPLEFT", tradeSoundsCheckbox, "BOTTOMLEFT", 0, -24)
    actionsLabel:SetText("Actions & Debugging:")

    local debugCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")
    debugCheckbox:SetPoint("TOPLEFT", actionsLabel, "BOTTOMLEFT", 0, -8)
    debugCheckbox.Text:SetText("Debug Mode")
    debugCheckbox:SetChecked(State.isDebug)
    debugCheckbox:SetScript("OnClick", function(self) addon:ToggleDebug(self:GetChecked()) end)

    local testButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    testButton:SetPoint("TOPLEFT", debugCheckbox, "BOTTOMLEFT", 0, -16)
    testButton:SetSize(150, 25)
    testButton:SetText("Test Sounds")
    testButton:SetScript("OnClick", function() SoundManager.testSounds() end)

    local resetButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetButton:SetPoint("LEFT", testButton, "RIGHT", 10, 0)
    resetButton:SetSize(150, 25)
    resetButton:SetText("Reset to Defaults")
    resetButton:SetScript("OnClick", function() addon:ResetToDefaults() end)
    
    -- Description
    local descText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    descText:SetPoint("TOPLEFT", testButton, "BOTTOMLEFT", 0, -20)
    descText:SetWidth(500)
    descText:SetJustifyH("LEFT")
    descText:SetText("Volume control temporarily adjusts the selected channel's volume when sounds play.\nUse /lootsound help for all available commands.")

    -- 2. Register the Panel with the new Settings API
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category, layout = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        addon.settingsCategory = category
    else
        -- Fallback for very old clients (unlikely given .toc but safe)
        if InterfaceOptions_AddCategory then
            InterfaceOptions_AddCategory(panel)
        end
    end
end
