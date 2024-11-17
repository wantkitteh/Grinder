** Grinder **
** For WoW 1.12 **

Created out of frustration at the lack of (or rather my inability to find) good speedrunning split tools for the WoW 1.12 client. Starting from zero prior WoW addon coding experience, I started with a basic "Hello World" tutorial I found online, moved on to reading other mods with some of the functionality I was looking to implement, then broke out the APIs and event lists to figure the rest out myself (with a few reuable functions and examples lifted from... er, wherever I got them)

The result is a WoW-HC friendly speedrunning HUD, using the simplest methods I could find to provide KTL, TTL and XP/hr, with implemented persistence to store splits and maintain accurate rates across play sessions. To improve the hardcore-friendly aspect further, run stats and split data for a character are kept available when you recreate a toon with the same name, allowing access to your split data even if you logged out and your dead toon was auto-deleted - provided you remember to check it before that new toon gains their first XP and needs those variables and tables themselves!

** IMPORTANT NOTICE **
This is intended primarily as a speedrunning tool. As such, it's not designed to be added to the addon line-up of a pre-existing character. The addon will get extremely confused if you try. So please don't.

** pfUI Compatibility **
If you use pfUI, the UI error mechanism I've co-opted into displaying the stats after each kill is restricted to a single line, leading to the stats being immediately overwritten if the mob you've just killed is a quest objective. I don't really intend to extend the UI of this mod at all myself to get around this problem, but you can go into pfUI's Settings / General tab, and uncheck "Use Single Line UIErrors Frame" to work around the issue.

Usage:
1) Extract the "Grinder" folder from inside the master folder
2) Place it inside Interface/Addons
3) You're good to go! Data gathering starts automatically
4) See the full detailed data it's hoarding with command /splits

Other Known Issues that *might* get fixed later:
1) No localization yet. Seriously, I've been working on this for less than 48 hours. I'm a fast lady, but I'm not that fast!
2) Slight accuracy issues - I can't find event hooks that directly ID experience from quests and exploration, so exploration may get classed as mob kills, and grey quests won't proc the workaround flag I set up causing the next exploration/mob kill to be misattributed as quest XP. No big deal in the grand scheme of things, but it's still annoying.
