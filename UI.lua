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
		-- Display combat info
		QuestLogUICountdownLabel:SetText("|cFF0000Reloading UI after combat|r")
	end
end

-- Function to hide the UI dialog box
function QuestLog.hideDialog()
	if not QuestLogUI:IsHidden() then QuestLogUI:SetHidden(true) end
end

-- Function that gets called when the reload button was clicked
function QuestLog.OnButtonReloadClicked()
	QuestLog.timer["dialogCountdown"].enabled = false
	if not IsUnitInCombat("player") then QuestLog.hideDialog() end
	SavelyReloadUI()
end

-- Function that gets called when the cancel button was clicked
function QuestLog.OnButtonCancelClicked()
	QuestLog.timer["dialogCountdown"].enabled = false
	QuestLog.hideDialog()
end

-- Reloads UI now (when player not in combat), or as soon as player left combat
function SavelyReloadUI()
	-- Check if it's save to reload UI
	if IsUnitInCombat("player") then
		-- Register combat event to reload UI after combat
		EVENT_MANAGER:RegisterForEvent("SavelyReloadUI", EVENT_PLAYER_COMBAT_STATE, OnCombatStateChanged)
	else
		-- Reload now so the file is written
		ReloadUI()
	end
end

-- Event handler function for EVENT_PLAYER_COMBAT_STATE
function OnCombatStateChanged(event, inCombat)
	-- Check if left combat
	if not inCombat then
		-- Wait another 2 seconds and then reload the UI (in the timer function)
		QuestLog.timer.start("postCombatDelay", 2000)
		-- We don't need the event anymore, unregister it
		EVENT_MANAGER:UnregisterForEvent("SavelyReloadUI", EVENT_PLAYER_COMBAT_STATE)
	end
end