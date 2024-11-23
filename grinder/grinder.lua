-- Defines
local SegmentStartTime = 0;
local SegmentAdditional = 0;
local ResetOnNextXP = false;

-- Called by XML on addon load
function Grinder_OnLoad()
	this:RegisterEvent("PLAYER_ENTERING_WORLD");
	this:RegisterEvent("TIME_PLAYED_MSG");
	this:RegisterEvent("CHAT_MSG_COMBAT_XP_GAIN");
	this:RegisterEvent("PLAYER_LEVEL_UP");
	this:RegisterEvent("QUEST_COMPLETE");
	SlashCmdList["Grinder"] = Grinder_Command;
	SLASH_Grinder1 = "/grind";
end

-- Called by XML on event
function Grinder_OnEvent()
	-- DEFAULT_CHAT_FRAME:AddMessage(event);
	if (event == "PLAYER_ENTERING_WORLD") then	
		DEFAULT_CHAT_FRAME:AddMessage("Grinder: Plugin loaded successfully, type /grind for options");
		if (FirstInit == nil) then	
			-- DEFAULT_CHAT_FRAME:AddMessage("First Init");		
			
			CurrentRun = {};
			ResetCurrentRun();
			
			SavedRun = {};		
			ResetSavedRun();	
			
			if (UnitLevel("player") ~= 1) then
				if (UnitXP("player") ~= 0) then
					DEFAULT_CHAT_FRAME:AddMessage("Grinder: Addon detected mid-run pre-existing character",1,0,0);
					DEFAULT_CHAT_FRAME:AddMessage("Grinder: Display of progress stats temporarily limited",1,0,0);
					CurrentRun[UnitLevel("player")]["CompTime"] = -1;
				end
			end		
			FirstInit = true;	
		else	
			-- DEFAULT_CHAT_FRAME:AddMessage("Normal Init");
			if (UnitLevel("player") == 1) then
				if (UnitXP("player") == 0) then
					DEFAULT_CHAT_FRAME:AddMessage("Grinder: New run detected, don't forget to save run data: /splits save",1,0,0);
					ResetOnNextXP = true;
				end
			end
		end
		RequestTimePlayed();	
	end
	
	if (event == "TIME_PLAYED_MSG") then
		-- DEFAULT_CHAT_FRAME:AddMessage("Segment Time Init");
		SegmentStartTime = time();
		SegmentAdditional = arg2;
	end
	
	if (event == "QUEST_COMPLETE") then
		-- DEFAULT_CHAT_FRAME:AddMessage("Next XP from Quest flag raised");
		NextXPfromQuest = true;
	end
	
	if (event == "CHAT_MSG_COMBAT_XP_GAIN") then
		--DEFAULT_CHAT_FRAME:AddMessage("XP Gain Handler");
		if (ResetOnNextXP == true) then
			DEFAULT_CHAT_FRAME:AddMessage("Grinder: Going agane, good luck!",0,1,1);
			ResetCurrentRun();
			ResetOnNextXP = false;
		end
	
		local XPgain = getnumbersfromtext(arg1);
		local XPlevel = UnitXPMax("player");
		local XPcurrent = UnitXP("player") + XPgain;
		local XPreq = XPlevel - XPcurrent;
		local CLvl = UnitLevel("player");
				
		if (NextXPfromQuest == true) then
			CurrentRun[CLvl]["QuestCount"] = CurrentRun[CLvl]["QuestCount"] + 1;
			CurrentRun[CLvl]["QuestXP"] = CurrentRun[CLvl]["QuestXP"] + XPgain;
			NextXPfromQuest = false;
		else
			CurrentRun[CLvl]["KillCount"] = CurrentRun[CLvl]["KillCount"] + 1;
			CurrentRun[CLvl]["KillXP"] = CurrentRun[CLvl]["KillXP"] + XPgain;
			
			local MessageText = "";
			
			if (XPreq > 0) then
				if (CurrentRun[CLvl]["CompTime"] ~= -1) then
					MessageText = string.format("%.1f", XPreq / (CurrentRun[CLvl]["KillXP"] / CurrentRun[CLvl]["KillCount"])).." ktl, ";
					MessageText = MessageText..string.format("%.1f", (XPcurrent / 1000) / ((time() - SegmentStartTime + SegmentAdditional) / 3600)).."k/hr, ";
					MessageText = MessageText..SecondsToShortTime(XPreq / (XPcurrent / (time() - SegmentStartTime + SegmentAdditional)));
					if (CurrentRun[CLvl]["CompTime"] ~= -1) then
						if (SavedRun[CLvl]["CompTime"] > 0) then
							local SplitPredict = 0;
							SplitPredict = ((time() - SegmentStartTime + SegmentAdditional) + (XPreq / (XPcurrent / (time() - SegmentStartTime + SegmentAdditional)))) - SavedRun[CLvl]["CompTime"];
							MessageText = MessageText.." (";
							if (SplitPredict > 0) then
								MessageText = MessageText.. "+";
							end
							if (SplitPredict < 0) then
								MessageText = MessageText.. "-";
							end
						MessageText = MessageText..SecondsToShortTime(abs(SplitPredict))..")"
						end
					end
				else
					MessageText = string.format("%.1f", XPreq / XPgain).." ktl";
				end
				UIErrorsFrame:AddMessage(MessageText,1,1,0,1, UIERRORS_HOLD_TIME);
			end
		end
	end
	
	if (event == "PLAYER_LEVEL_UP") then
		local CLvl = UnitLevel("player")
		local CTxp = CurrentRun[CLvl]["KillXP"] + CurrentRun[CLvl]["QuestXP"]
		local MessageText = "";
		local TCRunTime = 0;
		local TCKills = 0;
		local TCQuests = 0;
		local TSRunTime = 0;
		
		
		if (CurrentRun[CLvl]["CompTime"] > -1) then -- TEST THIS
			CurrentRun[CLvl]["CompTime"] = (time() - SegmentStartTime + SegmentAdditional);			
			if (SavedRun[CLvl]["CompTime"] - CurrentRun[CLvl]["CompTime"] > 0) then
				MessageText = "Level "..CLvl.." completed in "..SecondsToTime(CurrentRun[CLvl]["CompTime"]).." (-"..SecondsToTime(abs(SavedRun[CLvl]["CompTime"] - CurrentRun[CLvl]["CompTime"]))..")"
			end
			if (SavedRun[CLvl]["CompTime"] - CurrentRun[CLvl]["CompTime"] < 0) then
				MessageText = "Level "..CLvl.." completed in "..SecondsToTime(CurrentRun[CLvl]["CompTime"]).." (+"..SecondsToTime(abs(SavedRun[CLvl]["CompTime"] - CurrentRun[CLvl]["CompTime"]))..")"
			end
			if (SavedRun[CLvl]["CompTime"] - CurrentRun[CLvl]["CompTime"] == 0) then
				MessageText = "Level "..CLvl.." completed in "..SecondsToTime(CurrentRun[CLvl]["CompTime"]).." (Dead Heat)"
			end
			DEFAULT_CHAT_FRAME:AddMessage(MessageText,0.5,1,1);		
		end -- TEST THIS
		
		if (SavedRun[CLvl]["CompTime"] > 0 and SavedRun[CLvl]["CompTime"] > 0) then
			for i=1,CLvl,1
			do
				TCRunTime = TCRunTime + CurrentRun[i]["CompTime"];
				TCKills = TCKills + CurrentRun[i]["KillCount"];
				TCQuests = TCQuests + CurrentRun[i]["QuestCount"];
				TSRunTime = TSRunTime + SavedRun[i]["CompTime"];
			end			
			if (TSRunTime - TCRunTime > 0 ) then
				MessageText = "Cumulative Time: "..SecondsToTime(TCRunTime).." (+"..SecondsToTime(abs(TSRunTime - TCRunTime))..")";
			end
			if (TSRunTime - TCRunTime < 0 ) then
				MessageText = "Cumulative Time: "..SecondsToTime(TCRunTime).." (+"..SecondsToTime(abs(TSRunTime - TCRunTime))..")";				
			end
			if (TSRunTime - TCRunTime == 0 ) then
				MessageText = "Cumulative Time: "..SecondsToTime(TCRunTime).." (Dead Heat!)";
			end
			DEFAULT_CHAT_FRAME:AddMessage(MessageText,0.5,1,1);
		end
		
		DEFAULT_CHAT_FRAME:AddMessage(CurrentRun[CLvl]["KillCount"].." mobs killed ("..TCKills.." Total) for "..CurrentRun[CLvl]["KillXP"].."XP ("..string.format("%.1f", CurrentRun[CLvl]["KillXP"] / CTxp * 100).."%)",0.5,1,1);
		DEFAULT_CHAT_FRAME:AddMessage(CurrentRun[CLvl]["QuestCount"].." quests completed ("..TCQuests.." Total) for "..CurrentRun[CLvl]["QuestXP"].."XP ("..string.format("%.1f", CurrentRun[CLvl]["QuestXP"] / CTxp * 100).."%)",0.5,1,1);
		
		SegmentStartTime = time();
		SegmentAdditional = 0;
	end
