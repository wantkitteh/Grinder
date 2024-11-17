local ResetConfirm = false;
local SegmentAdditional = 0;
local SegmentStartTime = 0;
local SegmentStartXP = 0;
local TimeInit = false;
local NextXPfromQuest = false;
local ResetOnNextXP = false;
local ComparisonTime = 0;

-- Called by XML on addon load
function Grinder_OnLoad()
	this:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN");
	this:RegisterEvent("QUEST_COMPLETE");
	this:RegisterEvent("PLAYER_LEVEL_UP");
	this:RegisterEvent("PLAYER_ENTERING_WORLD");
	this:RegisterEvent("ADDON_LOADED");
	this:RegisterEvent("TIME_PLAYED_MSG");
	this:RegisterEvent("PLAYER_DEAD");
	
	SlashCmdList["Grinder"] = Grinder_Command;
	SLASH_Grinder1 = "/splits";
	
	RequestTimePlayed()
end

-- Called by XML on event
function Grinder_OnEvent()
	-- DEFAULT_CHAT_FRAME:AddMessage(event,0.9,0.9,0.9);
	if (event == "CHAT_MSG_COMBAT_XP_GAIN" and UnitLevel("player") < 60) then
		local XPGain, XPLevel, XPCurrent, XPReq, KillXPRate, KillsToLevel, QuestsToLevel, TimeToLevel, SavedSplitCount, SplitNow, SSplitData, MessageText;
		
		if (ResetOnNextXP == true) then
			DEFAULT_CHAT_FRAME:AddMessage("Stats from previous run have been reset. Good luck, brave adventurer!",1,0,0)
			KillsTotal = 0;
			KillsLevel = 0;
			QuestsTotal = 0;
			QuestsLevel = 0;
			KillXPTotal = 0;
			KillXPLevel = 0;
			QuestXPTotal = 0;
			QuestXPLevel = 0;
			CharClass = UnitClass("player");
			ResetOnNextXP = false;
			
			SplitsCurrent = {};
			collectgarbage();
		end;			
		
		XPGain = getnumbersfromtext(arg1);
		XPLevel = UnitXPMax("player")
		XPCurrent = UnitXP("player") + XPGain;
		XPReq = XPLevel - XPCurrent;
		
		if (NextXPfromQuest == true) then
			QuestXPTotal = QuestXPTotal + XPGain;
			QuestXPLevel = QuestXPLevel + XPGain;
			QuestsLevel = QuestsLevel + 1;
			QuestsTotal = QuestsTotal + 1;
			
			QuestsToLevel = (XPReq / (QuestXPLevel / QuestsLevel)) + 1;
			
			MessageText = string.format("%.0f", QuestsToLevel).." qtl";
		end
		
		if (NextXPfromQuest == false) then
			KillXPTotal = KillXPTotal + XPGain;
			KillXPLevel = KillXPLevel + XPGain;
			KillsLevel = KillsLevel + 1;
			KillsTotal = KillsTotal + 1;			
			
			KillsToLevel = (XPReq / (KillXPLevel / KillsLevel)) + 1;
			
			MessageText = string.format("%.0f", KillsToLevel).." ktl"
		end
		
		KillXPRate = (XPCurrent / 1000) / ((time() - SegmentStartTime + SegmentAdditional) / 3600);
		MessageText = MessageText..", "..string.format("%.1f", KillXPRate).."k/hr";
		
		TimeToLevel = SecondsToTimeShort(XPReq / (XPCurrent / (time() - SegmentStartTime + SegmentAdditional)));
		MessageText = MessageText.." ("..TimeToLevel..")";
		
		for i, v in ipairs(SplitsSaved) do SavedSplitCount = i end;
		if (UnitLevel("player") <= SavedSplitCount) then
			SSplitData = SplitsSaved[UnitLevel("player")];
			SplitNow = ((time() - SegmentStartTime + SegmentAdditional) + (XPReq / (XPCurrent / (time() - SegmentStartTime + SegmentAdditional)))) - SSplitData[2];
			if (SplitNow < 0) then
				MessageText = (MessageText.." "..SecondsToTimeShort(SplitNow))
			else
				MessageText = (MessageText.." +"..SecondsToTimeShort(SplitNow))
			end
		end
				
		UIErrorsFrame:AddMessage(MessageText,1,1,0,1, UIERRORS_HOLD_TIME);
		
		NextXPfromQuest = false;
	end
	
	if (event == "QUEST_COMPLETE") then
		NextXPfromQuest = true;
	end
	
	if (event == "PLAYER_LEVEL_UP") then
		local CurrentLevel, TimeTakenLevel, ActualLevelXP, SplitData;
		
		CurrentLevel = UnitLevel("player");
		TimeTakenLevel = (time() - SegmentStartTime + SegmentAdditional);
		ActualLevelXP = KillXPLevel + QuestXPLevel;
		
		SplitData = {CurrentLevel, TimeTakenLevel, KillsLevel, KillXPLevel, QuestsLevel, QuestXPLevel};
		SplitsCurrent[CurrentLevel] = SplitData;
		
		DEFAULT_CHAT_FRAME:AddMessage(UnitName"player".." the "..UnitClass("player").." completed Level "..CurrentLevel.." in "..SecondsToTime(TimeTakenLevel)..".")
		DEFAULT_CHAT_FRAME:AddMessage("Total XP earned was "..(KillXPLevel+QuestXPLevel).." : "..KillXPLevel.." ["..string.format("%.1f",((KillXPLevel/ActualLevelXP)*100)).."%] from "..KillsLevel.." mobs, "..QuestXPLevel.." ["..string.format("%.1f",((QuestXPLevel/ActualLevelXP)*100)).."%] from "..QuestsLevel.." quests")
									
		KillsLevel = 0;
		KillXPLevel = 0;
		QuestsLevel = 0;
		QuestXPLevel = 0;
			
		SegmentAdditional = 0;
		SegmentStartTime = time();
		
		if (CurrentLevel == 60) then
			DumpSplits()
		end
		
	end
	
	if (event == "PLAYER_ENTERING_WORLD") then
		if (UnitLevel("player") == 1 and UnitXP("player") == 0 and KillsTotal ~= 0) then
			
			DEFAULT_CHAT_FRAME:AddMessage("WARNING: Grinder stats from previous run will be lost on first XP gain",1,0,0); -- RED
			
			ResetOnNextXP = true;
			
			if (KillsTotal == nil) then KillsTotal = 0 end
			if (KillsLevel == nil) then KillsLevel = 0 end
			if (QuestsTotal == nil) then QuestsTotal = 0 end
			if (QuestsLevel == nil) then QuestsLevel = 0 end
	
			if (KillXPTotal == nil) then KillXPTotal = 0 end
			if (KillXPLevel == nil) then KillXPLevel = 0 end
			if (QuestXPTotal == nil) then QuestXPTotal = 0 end
			if (QuestXPLevel == nil) then QuestXPLevel = 0 end
	
			if (SplitsCurrent == nil) then SplitsCurrent = {} end
			if (SplitsSaved == nil) then SplitsSaved = {} end
			if (CharClass == nil) then CharClass = UnitClass("player") end
		end
	end
	
	if (event == "TIME_PLAYED_MSG" and TimeInit == false) then
		SegmentAdditional = arg2;
		SegmentStartTime = time();
		TimeInit = true;
	end
	
	if (event == "PLAYER_DEAD") then
		DumpCurrentSplits()
		DEFAULT_CHAT_FRAME:AddMessage("DON'T FORGET TO STORE YOUR SPLITS!!! (/splits store)",1,0,0); -- RED
	end
