
function GetActionCommandIDByFilename(searchfilename)
  for k in io.lines(reaper.GetResourcePath().."/reaper-kb.ini") do
    if k:match("SCR") and k:match(searchfilename)then
      return "_"..k:match("SCR %d+ %d+ (%S*) ")
    end
  end
  return nil
end

local commands = {GetActionCommandIDByFilename("Marini_ReaLink_Background.lua")
}

for _, command in ipairs(commands)do
  reaper.Main_OnCommand(reaper.NamedCommandLookup(command), -1)
end