end

-- Slash command handler
function Grinder_Command(args)
	
	if (args == "") then
		DEFAULT_CHAT_FRAME:AddMessage("Grinder Commands:",0.85,0,0.85);
		DEFAULT_CHAT_FRAME:AddMessage("  /grind delete : erase saved data",0.85,0,0.85);
		DEFAULT_CHAT_FRAME:AddMessage("  /grind save : save current data",0.85,0,0.85);
		DEFAULT_CHAT_FRAME:AddMessage("  /grind splits : generate current vs saved split times report", 0.85,0,0.85);
		DEFAULT_CHAT_FRAME:AddMessage("  /grind data (current|saved) : show full run data", 0.85,0,0.85);
	end
	
	if (args == "delete") then
		ResetSavedRun();
	end
	
	if (args == "save") then
		SaveCurrentRun();
	end
	
	if (args == "splits") then
		SplitsReport();
	end
	
	if (args == "data current") then
		DumpCurrent();
	end
	
	if (args == "data saved") then
		DumpSaved();
	end
	
end

function ResetCurrentRun()
	local i = 0;
	CurrentRun = {};
	collectgarbage();
	for i = 1,59,1
	do
		table.insert(CurrentRun, i, {KillCount = 0, KillXP = 0, QuestCount = 0, QuestXP = 0, CompTime = 0})
	end
	DEFAULT_CHAT_FRAME:AddMessage("Grinder: Current run data reset",0.25,1,0.25);