end

-- Slash command handler
function Grinder_Command(args)
	if (args == "") then
		DEFAULT_CHAT_FRAME:AddMessage("Grinder Commands:");
		DEFAULT_CHAT_FRAME:AddMessage(" /splits live : show current split data");
		DEFAULT_CHAT_FRAME:AddMessage(" /splits saved : show saved split data");
		DEFAULT_CHAT_FRAME:AddMessage(" /splits store : save current split data");
		DEFAULT_CHAT_FRAME:AddMessage(" /splits comp : compare current and saved split times");
	end
	if (args == "live") then
		DumpCurrentSplits()
	end
	if (args == "saved") then
		DumpSavedSplits()
	end
	if (args == "store") then
		SaveSplits()
	end
	if (args == "comp") then
		CompareSplits()
	end
end

-- ** EXTRA FUNCTIONS **

-- Return numbers from string.byte
function getnumbersfromtext(txt)
	local str = ""
	string.gsub(txt,"%d+",function(e)
		str = str .. e
		end)
	return str;
end

function DataSummary()
	DEFAULT_CHAT_FRAME:AddMessage("Data summary here");
end

function DumpCurrentSplits()
	local TotalSplitTime, TotalSplitKills, TotalSplitQuests, TotalSpliKillXP, TotalSplitQuestXP, PercentXPMobs, PercentXPQuests
	TotalSplitTime = 0;
	TotalSplitKills = 0;
	TotalSplitQuests = 0;
	TotalSplitKillXP = 0;
	TotalSplitQuestXP = 0;
	DEFAULT_CHAT_FRAME:AddMessage("[ Live Split Data for "..UnitName"player".." the "..CharClass.." ]",0.65,0.65,1);
	for i, v in ipairs(SplitsCurrent) do
		-- SplitData : 1=CurrentLevel, 2=TimeTakenLevel, 3=KillsLevel, 4=KillXPLevel, 5=QuestsLevel, 6=QuestXPLevel
		TotalSplitTime = TotalSplitTime + v[2];
		TotalSplitKills = TotalSplitKills + v[3];
		TotalSplitKillXP = TotalSplitKillXP + v[4];
		TotalSplitQuests = TotalSplitQuests + v[5];
		TotalSplitQuestXP = TotalSplitQuestXP + v[6];
		PercentXPMobs = string.format("%.0f",((v[4]/(v[4]+v[6]))*100));
		PercentXPQuests = string.format("%.0f",((v[6]/(v[4]+v[6]))*100));
		DEFAULT_CHAT_FRAME:AddMessage("[ Lv"..v[1].." : "..SecondsToTime(TotalSplitTime).." ] - "..SecondsToTime(v[2]).." - "..v[3].." Kills ("..v[4].."xp, "..PercentXPMobs.."%), "..v[5].." Quests ("..v[6].."xp, "..PercentXPQuests.."%)",0.65,0.65,1);
	end
	PercentXPMobs = string.format("%.0f", (TotalSplitKillXP / (TotalSplitKillXP + TotalSplitQuestXP)) * 100);
	PercentXPQuests = string.format("%.0f", (TotalSplitQuestXP / (TotalSplitKillXP + TotalSplitQuestXP)) * 100);
	DEFAULT_CHAT_FRAME:AddMessage("Total: "..TotalSplitKills.." Kills ("..PercentXPMobs.."% of XP), "..TotalSplitQuests.." Quests ("..PercentXPQuests.."% of XP), "..(TotalSplitKillXP + TotalSplitQuestXP).." XP",0.65,0.65,1);
