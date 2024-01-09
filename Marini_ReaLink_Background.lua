function GetActionCommandIDByFilename(searchfilename)
  for k in io.lines(reaper.GetResourcePath() .. "/reaper-kb.ini") do
    if k:match("SCR") and k:match(searchfilename) then
      return "_" .. k:match("SCR %d+ %d+ (%S*) ")
    end
  end
  return nil
end

local fontSize = 12
gfx.setfont(1)

local currProject = reaper.EnumProjects(-1)
local uiToggleCommand = GetActionCommandIDByFilename("Marini_ReaLink_Ui_Toggle.lua")
local uiToggleCommandId = reaper.NamedCommandLookup(uiToggleCommand)

local pluginName = "Marini_ReaLink"

local linkPairs = {}

local windowSize = nil
local firstInit = true
local scale = 1
local padding = 20
local innerPadding = 10
local trackNamesLeft = 2.5
local trackNamesSpacing = 25
local rowHeight = 20

local button1W, button1H = 100, 25
local button2W, button2H = 25, 25
local buttonSpacing = 10

local tableBounds = {}

local b1Bounds, b2Bounds

local buttonHover
local tableSelection = nil
local tableHover = nil



local function applyDpiToConstants()

  padding = padding * scale
  innerPadding = innerPadding * scale
  trackNamesLeft = trackNamesLeft * scale
  trackNamesSpacing = trackNamesSpacing * scale
  rowHeight = rowHeight * scale

  button1W, button1H = button1W * scale, button1H * scale
  button2W, button2H = button2W * scale, button2H * scale
  buttonSpacing = buttonSpacing * scale

  if reaper.GetOS():match("^Win") == nil then
    gfx.setfont(1, "Verdana", fontSize * scale)
  else
    gfx.setfont(1, "Calibri", fontSize * scale)
  end
end

local function applyDpi(bounds)
  for _, value in pairs(bounds) do
    value = value * scale
  end
end



function parseTracks()
  local _, size = reaper.GetProjExtState(0, pluginName, "nLinks")

  local allTracks = {}

  for i = 0, reaper.CountTracks()-1 do 
    local track = reaper.GetTrack(0, i)
    allTracks[reaper.GetTrackGUID(track)] = track
  end

  if size == "" then return end

  for linkIndex = 1, tonumber(size) do
    local _, link = reaper.GetProjExtState(0, pluginName, tostring(linkIndex))

    local masterGUID, slaveGUID = string.match(link, "(%S+),"), string.match(link, ",(%S+)")


    local master, slave = allTracks[masterGUID], allTracks[slaveGUID]
    if master and slave then
      --reaper.ShowConsoleMsg("carico traccia\n")
      table.insert(linkPairs, { master, slave })
    end
  end
end

