# ReaperLink
Lua script to link fx parameters across different tracks in reaper. 

## Installation
You can install this adding [this repo] in ReaPack, or manually:

1. Put `Marini_ReaLink_Background.lua`, `Marini_ReaLink_Ui_Toggle.lua` and `Marini_ReaLink_Toggle_Autostart.lua` wherever you want (script folder or subdirectory)
2. Add the scripts in reaper (<i>Actions -> Show action list...</i>)

## Usage
1. Start the background syncing task with `Marini_ReaLink_Background.lua`. Open/close ui with `Marini_ReaLink_Ui_Toggle.lua`*. Add/remove links from the UI
2. If you want to avoid needing to start the background task on each startup, run `Marini_ReaLink_Toggle_Autostart.lua`. Disable this behaviour with the same action
3. Open UI, select the 2 tracks on which you want the FX params to be linked, press link. To unlink, select the track pair on the script UI and press the "-" button

*note that in order for the UI to show you need to have `Marini_ReaLink_Background.lua` running 

You can find more detailed instruction in the pdf in this repo

Enojoy ;)