end

function ResetSavedRun()
	local i = 0;
	SavedRun = {};
	collectgarbage();
	for i = 1,59,1
	do
		table.insert(SavedRun, i, {KillCount = 0, KillXP = 0, QuestCount = 0, QuestXP = 0, CompTime = 0})
	end
	DEFAULT_CHAT_FRAME:AddMessage("Grinder: Saved run data reset",0.25,1,0.25);
end

function SaveCurrentRun()
	if (CurrentRun[1]["CompTime"] > 0) then
		local i = 0;			
		for i = 1,59,1
		do
			SavedRun[i] = CurrentRun[i];
		end
		DEFAULT_CHAT_FRAME:AddMessage("Grinder: Current run data saved",0.25,1,0.25);
	else
		if (UnitLevel("player") == 1) then
			DEFAULT_CHAT_FRAME:AddMessage("Grinder: No data to save",1,1,0);
		else
			DEFAULT_CHAT_FRAME:AddMessage("Grinder: FAILED! Cannot save run data that does not begin at lv1",1,0,0);
		end
	end
end

function SplitsReport()

	local TCtime = 0;
	local TStime = 0;
	local MessageText = "";
	
	DEFAULT_CHAT_FRAME:AddMessage(" -- Grinder Splits Report --",0.5,1,1);
	for i = 1,59,1
	do
		if (SavedRun[i]["CompTime"] > 0 and CurrentRun[i]["CompTime"] > 0) then
		
			TCtime = TCtime + CurrentRun[i]["CompTime"];
			TStime = TStime + SavedRun[i]["CompTime"];
			
			MessageText = " [Lv"..i.."] "..SecondsToTime(CurrentRun[i]["CompTime"]).." ("
			
			if (CurrentRun[i]["CompTime"] > SavedRun[i]["CompTime"]) then
				MessageText = MessageText.."+"..SecondsToTime(abs(SavedRun[i]["CompTime"] - CurrentRun[i]["CompTime"]))..")";
			end
			if (CurrentRun[i]["CompTime"] < SavedRun[i]["CompTime"]) then
				MessageText = MessageText.."-"..SecondsToTime(abs(SavedRun[i]["CompTime"] - CurrentRun[i]["CompTime"]))..")";
			end 
			if (CurrentRun[i]["CompTime"] == SavedRun[i]["CompTime"]) then
				MessageText = MessageText.."0)";
			end
			
			if (i > 1) then
				MessageText = MessageText.." : "..SecondsToTime(TCtime).." ("
				if (TCtime > TStime) then
					MessageText = MessageText.."+"..SecondsToTime(abs(TCtime - TStime))..")"
				end
				if (TCtime < TStime) then
					MessageText = MessageText.."-"..SecondsToTime(abs(TCtime - TStime))..")"
				end
				if (TCtime == TStime) then
					MessageText = MessageText.."Dead Heat)"
				end
			end
			DEFAULT_CHAT_FRAME:AddMessage(MessageText,0.5,1,1);
		end
	end
end

