local addonName = "LootSoundPlugin"
local addonVersion = "1.0"

function LootSoundPlugin:OnLoad()
    self.name = addonName
    self.version = addonVersion
    self.soundFile = "sounds/treasure.ogg"

    -- Registering the event handler for loot pickup
    self:RegisterEvent("LOOT_PICKED_UP")
end

function LootSoundPlugin:OnEvent(event)
    if event == "LOOT_PICKED_UP" then
        -- Playing the sound using PlaySound()
        PlaySound(self.soundFile)
    end
end