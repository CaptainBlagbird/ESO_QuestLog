--[[

Helmet Toggle
by CaptainBlagbird
https://github.com/CaptainBlagbird

--]]

-- Namespace for the addon (top-level table) that will hold everything
QuestLog = {}
-- Addon info
QuestLog.name = "QuestLog"
-- Other info
QuestLog.init = false
QuestLog.msgColor = "70C0DE"
QuestLog.msgPrefix = "|r|c" .. QuestLog.msgColor .. "[" .. QuestLog.name .. "] |r|cFFFF00"
QuestLog.timer = {}
QuestLog.timer.enabled = false
 
-- Initialisations
function QuestLog:Init()
	-- Set up SavedVariables object
	self.savedVariables = ZO_SavedVars:New("QuestLogSavedVariables", 1, nil, {})
	if QuestLog.savedVariables.log == nil then QuestLog.savedVariables.log = {} end
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

-- Function to start the timer
function QuestLog.timer.start(ms)
	QuestLog.timer.startTimeStamp = GetGameTimeMilliseconds()
	QuestLog.timer.durationMs = ms
	QuestLog.timer.enabled = true
end

-- Function to check if timer finished
function QuestLog.timer.finished()
	if GetGameTimeMilliseconds() >= QuestLog.timer.startTimeStamp + QuestLog.timer.durationMs then
		QuestLog.timer.enabled = false
		return true
	end
end

-- Event handler function, called when the UI gets updated
function QuestLog.OnUIUpdate()
	if not QuestLog.timer.enabled then return end
	if QuestLog.timer.finished() then
		d('bla')
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
	QuestLog.savedVariables.log[GetDateTimeString()] = msg
	QuestLog:Print(msg)
	-- Auto share quest with group
	if GetIsQuestSharable(index) then
		ShareQuest(index)
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
	local msg = "Quest complete (level=" .. lvl .. ", rank=" .. rnk .."): " .. name
	QuestLog.savedVariables.log[GetDateTimeString()] = msg
	
	-- Check if it's save to reload UI
	if IsUnitInCombat("player") then
		-- Register combat event to reload UI after combat
		EVENT_MANAGER:RegisterForEvent(QuestLog.name, EVENT_PLAYER_COMBAT_STATE, QuestLog.OnCombatStateChanged)
	else
		-- Reload now so the file is written
		ReloadUI()
	end
	QuestLog:Print(msg)
end

-- Event handler function for EVENT_PLAYER_COMBAT_STATE
function QuestLog.OnCombatStateChanged(event, inCombat)
	-- Check if left combat
	if not inCombat then
		-- Now it's save to reload the UI so the file is written
		ReloadUI()
		-- We don't need the event anymore, unregister it
		EVENT_MANAGER:UnregisterForEvent(test.name, EVENT_PLAYER_COMBAT_STATE)
	end
end

-- Registering the event handler functions for the events
EVENT_MANAGER:RegisterForEvent(QuestLog.name, EVENT_ADD_ON_LOADED,    QuestLog.OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(QuestLog.name, EVENT_PLAYER_ACTIVATED, QuestLog.OnPlayerActivated)
EVENT_MANAGER:RegisterForEvent(QuestLog.name, EVENT_QUEST_ADDED,      QuestLog.OnQuestAdded)
EVENT_MANAGER:RegisterForEvent(QuestLog.name, EVENT_QUEST_REMOVED,    QuestLog.OnQuestRemoved)
EVENT_MANAGER:RegisterForEvent(QuestLog.name, EVENT_QUEST_COMPLETE,   QuestLog.OnQuestComplete)