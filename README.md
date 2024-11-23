** Grinder **
** For WoW 1.12.1 (Build 5875) **

Created out of frustration at the lack of (or rather my inability to find) good speedrunning split tools for the WoW 1.12 client. Starting from zero prior WoW addon coding experience, I started with a basic "Hello World" tutorial I found online, moved on to reading other mods with some of the functionality I was looking to implement, then broke out the APIs and event lists to figure the rest out myself (with a few reuable functions and examples lifted from... er, wherever I got them)

The result is a WoW-HC friendly speedrunning HUD, using the simplest methods I could find to provide KTL, TTL and XP/hr, with implemented persistence to store splits and maintain accurate rates across play sessions. To improve the hardcore-friendly aspect further, run stats and split data for a character are kept available when you recreate a toon with the same name, allowing access to your split data even if you logged out and your dead toon was auto-deleted - provided you remember to check it before that new toon gains their first XP and needs those variables and tables themselves!

** IMPORTANT NOTICE **
This is intended primarily as a speedrunning tool. As such, it's not designed to be added to the addon line-up of a pre-existing character. The addon will switch to a limited functionality fall-back mode; HUD details will be reduced and operate in a reduced accuracy fall-back mode until the character levels up; data saving for comparison will be disabled until a fresh run starting from 0XP Lv1 is detected, as comparing incomplete run data sets is not currently supported.

** pfUI Compatibility **
If you use pfUI, the UI error mechanism I've co-opted into displaying the stats after each kill is restricted to a single line, leading to the stats being immediately overwritten if the mob you've just killed is a quest objective. I don't really intend to extend the UI of this mod at all myself to get around this problem, but you can go into pfUI's Settings / General tab, and uncheck "Use Single Line UIErrors Frame" to work around the issue.

Usage:
1) Extract the "Grinder" folder from inside the master folder
2) Place it inside Interface/Addons
3) You're good to go! Data gathering starts automatically

Commands:
	/grind delete : erase saved data
	/grind save : save current data
	/grind splits : generate current vs saved split times report
	/grind data (current|saved) : show full data for either current or saved run, as per stated option
	
NB:
Split data is stored per-character, as opposed to per-account. Assuming you reuse the same character name when repeating runs, this is the simplest way to allow multiple independent splits to be saved. If you do want to transfer split data between characters, you can copy the Grinder.lua file in the "wtf/account/ACCOUNT NAME/SERVER NAME/CHAR NAME/SavedVariables" folder between characters no problem - AS LONG AS YOU REMEMBER not to try to start new data with anything other than a completely fresh character.

Other Known Issues that *might* get fixed later:
1) No localization yet. Seriously, I've been working on this for less than 48 hours. I'm a fast lady, but I'm not that fast!
2) Slight accuracy issues - I can't find event hooks that directly ID experience from quests and exploration, so exploration may get classed as mob kills, and grey quests won't proc the workaround flag I set up causing the next exploration/mob kill to be misattributed as quest XP. No big deal in the grand scheme of things, but it's still annoying.

Version Data
	0.1a	:	Initial upload
	
	0.2a	:	Added split data storage and comparison functions
				Added estimated split difference to HUD (when saved data is available)
				Minor cosmetic bug fixes
				
	0.3a	:	Major internal rewrite