function saveState()
  --reaper.ShowConsoleMsg( tostring(#linkPairs))
  --reaper.SetProjExtState(0, pluginName, "nLinks", tostring())
  reaper.SetProjExtState(0, pluginName, "", "") --cancella stato
  reaper.SetProjExtState(0, pluginName, "nLinks", tostring(#linkPairs))
  for i, pair in ipairs(linkPairs) do
    --reaper.ShowConsoleMsg(tostring(i))

    reaper.SetProjExtState(0, pluginName, tostring(i), reaper.GetTrackGUID(pair[1]) .. "," .. reaper.GetTrackGUID(pair[2]))
    --reaper.ShowConsoleMsg("{" .. n1 .. "," .. n2 .. "}\n")
  end
  --file:close()
  --reaper.Main_SaveProject(0, false)
end

function tableView()
  tableBounds = { x = padding, y = padding, width = gfx.w - 2 * padding, height = gfx.h - 3 * padding - button1H }
  applyDpi(tableBounds)

  gfx.set(0.15, 0.15, 0.15)
  gfx.rect(0, 0, gfx.w, gfx.h)
  gfx.set(0.1, 0.1, 0.1)

  gfx.rect(padding, padding, gfx.w - 2 * padding, gfx.h - 3 * padding - button1H)


  if tableHover then
    gfx.set(0.15, 0.15, 0.15)
    gfx.rect(
      tableBounds.x + innerPadding,
      tableBounds.y + innerPadding + rowHeight * tableHover,
      tableBounds.width - 2 * innerPadding,
      rowHeight)
  end

  if tableSelection then
    gfx.set(0.2, 0.2, 0.2)
    gfx.rect(
      tableBounds.x + innerPadding,
      tableBounds.y + innerPadding + rowHeight * tableSelection,
      tableBounds.width - 2 * innerPadding,
      rowHeight)
  end

  gfx.set(1, 1, 1)
  local maxTrackNameLength = -1

  for _, pair in ipairs(linkPairs) do
    local _, masterTrack = reaper.GetTrackName(pair[1])

    if gfx.measurestr(masterTrack) > maxTrackNameLength then
      maxTrackNameLength = gfx.measurestr(masterTrack)
    end
  end

  for i, pair in ipairs(linkPairs) do
    if reaper.ValidatePtr(pair[1], "MediaTrack*") and
        reaper.ValidatePtr(pair[2], "MediaTrack*") then
      local masterTrack, slaveTrack = pair[1], pair[2]
      local _, masterTrackName = reaper.GetTrackName(masterTrack)
      local _, slaveTrackName = reaper.GetTrackName(slaveTrack)

      --gui stuff
      gfx.x, gfx.y = padding + innerPadding + trackNamesLeft, padding + (i - 1) * rowHeight + innerPadding
      gfx.drawstr(masterTrackName, 4, tableBounds.x + tableBounds.width - innerPadding, gfx.y + rowHeight)
      gfx.x = maxTrackNameLength + padding + trackNamesSpacing
      gfx.drawstr(slaveTrackName, 4, tableBounds.x + tableBounds.width - innerPadding, gfx.y + rowHeight)

      --linking FX parameters

      local masterHash, slaveHash = {}, {}
      for fxIndex = 0, reaper.TrackFX_GetCount(masterTrack) - 1 do
        local _, fxName = reaper.TrackFX_GetFXName(masterTrack, fxIndex)
        if masterHash[fxName] == nil then masterHash[fxName] = {} end
        table.insert(masterHash[fxName], fxIndex)
      end
      for fxIndex = 0, reaper.TrackFX_GetCount(slaveTrack) - 1 do
        local _, fxName = reaper.TrackFX_GetFXName(slaveTrack, fxIndex)
        if slaveHash[fxName] == nil then slaveHash[fxName] = {} end
        table.insert(slaveHash[fxName], fxIndex)
      end

      for key, value in pairs(masterHash) do
        if slaveHash[key] ~= nil then
          for fxIndex = 1, math.min(#value, #slaveHash[key]) do
            local masterFX, slaveFX = value[fxIndex], slaveHash[key][fxIndex]
            for parIndex = 0, reaper.TrackFX_GetNumParams(masterTrack, masterFX) - 1 do
              local param1 = reaper.TrackFX_GetParamNormalized(masterTrack, masterFX, parIndex)
              local param2 = reaper.TrackFX_GetParamNormalized(slaveTrack, slaveFX, parIndex)
              if param1 ~= param2 then 
                reaper.TrackFX_SetParamNormalized(slaveTrack, slaveFX, parIndex, param1)
              end
            end
          end
        end
      end
    else
      table.remove(linkPairs, i)
    end
  end

  gfx.set(0.15, 0.15, 0.15)
  gfx.rect(0, gfx.h - 2 * padding - button1H, gfx.w, 2 * padding + button1H)
end

local function adjustDpi()
end

local function buttons()
  local button1x, button1y = gfx.w - padding - button1W, gfx.h - padding - button1H
  local button2x, button2y = button1x - buttonSpacing - button2W, button1y
  b1Bounds = { x1 = button1x, y1 = button1y, x2 = button1x + button1W, y2 = button1y + button1H }
  b2Bounds = { x1 = button2x, y1 = button2y, x2 = button2x + button2W, y2 = button2y + button2H }

  --background
  gfx.set(0.3, 0.3, 0.3)
  gfx.rect(button1x, button1y, button1W, button1H, true)
  gfx.rect(button2x, button2y, button2W, button2H, true)

  --hover
  if buttonHover then
    gfx.set(0.5, 0.5, 0.5, 1)
    gfx.rect(buttonHover.x1, buttonHover.y1, buttonHover.x2 - buttonHover.x1, buttonHover.y2 - buttonHover.y1, true)
  end

  --lineart
  gfx.set(0, 0, 0)
  gfx.rect(button1x, button1y, button1W, button1H, false)
  gfx.rect(button2x, button2y, button2W, button2H, false)

  --testo
  gfx.set(1, 1, 1)
  gfx.x, gfx.y = button1x, button1y
  gfx.drawstr("Link", 5, gfx.x + button1W, gfx.y + button1H)

  gfx.x, gfx.y = button2x, button2y
  gfx.drawstr("-", 5, gfx.x + button2W, gfx.y + button2H)
end


local function inBounds(bounds)
  gfx.getchar()
  local x, y = gfx.mouse_x, gfx.mouse_y

  if bounds.width then
    return x > bounds.x and x < bounds.x + bounds.width
        and y > bounds.y and y < bounds.y + bounds.height
  else
    return (x > bounds.x1 and x < bounds.x2 and y > bounds.y1 and y < bounds.y2)
  end
end


local function addSelectedTracks()
  if reaper.CountSelectedTracks(0) < 2 then
    reaper.ShowMessageBox("You need to select at lest 2 tracks!", "ReaperLink error", 0)
    return
  elseif reaper.CountSelectedTracks(0) > 2 then
    reaper.ShowMessageBox("You need to select at least 2 tracks!", "ReaperLink error", 0)
    return
  end

  local track1, track2 = reaper.GetSelectedTrack(0, 0), reaper.GetSelectedTrack(0, 1)

  for i = 1, #linkPairs do
    if linkPairs[i][1] == track1 or linkPairs[i][2] == track1
        or linkPairs[i][1] == track2 or linkPairs[i][2] == track2
    then
      reaper.ShowMessageBox("Selected tracks are already linked", "ReaperLink error", 0)
      return
    end
  end

  --reaper.MarkProjectDirty()
  table.insert(linkPairs, { reaper.GetSelectedTrack(0, 0), reaper.GetSelectedTrack(0, 1) })
  saveState()

end


local function removeSelectedLink()
  if tableSelection then
    --reaper.MarkProjectDirty()
    table.remove(linkPairs, tableSelection + 1)
    tableSelection = tableSelection - 1
    if tableSelection == -1 then tableSelection = 0 end
    if #linkPairs == 0 then tableSelection = nil end
  end
  --reaper.MarkProjectDirty()
  saveState()
end


local prevClick = 0
function handleMouse()
  if gfx.mouse_cap == 1 and prevClick == 0
  then

  elseif prevClick == 1 and gfx.mouse_cap == 0 then
    if inBounds(tableBounds) then
      if (gfx.mouse_y < padding + innerPadding + #linkPairs * rowHeight) and (gfx.mouse_y > padding + innerPadding) then
        tableSelection = math.floor((gfx.mouse_y - innerPadding - padding) / rowHeight)
      else
        tableSelection = nil
      end
    elseif inBounds(b1Bounds) then
      addSelectedTracks()
    elseif inBounds(b2Bounds) then
      removeSelectedLink()
    end
  end

  buttonHover = nil
  tableHover = nil

  if inBounds(tableBounds) then
    if not buttonHover then
      if (gfx.mouse_y < padding + innerPadding + #linkPairs * rowHeight) and (gfx.mouse_y > padding + innerPadding) then
        tableHover = math.floor((gfx.mouse_y - innerPadding - padding) / rowHeight)
      else
        tableHover = nil
      end
    end
  elseif inBounds(b1Bounds) then
    buttonHover = b1Bounds
  elseif inBounds(b2Bounds) then
    buttonHover = b2Bounds
  end
  prevClick = gfx.mouse_cap
end

local prevToggle = reaper.GetToggleCommandState(uiToggleCommandId)
local prevChar = gfx.getchar()

local function checkForToggleUi()
  local toggle = reaper.GetToggleCommandState(uiToggleCommandId)
  if toggle == 1 and prevToggle == 0 then

    if windowSize then  
      --reaper.ShowConsoleMsg(windowSize.d .. " " .. windowSize.x .. " ".. windowSize.y .. " ".. windowSize.w .. " ".. windowSize.h) 
      gfx.init("Links", windowSize.w, windowSize.h, windowSize.d, windowSize.x, windowSize.y)
    else
      gfx.init("Links")
    end
    if firstInit then
      scale = gfx.ext_retina
      applyDpiToConstants()
      firstInit = false
    end

  elseif toggle == 0 and prevToggle == 1 then
    local d,x,y,w,h=gfx.dock(-1,0,0,0,0)
    windowSize = {d = d, x = x, y = y, w = w, h = h}
    gfx.quit()
  elseif gfx.getchar() ~= prevChar and gfx.getchar() == -1 then
    reaper.SetToggleCommandState(0, uiToggleCommandId, 0)
    reaper.RefreshToolbar(uiToggleCommandId)
    local d,x,y,w,h=gfx.dock(-1,0,0,0,0)
    --reaper.ShowConsoleMsg(x.." "..y.." "..w.." "..h)
    windowSize = {d = d, x = x, y = y, w = w, h = h}
  end
  prevChar = gfx.getchar()
  prevToggle = toggle
end


reaper.SetToggleCommandState(0, uiToggleCommandId, 0)
local prevIsDirty = reaper.IsProjectDirty(0)

local function checkForSaves()
  local isDirty = reaper.IsProjectDirty(0)
  if (isDirty == 0) and prevIsDirty == 1 then
    saveState()
  end
  prevIsDirty = isDirty
end

local function quit()
  local file = io.open("/Users/mattia/Desktop/prova.txt", "w")

  --reaper.ShowConsoleMsg("1")
  --reaper.SetToggleCommandState(0, uiToggleCommandId, 0)
  --reaper.ShowConsoleMsg("\ncarattere:" .. gfx.getchar() .. "\n")
    local d,x,y,w,h=gfx.dock(-1,0,0,0,0)
  if not (x == 0 and y == 0 and w == 0 and h == 0) then 
  reaper.ShowConsoleMsg("2")
    file:write("GUI aperta ")
    file:write(d,x,y,w,h)
    local d,x,y,w,h=gfx.dock(-1,0,0,0,0)
    reaper.SetExtState(pluginName,"dock",d,true)
    reaper.SetExtState(pluginName,"wndx",x,true)
    reaper.SetExtState(pluginName,"wndy",y,true)
    reaper.SetExtState(pluginName,"wndw",w,true)
    reaper.SetExtState(pluginName,"wndh",h,true)
    gfx.quit()
  elseif windowSize then 
  reaper.ShowConsoleMsg("3")
    file:write("GUI chiusa")
    reaper.SetExtState(pluginName,"dock",windowSize.d,true)
    reaper.SetExtState(pluginName,"wndx",windowSize.x,true)
    reaper.SetExtState(pluginName,"wndy",windowSize.y,true)
    reaper.SetExtState(pluginName,"wndw",windowSize.w,true)
    reaper.SetExtState(pluginName,"wndh",windowSize.h,true)
  end
  file:close()
end

local function setup()
   gfx.ext_retina = 1
   parseTracks()
   d = reaper.GetExtState(pluginName, "dock")
   x, y = tonumber(reaper.GetExtState(pluginName, "wndx")),tonumber(reaper.GetExtState(pluginName, "wndy"))
   w, h = tonumber(reaper.GetExtState(pluginName, "wndw")),tonumber(reaper.GetExtState(pluginName, "wndh"))
 
  if d  and x  and y and w  and h  then 
    windowSize = {d = d, x = x, y = y, w = w, h = h}
    --reaper.ShowConsoleMsg("loading: " .. windowSize.x .. " " .. windowSize.y .. " " .. windowSize.w .. " " .. windowSize.h .."\n\n")
  else
    windowSize = nil
  end
  reaper.atexit(quit)
end

function drawLoop()
  tableView()
  buttons()
  handleMouse()
  checkForSaves()

  gfx.update()
  checkForToggleUi()

  reaper.defer(drawLoop)
end

setup()
drawLoop()
