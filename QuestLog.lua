--[[

Quest log
by CaptainBlagbird
https://github.com/CaptainBlagbird

--]]

-- Namespace for the addon (top-level table) that will hold everything
QuestLog = {}
-- Addon info
QuestLog.name = "QuestLog"
-- Other variables
QuestLog.init = false
QuestLog.msgColor = "70C0DE"
QuestLog.msgPrefix = "|r|c" .. QuestLog.msgColor .. "[" .. QuestLog.name .. "] |r|cFFFF00"
 
-- Initialisations
function QuestLog:Init()
	-- Set up SavedVariables object (only for quest log data)
	QuestLog.savedVariables = ZO_SavedVars:New("QuestLogFile", 1, nil, {})
	if QuestLog.savedVariables.log == nil then QuestLog.savedVariables.log = {} end
	
	-- Set up SavedVariables object (for settings)
	QuestLog.settings = ZO_SavedVars:New("QuestLogSettings", 1, nil, {})
	if QuestLog.settings.countdownTimeS == nil then QuestLog.settings.countdownTimeS = 30 end
	if QuestLog.settings.questShareEnabled == nil then QuestLog.settings.questShareEnabled = true end
	
	QuestLog.hideDialog()
end

-- Print
function QuestLog:Print(str)
	d(QuestLog.msgPrefix .. str)
end

-- Check if player busy
function QuestLog.isPlayerBusy()
	return IsUnitInCombat("player") or IsReticleHidden() or IsInteractionCameraActive() or GetNumLootItems() > 0
end
-- Register all events that are used to check if player still busy
function QuestLog.registerBusyEvents(registerName)
	EVENT_MANAGER:RegisterForEvent(registerName, EVENT_PLAYER_COMBAT_STATE,   OnPlayerBusyChanged)
	EVENT_MANAGER:RegisterForEvent(registerName, EVENT_RETICLE_HIDDEN_UPDATE, OnPlayerBusyChanged)
	EVENT_MANAGER:RegisterForEvent(registerName, EVENT_CHATTER_END,           OnPlayerBusyChanged)
	EVENT_MANAGER:RegisterForEvent(registerName, EVENT_LOOT_CLOSED,           OnPlayerBusyChanged)
end
-- Register all events that are used to check if player still busy
function QuestLog.unregisterBusyEvents(registerName)
	EVENT_MANAGER:UnregisterForEvent(registerName, EVENT_PLAYER_COMBAT_STATE)
	EVENT_MANAGER:UnregisterForEvent(registerName, EVENT_RETICLE_HIDDEN_UPDATE)
	EVENT_MANAGER:UnregisterForEvent(registerName, EVENT_CHATTER_END)
	EVENT_MANAGER:UnregisterForEvent(registerName, EVENT_LOOT_CLOSED)
end

-- Get formated datetime string ("YYYY-MM-DD hh:mm:ss")
local function GetDateTimeString()
	-- Get the date as formated number and convert it to a string (with leading zeros)
	local yyyymmdd = string.format("%08d", GetDate())
	-- Extract substrings
	local year = string.sub(yyyymmdd, 1, 4)
	local mon  = string.sub(yyyymmdd, 5, 6)
	local day  = string.sub(yyyymmdd, 7, 8)
	-- Get the time as formated number and convert it to a string (with leading zeros)
	local hhmmss = string.format("%06d", GetFormattedTime())
	-- Extract substrings
	local h = string.sub(hhmmss, 1, 2)
	local m = string.sub(hhmmss, 3, 4)
	local s = string.sub(hhmmss, 5, 6)
	-- Get the game milliseconds as formated number and convert it to a string (with leading zeros)
	local gms = string.format("%03d", GetGameTimeMilliseconds())
	-- Extract substring
	local ms = string.sub(gms, -3, -1)
	-- Return string in ISO format
	return year .. "-" .. mon .. "-" .. day .. " " .. h .. ":" .. m .. ":" .. s .. "." .. ms
end

-- Event handler function for EVENT_ADD_ON_LOADED
function QuestLog.OnAddOnLoaded(event, addonName)
	-- Only continue if the loaded addon is this addon
	if addonName ~= QuestLog.name then return end

	-- Initialise addon
	QuestLog:Init()
	QuestLog.init = true
	EVENT_MANAGER:UnregisterForEvent(QuestLog.name, EVENT_ADD_ON_LOADED)
end

-- Event handler function for EVENT_PLAYER_ACTIVATED
function QuestLog.OnPlayerActivated(event)
	if QuestLog.init then
		QuestLog:Print("Ready")
		QuestLog.init = false
	end
	EVENT_MANAGER:UnregisterForEvent(QuestLog.name, EVENT_PLAYER_ACTIVATED)
end

-- Event handler function for
-- EVENT_QUEST_ADDED (integer eventCode, integer journalIndex, string questName, string objectiveName)
function QuestLog.OnQuestAdded(event, index, name, objective)
	local msg = "Quest added: " .. name
	local posX, posY = GetMapPlayerPosition("player")
	local strPos = string.format(" (%1.1f, %1.1f)", posX*100, posY*100)
	QuestLog.savedVariables.log[GetDateTimeString()] = msg .. " @ " .. GetPlayerLocationName() .. strPos
	QuestLog:Print(msg)
	-- Auto share quest with group
	if IsUnitGrouped("player") and QuestLog.settings.questShareEnabled and GetIsQuestSharable(index) then
		ShareQuest(index)
		QuestLog:Print("Quest shared with group")
	end
end

-- Event handler function for
-- EVENT_QUEST_REMOVED (integer eventCode, bool isCompleted, integer journalIndex, string questName, integer zoneIndex, integer poiIndex)
function QuestLog.OnQuestRemoved(event, isComplete, index, name, zone, poi)
	if isComplete then return end
	local msg = "Quest abandoned: " .. name
	QuestLog.savedVariables.log[GetDateTimeString()] = msg
	QuestLog:Print(msg)
end

-- Event handler function for
-- EVENT_QUEST_COMPLETE (integer eventCode, string questName, integer level, integer previousXP, integer currentXP, integer rank, integer previousPoints, integer currentPoints) 
function QuestLog.OnQuestComplete(event, name, lvl, pXP, cXP, rnk, pPoints, cPoints)
	local msg = "Quest complete: " .. name
	local posX, posY = GetMapPlayerPosition("player")
	local strPos = string.format(" (%1.1f, %1.1f)", posX*100, posY*100)
	QuestLog.savedVariables.log[GetDateTimeString()] = msg .. " @ " .. GetPlayerLocationName() .. strPos
	QuestLog:Print(msg)
	
	-- Check value: Negative = disabled
	if QuestLog.settings.countdownTimeS >= 0 then
	-- Start countdown for UI reloading
		QuestLog.timer.start("dialogCountdown", QuestLog.settings.countdownTimeS*1000)
	end
end

-- Registering the event handler functions for the events
EVENT_MANAGER:RegisterForEvent(QuestLog.name, EVENT_ADD_ON_LOADED,    QuestLog.OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(QuestLog.name, EVENT_PLAYER_ACTIVATED, QuestLog.OnPlayerActivated)
EVENT_MANAGER:RegisterForEvent(QuestLog.name, EVENT_QUEST_ADDED,      QuestLog.OnQuestAdded)
EVENT_MANAGER:RegisterForEvent(QuestLog.name, EVENT_QUEST_REMOVED,    QuestLog.OnQuestRemoved)
EVENT_MANAGER:RegisterForEvent(QuestLog.name, EVENT_QUEST_COMPLETE,   QuestLog.OnQuestComplete)