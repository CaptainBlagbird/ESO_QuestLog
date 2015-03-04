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
-- Local variables
local ZONE_INDEX_CYRODIIL = 38
 
-- Initialisations
function QuestLog:Init()
	-- Set up SavedVariables object (only for quest log data)
	QuestLog.QuestLogFile = ZO_SavedVars:New("QuestLogFile", 1, nil, {})
	if QuestLog.QuestLogFile.log == nil then QuestLog.QuestLogFile.log = {} end
	
	-- Set up SavedVariables object (for settings)
	QuestLog.settings = ZO_SavedVars:New("QuestLogSettings", 1, nil, {})
	if QuestLog.settings.countdownTimeS == nil then QuestLog.settings.countdownTimeS = 30 end
	if QuestLog.settings.questShareEnabled == nil then QuestLog.settings.questShareEnabled = false end
	if QuestLog.settings.displayInCyrodiil == nil then QuestLog.settings.displayInCyrodiil = false end
	
	-- -- Restore position
	QuestLog:RestoreUIPosition()
	
	QuestLog.hideDialog()
end

-- Print
function QuestLog:Print(str)
	d(QuestLog.msgPrefix .. str)
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

-- Check if player busy
function QuestLog.isPlayerBusy()
	return IsUnitInCombat("player") or IsReticleHidden() or IsInteractionCameraActive() or GetNumLootItems() > 0
end
-- Register all events that are used to check if player still busy
function QuestLog.registerBusyEvents(registerName, func)
	EVENT_MANAGER:RegisterForEvent(registerName, EVENT_PLAYER_COMBAT_STATE,   func)
	EVENT_MANAGER:RegisterForEvent(registerName, EVENT_RETICLE_HIDDEN_UPDATE, func)
	EVENT_MANAGER:RegisterForEvent(registerName, EVENT_CHATTER_END,           func)
	EVENT_MANAGER:RegisterForEvent(registerName, EVENT_LOOT_CLOSED,           func)
end
-- Register all events that are used to check if player still busy
function QuestLog.unregisterBusyEvents(registerName)
	EVENT_MANAGER:UnregisterForEvent(registerName, EVENT_PLAYER_COMBAT_STATE)
	EVENT_MANAGER:UnregisterForEvent(registerName, EVENT_RETICLE_HIDDEN_UPDATE)
	EVENT_MANAGER:UnregisterForEvent(registerName, EVENT_CHATTER_END)
	EVENT_MANAGER:UnregisterForEvent(registerName, EVENT_LOOT_CLOSED)
end

-- Event handler function for 'player busy' events (before countdown dialog)
function OnPlayerBusyChangedBeforeDialog(event)
	-- Check if busy
	if not QuestLog.isPlayerBusy() then
		-- Start countdown for UI reloading
		QuestLog.timer.start("dialogCountdown", QuestLog.settings.countdownTimeS*1000)
		-- We don't need the events anymore, unregister it
		QuestLog.unregisterBusyEvents(QuestLog.name .. "WaitBeforeDialog")
	end
end

-- Event handler function for 'player busy' events (after countdown dialog)
function OnPlayerBusyChangedAfterDialog(event)
	-- Check if busy
	if not QuestLog.isPlayerBusy() then
		-- Wait another 2 seconds and then reload the UI (in the timer function)
		QuestLog.timer.start("postCombatDelay", 2000)
		-- We don't need the events anymore, unregister it
		QuestLog.unregisterBusyEvents(QuestLog.name .. "SavelyReloadUI")
	end
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
	QuestLog.QuestLogFile.log[GetDateTimeString()] = msg .. " @ " .. GetPlayerLocationName() .. strPos
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
	QuestLog.QuestLogFile.log[GetDateTimeString()] = msg
	QuestLog:Print(msg)
end

-- Event handler function for
-- EVENT_QUEST_COMPLETE (integer eventCode, string questName, integer level, integer previousXP, integer currentXP, integer rank, integer previousPoints, integer currentPoints) 
function QuestLog.OnQuestComplete(event, name, lvl, pXP, cXP, rnk, pPoints, cPoints)
	local msg = "Quest complete: " .. name
	local posX, posY = GetMapPlayerPosition("player")
	local strPos = string.format(" (%1.1f, %1.1f)", posX*100, posY*100)
	QuestLog.QuestLogFile.log[GetDateTimeString()] = msg .. " @ " .. GetPlayerLocationName() .. strPos
	QuestLog:Print(msg)
	
	-- Check value: Negative = disabled
	if QuestLog.settings.countdownTimeS >= 0 then
		-- Check setting for Cyrodiil
		if GetCurrentMapZoneIndex() ~= ZONE_INDEX_CYRODIIL or QuestLog.settings.displayInCyrodiil then
			if not QuestLog.isPlayerBusy() then
				-- Start countdown for UI reloading
				QuestLog.timer.start("dialogCountdown", QuestLog.settings.countdownTimeS*1000)
			else
				-- Register events to reload UI when player not busy anymore
				QuestLog.registerBusyEvents(QuestLog.name .. "WaitBeforeDialog", OnPlayerBusyChangedBeforeDialog)
			end
		end
	end
end

-- Registering the event handler functions for the events
EVENT_MANAGER:RegisterForEvent(QuestLog.name, EVENT_ADD_ON_LOADED,    QuestLog.OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(QuestLog.name, EVENT_PLAYER_ACTIVATED, QuestLog.OnPlayerActivated)
EVENT_MANAGER:RegisterForEvent(QuestLog.name, EVENT_QUEST_ADDED,      QuestLog.OnQuestAdded)
EVENT_MANAGER:RegisterForEvent(QuestLog.name, EVENT_QUEST_REMOVED,    QuestLog.OnQuestRemoved)
EVENT_MANAGER:RegisterForEvent(QuestLog.name, EVENT_QUEST_COMPLETE,   QuestLog.OnQuestComplete)