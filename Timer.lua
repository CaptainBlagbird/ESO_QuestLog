--[[

Quest log
by CaptainBlagbird
https://github.com/CaptainBlagbird

--]]

-- Timer variables
QuestLog.timer = {}
QuestLog.timer["dialogCountdown"] = {}
QuestLog.timer["dialogCountdown"].enabled = false
QuestLog.timer["postCombatDelay"] = {}
QuestLog.timer["postCombatDelay"].enabled = false


-- Function to start the timer
function QuestLog.timer.start(i, ms)
	QuestLog.timer[i].startTimeStamp = GetGameTimeMilliseconds()
	QuestLog.timer[i].durationMs = ms
	QuestLog.timer[i].enabled = true
end

-- Function to check remaining time
function QuestLog.timer.getRemainingMs(i)
	return QuestLog.timer[i].startTimeStamp + QuestLog.timer[i].durationMs - GetGameTimeMilliseconds()
end

-- Event handler function, called when the QuestLogTimerUI gets updated
function QuestLog.timer.OnUpdate()
	if QuestLog.timer["dialogCountdown"].enabled then
		local remainingMs = QuestLog.timer.getRemainingMs("dialogCountdown")
		QuestLog.showDialog(remainingMs/1000)
		if remainingMs <= 0 then
			QuestLog.timer["dialogCountdown"].enabled = false
			if not IsUnitInCombat("player") then QuestLog.hideDialog() end
			SavelyReloadUI()
		end
	end
	
	if QuestLog.timer["postCombatDelay"].enabled then
		if QuestLog.timer.getRemainingMs("postCombatDelay") <= 0 then
			QuestLog.timer["postCombatDelay"].enabled = false
			SavelyReloadUI()
		end
	end
end