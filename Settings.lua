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
				text = "The UI has to be reloaded in order to save the log file instantly. Normally the file is written when logging out, but if the game crashes before that, all logging of the session would lost.",
				width = "full",
			},
			[3] = {
				type = "description",
				text = "Because of that, |c70C0DEQuestLog|r will display a dialog box with a countdown when you complete a quest. When the countdown runs out, the UI will be reloaded automatically. The dialog box also gives you the option to reload the UI instantly or to cancel the countdown.",
				width = "full",
			},
			[4] = {
				type = "description",
				text = "This addon will never reload the UI while the player is in combat, it will wait until after combat!",
				width = "full",
			},
			[4] = {
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
		type = "header",
		name = "",
		width = "full",
	},
	[5] = {
		type = "description",
		text = "|cFF0000Clear log file for current character:|r",
		width = "half",
	},
	[6] = {
		type = "button",
		name = "Clear log file",
		tooltip = "Are you sure?",
		func = function()
					QuestLog.savedVariables.log = nil
					ReloadUI()
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