end

function SaveSplits()
	local Counter;
	SplitsSaved = {};
	collectgarbage();
	
	for i, v in ipairs(SplitsCurrent) do
		SplitsSaved[i] = SplitsCurrent[i];
	end
	DEFAULT_CHAT_FRAME:AddMessage("Splits saved successfully",0.65,0.65,1);
			
end

function DumpSavedSplits()
	local TotalSplitTime, TotalSplitKills, TotalSplitQuests, TotalSpliKillXP, TotalSplitQuestXP, PercentXPMobs, PercentXPQuests
	TotalSplitTime = 0;
	TotalSplitKills = 0;
	TotalSplitQuests = 0;
	TotalSplitKillXP = 0;
	TotalSplitQuestXP = 0;
	DEFAULT_CHAT_FRAME:AddMessage("[ Saved Split Data ]",0.65,0.65,1);
	for i, v in ipairs(SplitsSaved) do
		-- SplitData : 1=CurrentLevel, 2=TimeTakenLevel, 3=KillsLevel, 4=KillXPLevel, 5=QuestsLevel, 6=QuestXPLevel
		TotalSplitTime = TotalSplitTime + v[2];
		TotalSplitKills = TotalSplitKills + v[3];
		TotalSplitKillXP = TotalSplitKillXP + v[4];
		TotalSplitQuests = TotalSplitQuests + v[5];
		TotalSplitQuestXP = TotalSplitQuestXP + v[6];
		PercentXPMobs = string.format("%.0f",((v[4]/(v[4]+v[6]))*100));
		PercentXPQuests = string.format("%.0f",((v[6]/(v[4]+v[6]))*100));
		DEFAULT_CHAT_FRAME:AddMessage("[ Lv"..v[1].." : "..SecondsToTime(TotalSplitTime).." ] - "..SecondsToTime(v[2]).." - "..v[3].." Kills ("..v[4].."xp, "..PercentXPMobs.."%), "..v[5].." Quests ("..v[6].."xp, "..PercentXPQuests.."%)",0.65,0.65,1);
	end
	PercentXPMobs = string.format("%.0f", (TotalSplitKillXP / (TotalSplitKillXP + TotalSplitQuestXP)) * 100);
	PercentXPQuests = string.format("%.0f", (TotalSplitQuestXP / (TotalSplitKillXP + TotalSplitQuestXP)) * 100);
	DEFAULT_CHAT_FRAME:AddMessage("Total: "..TotalSplitKills.." Kills ("..PercentXPMobs.."% of XP), "..TotalSplitQuests.." Quests ("..PercentXPQuests.."% of XP), "..(TotalSplitKillXP + TotalSplitQuestXP).." XP",0.65,0.65,1);
