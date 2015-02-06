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