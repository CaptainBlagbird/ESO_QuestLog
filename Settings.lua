--[[

Quest log
by CaptainBlagbird
https://github.com/CaptainBlagbird

Note: This file is optional, it is used for the settings menu using the LAM library (LibAddonMenu).
--]]

local panelData = {
	type = "panel",
	name = "QuestLog",
	displayName = "|c70C0DEQuestLog|r",
	author = "|c70C0DECaptainBlagbird|r",
	version = "1.0",
	slashCommand = "/questlog",	--(optional) will register a keybind to open to this panel
	registerForRefresh = true,	--boolean (optional) (will refresh all options controls when a setting is changed and when the panel is shown)
	registerForDefaults = true,	--boolean (optional) (will set all options controls back to default values)
}

local optionsTable = {
	[1] = {
		type = "submenu",
		name = "Information, please read",
		controls = {
			[1] = {
				type = "description",
				title = "Information",
				text = "The log file can be found in the following file:\r\n|cADADADElder Scrolls Online \\ live<eu> \\ SavedVariables \\ QuestLog.lua|r",
				width = "full",
			},
			[2] = {
				type = "description",
				title = "|cFF0000Please read|r",
				text = "The UI has to be reloaded in order to save the log file instantly. Normally the file is written when logging out, but if the game crashes before that, all logging of the session would be lost.",
				width = "full",
			},
			[3] = {
				type = "description",
				text = "Because of that, |c70C0DEQuestLog|r will display a dialog box with a countdown when you complete a quest. When the countdown runs out, the UI will be reloaded automatically. The dialog box also gives you the option to reload the UI instantly or to cancel the countdown.",
				width = "full",
			},
			[4] = {
				type = "description",
				text = "This addon will never reload the UI while the player is busy (in combat/dialog/menu), it will wait until player is ready!",
				width = "full",
			},
			[5] = {
				type = "description",
				title = "Note",
				text = "You can always manually reload the UI with the chat command |cC5C29E/reloadui|r",
				width = "full",
			},
		},
	
	},
	[2] = {
		type = "slider",
		name = "Auto reload UI countdown time [s]",
		tooltip = "-1 to disable (no auto UI reload)",
		min = -1,
		max = 120,
		step = 1,
		getFunc = function() return QuestLog.settings.countdownTimeS end,
		setFunc = function(value) QuestLog.settings.countdownTimeS = value end,
		width = "full",
		default = 30,
	},
	[3] = {
		type = "checkbox",
		name = "Auto share new quests with group",
		tooltip = "When on, you'll automatically share the quest with the members of your current group so they can decide if they want to start the quest too",
		getFunc = function() return QuestLog.settings.questShareEnabled end,
		setFunc = function(value) QuestLog.settings.questShareEnabled = value end,
		default = true,
		width = "full",
	},
	[4] = {
		type = "description",
		title = "Position of the dialog box",
		text = "",
		width = "half",
	},
	[5] = {
		type = "button",
		name = "Reset",
		tooltip = "Reset to default position",
		func = function()
				QuestLog.settings.position = {}
				QuestLog:RestoreUIPosition()
				end,
		width = "half",
	},
	[6] = {
		type = "header",
		name = "",
		width = "full",
	},
	[7] = {
		type = "description",
		text = "\r\n \r\n \r\n \r\n ",
		width = "full",
	},
	[8] = {
		type = "description",
		text = "\r\n ",
		width = "full",
	},
	[9] = {
		type = "description",
		title = "Clear log for current character",
		text = "Type 'yes' to confirm",
		width = "half",
	},
	[10] = {
		type = "editbox",
		name = " ",
		tooltip = "Confirm log file clearing",
		getFunc = function() return "" end,
		setFunc = function(text) QuestLog.temp = text end,
		isMultiline = false,
		width = "half",
		default = "",
	},
	[11] = {
		type = "description",
		text = "|cFF0000Previously completed quests cannot be added again!|r",
		width = "half",
	},
	[12] = {
		type = "button",
		name = "Clear log file",
		tooltip = "Are you really sure?",
		func = function()
					if QuestLog.temp == "yes" then
						QuestLog.savedVariables.log = nil
						QuestLog.temp = nil
						ReloadUI()
					end
				end,
		width = "half",
		warning = "This cannot be undone!\r\nWill need to reload the UI.",
	},
}

-- Only use LibAddonMenu if it's available
if LibStub ~= nil then
	local LAM = LibStub("LibAddonMenu-2.0")
	LAM:RegisterAddonPanel("MyAddon", panelData)
	LAM:RegisterOptionControls("MyAddon", optionsTable)
end