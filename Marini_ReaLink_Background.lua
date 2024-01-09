-- FONTS
--reaper, gfx = {},{}

local fontSize = 24
gfx.setfont(1)

function GetActionCommandIDByFilename(searchfilename)
  for k in io.lines(reaper.GetResourcePath() .. "/reaper-kb.ini") do
    if k:match("SCR") and k:match(searchfilename) then
      return "_" .. k:match("SCR %d+ %d+ (%S*) ")
    end
  end
  return nil
end

--TABLE VIEW
local currProject = reaper.EnumProjects(-1)
local uiToggleCommand = GetActionCommandIDByFilename("Marini_ReaLink_Ui_Toggle.lua")
local uiToggleCommandId = reaper.NamedCommandLookup(uiToggleCommand)

local pluginName = "Marini_ReaLink"

local linkPairs = {}

local firstInit = true
local scale = 1
local padding = 40
local innerPadding = 20
local trackNamesLeft = 5
local trackNamesSpacing = 50
local rowHeight = 40

local button1W, button1H = 200, 50
local button2W, button2H = 50, 50
local buttonSpacing = 20

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

  reaper.ShowConsoleMsg(size)
  if size == "" then return end

  for linkIndex = 1, tonumber(size) do
    local _, link = reaper.GetProjExtState(0, pluginName, tostring(linkIndex))

    local masterID, slaveID = string.match(link, "{(%d+),"), string.match(link, ",(%d+)}")
    local master, slave = reaper.GetTrack(0, masterID), reaper.GetTrack(0, slaveID)
    if master and slave then
      table.insert(linkPairs, { master, slave })
    end
  end
end

function saveState()
  --reaper.ShowConsoleMsg( tostring(#linkPairs))
  reaper.SetProjExtState(0, pluginName, "", "")
  --reaper.SetProjExtState(0, pluginName, "nLinks", tostring())
  reaper.SetProjExtState(0, pluginName, "nLinks", tostring(#linkPairs))
  for i, pair in ipairs(linkPairs) do
    reaper.ShowConsoleMsg(tostring(i))
    local n1 = string.format("%.0f", reaper.GetMediaTrackInfo_Value(pair[1], "IP_TRACKNUMBER") - 1)
    local n2 = string.format("%.0f", reaper.GetMediaTrackInfo_Value(pair[2], "IP_TRACKNUMBER") - 1)
    reaper.SetProjExtState(0, pluginName, tostring(i), "{" .. n1 .. "," .. n2 .. "}")
    reaper.ShowConsoleMsg("{" .. n1 .. "," .. n2 .. "}\n")
  end
  --file:close()
  reaper.Main_SaveProject(0, false)
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
              reaper.TrackFX_SetParamNormalized(slaveTrack, slaveFX, parIndex, param1)
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
    reaper.ShowMessageBox("Non hai selezionato abbastanza tracce!", "ReaperLink error", 0)
    return
  elseif reaper.CountSelectedTracks(0) > 2 then
    reaper.ShowMessageBox("Hai selezionato troppe tracce!", "ReaperLink error", 0)
    return
  end

  local track1, track2 = reaper.GetSelectedTrack(0, 0), reaper.GetSelectedTrack(0, 1)


  for i = 1, #linkPairs do
    if linkPairs[i][1] == track1 or linkPairs[i][2] == track1
        or linkPairs[i][1] == track2 or linkPairs[i][2] == track2
    then
      reaper.ShowMessageBox("Le tracce selezionate sono già state linkate", "ReaperLink error", 0)
      return
    end
  end
  reaper.MarkProjectDirty()
  table.insert(linkPairs, { reaper.GetSelectedTrack(0, 0), reaper.GetSelectedTrack(0, 1) })
end


local function removeSelectedLink()
  if tableSelection then
    reaper.MarkProjectDirty(0)
    table.remove(linkPairs, tableSelection + 1)
    tableSelection = tableSelection - 1
    if tableSelection == -1 then tableSelection = 0 end
    if #linkPairs == 0 then tableSelection = nil end
  end
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
  elseif inBounds(tableBounds) then 
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
  else
    buttonHover = nil
    tableHover = nil
  end
  prevClick = gfx.mouse_cap
end

local prevToggle = reaper.GetToggleCommandState(uiToggleCommandId)
local function checkForToggleUi()
  local toggle = reaper.GetToggleCommandState(uiToggleCommandId)
  if toggle == 1 and prevToggle == 0 then
    gfx.init("Links")
    if firstInit then
      scale = gfx.ext_retina
      applyDpiToConstants()
      firstInit = false
    end
  elseif toggle == 0 and prevToggle == 1 then
    gfx.quit()
  elseif gfx.getchar() == -1 then
    reaper.SetToggleCommandState(0, uiToggleCommandId, 0)
    reaper.RefreshToolbar(uiToggleCommandId)
  end
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

function drawLoop()
  tableView()
  buttons()
  handleMouse()
  checkForSaves()

  gfx.update()
  checkForToggleUi()

  reaper.defer(drawLoop)
end

gfx.ext_retina = 1
parseTracks()

drawLoop()
