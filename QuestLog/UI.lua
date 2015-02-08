--[[

Quest log
by CaptainBlagbird
https://github.com/CaptainBlagbird

--]]

-- Function to show the UI dialog box
function QuestLog.showDialog(remainingSec)
	if QuestLogUI:IsHidden() then
		QuestLogUI:SetHidden(false)
		QuestLogUI:SetTopmost(true)
	end
	
	if remainingSec >= 0 then
		-- Display countdown
		QuestLogUICountdownLabel:SetText(string.format("Reloading UI in |cFF0000%02d|r s", remainingSec))
	else
		-- Display busy player info
		QuestLogUICountdownLabel:SetText("|cFF0000Waiting before reloading UI while player is busy|r")
	end
end

-- Function to hide the UI dialog box
function QuestLog.hideDialog()
	if not QuestLogUI:IsHidden() then QuestLogUI:SetHidden(true) end
end

-- Event handler function, called after the UI was moved
function QuestLog.OnUIMoveStop()
	-- Store positions
	QuestLog.settings.position.x = QuestLogUI:GetLeft()
	QuestLog.settings.position.y = QuestLogUI:GetTop()
end

-- Function to restore the saved position of the dialog
function QuestLog:RestoreUIPosition()
	if QuestLog.settings.position == nil then QuestLog.settings.position = {} end
	-- Get stored positions
	local posX = QuestLog.settings.position.x
	local posY = QuestLog.settings.position.y
	
	QuestLogUI:ClearAnchors()
	if posX ~= nil or posY ~= nil then
		-- Set position
		QuestLogUI:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, posX, posY)
	else
		-- Set start position
		QuestLogUI:SetAnchor(CENTER, GuiRoot, CENTER, 0, -200)
	end
end

-- Function that gets called when the reload button was clicked
function QuestLog.OnButtonReloadClicked()
	QuestLog.timer["dialogCountdown"].enabled = false
	if not QuestLog.isPlayerBusy() then QuestLog.hideDialog() end
	ReloadUI()
end

-- Function that gets called when the cancel button was clicked
function QuestLog.OnButtonCancelClicked()
	QuestLog.timer["dialogCountdown"].enabled = false
	QuestLog.unregisterBusyEvents(QuestLog.name .. "SavelyReloadUI")
	QuestLog.hideDialog()
end

-- Reloads UI now (when player not busy), or as soon as player is ready again
function SavelyReloadUI()
	-- Check if it's save to reload UI
	if QuestLog.isPlayerBusy() then
		-- Register events to reload UI detect when player not busy anymore
		QuestLog.registerBusyEvents(QuestLog.name .. "SavelyReloadUI", OnPlayerBusyChangedAfterDialog)
	else
		-- Reload now so the file is written
		ReloadUI()
	end
end