end

function CompareSplits()
	local CurrentSplitCount, SavedSplitCount, SCurrent, SSaved, STCurrent, STSaved;
	
	CurrentSplitCount = 0;
	SavedSplitCount = 0;
	SCurrent = {};
	SSaved = {};
	STCurrent = 0;
	STSaved = 0;
	
	DEFAULT_CHAT_FRAME:AddMessage("[ Split (Overall) ]",0.65,0.65,1);
	
	for i, v in ipairs(SplitsCurrent) do CurrentSplitCount = i end;
	for i, v in ipairs(SplitsSaved) do SavedSplitCount = i end;
	
	if (CurrentSplitCount >= SavedSplitCount) then
		for i = 1, CurrentSplitCount do
			local MessageText;
			
			MessageText = "";
			
			if (i > SavedSplitCount) then
				-- Do Nothing
			else
				-- Comparison
				SCurrent = SplitsCurrent[i];
				SSaved = SplitsSaved[i];
				STCurrent = STCurrent + SCurrent[2];
				STSaved = STSaved + SSaved[2];
				
				if (SSaved[2] > SCurrent[2]) then
					MessageText = MessageText..("[Lv "..SCurrent[1].."] : "..SecondsToTime(SCurrent[2]-SSaved[2]));
				else
					MessageText = MessageText..("[Lv "..SCurrent[1].."] : +"..SecondsToTime(SCurrent[2]-SSaved[2]));
				end
				
				if (STSaved > STCurrent) then
					MessageText = MessageText..(" ("..SecondsToTime(STCurrent-STSaved)..")");
				else
					MessageText = MessageText..(" (+"..SecondsToTime(STCurrent-STSaved)..")");
				end
				
				DEFAULT_CHAT_FRAME:AddMessage(MessageText, 0.65, 0.65, 1);
				
			end
		end
	else
		for i = 1, SavedSplitCount do
			local MessageText;
			
			MessageText = "";
			if (i > CurrentSplitCount) then
				-- Do Nothing
			else
				-- Comparison
				SCurrent = SplitsCurrent[i];
				SSaved = SplitsSaved[i];
				STCurrent = STCurrent + SCurrent[2];
				STSaved = STSaved + SSaved[2];
				
				if (SSaved[2] > SCurrent[2]) then
					MessageText = MessageText..("[Lv "..SCurrent[1].."] : "..SecondsToTime(SCurrent[2]-SSaved[2]));
				else
					MessageText = MessageText..("[Lv "..SCurrent[1].."] : +"..SecondsToTime(SCurrent[2]-SSaved[2]));
				end
				
				if (STSaved > STCurrent) then
					MessageText = MessageText..(" ("..SecondsToTime(STCurrent-STSaved)..")");
				else
					MessageText = MessageText..(" (+"..SecondsToTime(STCurrent-STSaved)..")");
				end
				
				DEFAULT_CHAT_FRAME:AddMessage(MessageText, 0.65, 0.65, 1);
			end
		end
	end
