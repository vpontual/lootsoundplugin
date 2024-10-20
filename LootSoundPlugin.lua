local addonName = "LootSoundPlugin"
local addonVersion = "1.0"

local playerGUID = UnitGUID("player")
local SOUND_PATH = "Interface\\AddOns\\LootSoundPlugin\\sounds\\treasure.ogg"
local SOUND_CHANNEL = "Master"

function LootSoundPlugin:OnLoad()
  self.name = addonName
  self.version = addonVersion

  -- Registering the event handler for loot pickup
  self:RegisterEvent("LOOT_PICKED_UP")
end

function LootSoundPlugin:OnEvent(event, ...)
  if event == "LOOT_PICKED_UP" then
    local _, _, _, sourceGUID = select(4, ...)
    if sourceGUID == playerGUID then
      -- Playing the sound using PlaySoundFile()
      PlaySoundFile(SOUND_PATH, SOUND_CHANNEL)
    end
  end
end