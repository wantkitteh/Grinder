** Grinder **

A super-simple WoW-HC friendly levelling stat tool, providing kills-to-level, time to level and XP rate data LIVE
Also saves split times, kill counts, quest counts and XP ratios, per level and overall
Timing data is persistent across sessions, so even if you log out for a week, the rates and TTL will still be accurate when you return!
Got your hardcore character killed and instinctively logged out before you checked your data? Don't worry, it's not gone yet!
Create a new character with the same name, log in, and the previous run's data will be available until the first time you gain XP on the new toon

Usage:
1) Extract the "Grinder" folder from inside the master folder
2) Place it inside Interface/Addons
3) You're good to go! Data gathering starts automatically
4) See the full detailed data it's hoarding with command /splits

I got frustrated I couldn't find a 1.12 speedrunning split mod, or a grind progress HUD that gave me the info I wanted
So yesterday I decided I'd look into writing WoW addons, and today I'm publishing my first attempt for your comments and suggestions

Known Issues:
1) No localization yet. Seriously, I've been working on this for less than 48 hours. I'm a fast lady, but I'm not that fast!
2) Slight accuracy issues - I can't find event hooks that directly ID experience from quests and exploration, so exploration may get classed as mob kills, and grey quests won't proc the workaround flag I set up causing the next exploration/mob kill to be misattributed as quest XP. No big deal in the grand scheme of things, but it's still annoying.