end

function SecondsToTime(time)
	local invert;
	if(time < 0) then
		time = abs(time);
		invert = true;
	else
		invert = false;
	end
	
	local days = floor(time/86400);
	local hours = floor(mod(time, 86400)/3600);
	local minutes = floor(mod(time,3600)/60);
	local seconds = floor(mod(time,60));
	local returned = false;
	
	if (days ~= 0 and returned == false) then
		returned = true
		if (invert == true) then
			return("-"..days.."d "..hours.."h "..minutes.."m "..seconds.."s")
		else
			return(days.."d "..hours.."h "..minutes.."m "..seconds.."s")
		end
	end
	
	if (hours ~= 0 and returned == false) then
		returned = true
		if (invert == true) then
			return("-"..hours.."h "..minutes.."m "..seconds.."s")
		else
			return(hours.."h "..minutes.."m "..seconds.."s")
		end
	end
	
	if (minutes ~= 0 and returned == false) then
		returned = true
		if (invert == true) then
			return("-"..minutes.."m "..seconds.."s")
		else
			return(minutes.."m "..seconds.."s")
		end
	end
	
	if (seconds ~= 0 and returned == false) then
		returned = true
		if (invert == true) then
			return("-"..seconds.."s")
		else
			return(seconds.."s")
		end
	end
	
	return(0)
end

function SecondsToTimeShort(time)
	local invert;
	if(time < 0) then
		time = abs(time);
		invert = true;
	else
		invert = false;
	end
	
	local days = floor(time/86400);
	local hours = floor(mod(time, 86400)/3600);
	local minutes = floor(mod(time,3600)/60);
	local seconds = floor(mod(time,60));
	local returned = false;
	
	if (days ~= 0 and returned == false) then
		returned = true
		if (invert == true) then
			return("-"..days.."d"..hours.."h")
		else
			return(days.."d"..hours.."h")
		end
	end
	
	if (hours ~= 0 and returned == false) then
		returned = true
		if (invert == true) then
			return("="..hours.."h"..minutes.."m")
		else
			return(hours.."h"..minutes.."m")
		end
	end
	
	if (minutes ~= 0 and returned == false) then
		returned = true
		if (invert == true) then
			return("-"..minutes.."m"..seconds.."s")
		else
			return(minutes.."m"..seconds.."s")
		end
	end
	
	if (seconds ~= 0 and returned == false) then
		returned = true
		if (invert == true) then
			return("-"..seconds.."s")
		else
			return(seconds.."s")
		end
	end
	
	return(0)
end