function DumpCurrent()

	local TCtime = 0;
	local TCkillcount = 0;
	local TCkillXP = 0;
	local TCquestcount = 0;
	local TCquestXP = 0;
	
	local MessageText = "";
	
	DEFAULT_CHAT_FRAME:AddMessage(" == Grinder Report: Current Run ==",0.25,1,0.75);
	for i = 1,59,1
	do
		if (CurrentRun[i]["CompTime"] > 0) then
			TCtime = TCtime + CurrentRun[i]["CompTime"];
			TCkillcount = TCkillcount + CurrentRun[i]["KillCount"];
			TCquestcount = TCquestcount + CurrentRun[i]["QuestCount"];
			TCkillXP = TCkillXP + CurrentRun[i]["KillXP"];
			TCquestXP = TCquestXP + CurrentRun[i]["QuestXP"];
			if (i == 1) then 
				DEFAULT_CHAT_FRAME:AddMessage("[Lv "..i.."] "..SecondsToTime(CurrentRun[i]["CompTime"])..", "..TCkillcount.." kills for "..TCkillXP.."XP, "..TCquestcount.." quests for "..TCquestXP.."XP.",0.5,1,1);
			else
				DEFAULT_CHAT_FRAME:AddMessage("[Lv "..i.."] "..SecondsToTime(CurrentRun[i]["CompTime"]).." ("..SecondsToTime(TCtime).."), "..TCkillcount.." kills for "..TCkillXP.."XP, "..TCquestcount.." quests for "..TCquestXP.."XP.",0.5,1,1);
			end
		else
			if (i == 1) then
				DEFAULT_CHAT_FRAME:AddMessage("Grinder: no data to report",1,0,0);
			end
		end
	end
	DEFAULT_CHAT_FRAME:AddMessage("Total kills: "..TCkillcount.." for "..TCkillXP.."XP ("..string.format("%.1f",(TCkillXP / (TCkillXP + TCquestXP) * 100)).."%)",0.5,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("Total quests: "..TCquestcount.." for "..TCquestXP.."XP ("..string.format("%.1f",(TCquestXP / (TCkillXP + TCquestXP) * 100)).."%)",0.5,1,1);
end

function DumpSaved()

	local TStime = 0;
	local TSkillcount = 0;
	local TSkillXP = 0;
	local TSquestcount = 0;
	local TSquestXP = 0;
	
	local MessageText = "";
	
	DEFAULT_CHAT_FRAME:AddMessage(" == Grinder Report: Saved Run ==",0.25,1,0.75);
	for i = 1,59,1
	do
		if (SavedRun[i]["CompTime"] > 0) then
			TStime = TStime + SavedRun[i]["CompTime"];
			TSkillcount = TSkillcount + SavedRun[i]["KillCount"];
			TSquestcount = TSquestcount + SavedRun[i]["QuestCount"];
			TSkillXP = TSkillXP + SavedRun[i]["KillXP"];
			TSquestXP = TSquestXP + SavedRun[i]["QuestXP"];
			DEFAULT_CHAT_FRAME:AddMessage("[Lv "..i.."] "..SecondsToTime(SavedRun[i]["CompTime"]).." ("..SecondsToTime(TStime).."), "..TSkillcount.." kills for "..TSkillXP.."XP, "..TSquestcount.." quests for "..TSquestXP.."XP.",0.5,1,1);
		end
	end
	DEFAULT_CHAT_FRAME:AddMessage("Total kills: "..TSkillcount.." for "..TSkillXP.."XP ("..string.format("%.1f",(TSkillXP / (TSkillXP + TSquestXP) * 100)).."%)",0.5,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("Total quests: "..TSquestcount.." for "..TSquestXP.."XP ("..string.format("%.1f",(TSquestXP / (TSkillXP + TSquestXP) * 100)).."%)",0.5,1,1);
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

function SecondsToTime(time)

	local days = floor(time/86400);
	local hours = floor(mod(time, 86400)/3600);
	local minutes = floor(mod(time,3600)/60);
	local seconds = floor(mod(time,60));
	local returned = false;
	
	if (days ~= 0) then
		return(days.."d "..hours.."h "..minutes.."m "..seconds.."s")
	else
		if (hours ~= 0) then
			return(hours.."h "..minutes.."m "..seconds.."s")
		else
			if (minutes ~= 0) then
				return(minutes.."m "..seconds.."s")
			else
				return(seconds.."s")
			end
		end
	end
end

function SecondsToShortTime(time)

	local days = floor(time/86400);
	local hours = floor(mod(time, 86400)/3600);
	local minutes = floor(mod(time,3600)/60);
	local seconds = floor(mod(time,60));
	local returned = false;
	
	if (days ~= 0) then
		return(days.."d"..hours.."h")
	else
		if (hours ~= 0) then
			return(hours.."h"..minutes.."m")
		else
			if (minutes ~= 0) then
				return(minutes.."m"..seconds.."s")
			else
				return(seconds.."s")
			end
		end
	end
end
