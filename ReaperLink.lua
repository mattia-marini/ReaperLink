--[[

local prevValue = -1
local track1 = reaper.GetTrack(0, 0)
local track2 = reaper.GetTrack(0, 1)
    
reaper.TrackFX_SetParamNormalized(track1, 0, 0, 0.5)
 --reaper.ShowConsoleMsg(reaper.TrackFX_GetParamNormalized(track1, 0, 0) .. "\n")

function onParameterChange()
    -- Get the first track
    
    local fxCount = reaper.TrackFX_GetCount(track1)
    
    if track1 and track2 then
      for fxIndex = 0, fxCount-1 do
      local parCount = reaper.TrackFX_GetNumParams(track1, fxIndex)
        for parIndex = 0, parCount -1 do 
          --local _, stringa = reaper.TrackFX_GetParamName(track1, fxIndex, parIndex, "")
          local param1 = reaper.TrackFX_GetParamNormalized(track1, fxIndex, parIndex)
          reaper.TrackFX_SetParamNormalized(track2, fxIndex, parIndex, param1)
          --reaper.ShowConsoleMsg(stringa .. "\n")
        end
      end
    end

    -- Schedule the function to run again
    
    reaper.defer(onParameterChange)
end

--Start the listener
onParameterChange()
--]]

-- FONTS
if reaper.GetOS():match("^Win") == nil then
  gfx.setfont(1, "Verdana", 9)
  gfx.setfont(2, "Verdana", 24)
  gfx.setfont(3, "Verdana", 16)
  gfx.setfont(4, "Tahoma", 9)
  gfx.setfont(5, "Tahoma", 12)
  gfx.setfont(6, "Tahoma", 16)
else
  gfx.setfont(1, "Calibri",12)
  gfx.setfont(2, "Calibri", 15)
  gfx.setfont(3, "Calibri", 19)
  gfx.setfont(4, "Calibri", 12)
  gfx.setfont(5, "Calibri", 15)
  gfx.setfont(6, "Calibri", 19)
end

--TABLE VIEW
local linkPairs = { {reaper.GetTrack(0,0),reaper.GetTrack(0,1)},
                  {reaper.GetTrack(0,2),reaper.GetTrack(0,3)} }
local padding = 40
local innerPadding = 20
local spacing = 5
local tableSelection = nil

local button1W, button1H = 200, 50
local button2W, button2H = 50, 50

local tableBounds ={} 


function tableView()

  tableBounds = {x=padding, y=padding, width=gfx.w-2*padding, height= gfx.h - 3*padding - button1H }
  
  gfx.set(0.15,0.15,0.15)
  gfx.rect(0,0,gfx.w, gfx.h)
  gfx.set(0.1,0.1,0.1)

  gfx.rect(padding, padding,gfx.w-2*padding, gfx.h - 3*padding - button1H)
  
  
  if tableSelection then
    gfx.set(0.2,0.2,0.2)
    gfx.rect(
    tableBounds.x + innerPadding, 
    tableBounds.y + innerPadding + 40 * tableSelection, 
    tableBounds.width - 2*innerPadding, 40)
  end
  
  gfx.setfont(2)
  gfx.set(1, 1, 1)
  local maxTrackNameLength = -1
  for i, pair in ipairs(linkPairs) do
    local _, masterTrack = reaper.GetTrackName(pair[1])
    
    if gfx.measurestr(masterTrack) > maxTrackNameLength then 
      maxTrackNameLength = gfx.measurestr(masterTrack)
    end
   
    --reaper.ShowConsoleMsg(gfx.measurestr(masterTrack) .. "\n")
  end

  for i, pair in ipairs(linkPairs) do
    if reaper.ValidatePtr(pair[1], "MediaTrack*") and 
       reaper.ValidatePtr(pair[2], "MediaTrack*") then
      local masterTrack, slaveTrack = pair[1], pair[2]
      local _, masterTrackName = reaper.GetTrackName(pair[1])
      local _, slaveTrackName = reaper.GetTrackName(pair[2])
    
      --gui stuff
      gfx.x, gfx.y = padding + innerPadding, padding + (i-1)*40 + innerPadding
      gfx.drawstr(masterTrackName,0,tableBounds.x + tableBounds.width, tableBounds.y+tableBounds.height)
      gfx.x = maxTrackNameLength + padding + 30
      gfx.drawstr(slaveTrackName, 0,tableBounds.x + tableBounds.width, tableBounds.y+tableBounds.height)
    
      --linking FX parameters
      for fxIndex = 0, reaper.TrackFX_GetCount(masterTrack)-1 do
        for parIndex = 0, reaper.TrackFX_GetNumParams(masterTrack, fxIndex)-1 do
          local _, stringa = reaper.TrackFX_GetParamName(masterTrack, fxIndex, parIndex, "")
          --reaper.ShowConsoleMsg(stringa)
          
          local param1 = reaper.TrackFX_GetParamNormalized(masterTrack, fxIndex, parIndex)
          reaper.ShowConsoleMsg(stringa .. ": " .. param1 .. "\n")
          reaper.TrackFX_SetParamNormalized(slaveTrack, fxIndex, parIndex, param1)
        end
      end
    else
      table.remove(linkPairs, i)
    end

  end
  
  --gfx.rect(0,0,50,50)
end

local b1Bounds, b2Bounds
local buttonHover
function buttons()

  local button1x, button1y = gfx.w - padding - button1W, gfx.h - padding - button1H
  local button2x, button2y = button1x - 20 - button2W, button1y
  b1Bounds = {x1=button1x, y1=button1y, x2=button1x + button1W, y2=button1y + button1H }
  b2Bounds = {x1=button2x, y1=button2y, x2=button2x + button2W, y2=button2y + button2H }
  
  --background
  gfx.set(0.3,0.3,0.3)
  gfx.rect(button1x, button1y, button1W, button1H, true)
  gfx.rect(button2x, button2y, button2W, button2H, true)
  
  --hover
  if buttonHover then
    gfx.set(0.5,0.5,0.5,1)
    gfx.rect(buttonHover.x1, buttonHover.y1, buttonHover.x2-buttonHover.x1, buttonHover.y2 - buttonHover.y1, true)
  end
  
  --lineart
  gfx.set(0,0,0)
  gfx.rect(button1x, button1y, button1W, button1H, false)
  gfx.rect(button2x, button2y, button2W, button2H, false)
 
  --testo
  gfx.set(1,1,1)
  gfx.x, gfx.y = button1x, button1y
  gfx.drawstr("Link", 5, gfx.x + button1W, gfx.y + button1H)

  gfx.x, gfx.y = button2x, button2y
  gfx.drawstr("-", 5, gfx.x + button2W, gfx.y + button2H)
  
  
  
end

local function inBounds(bounds)
gfx.getchar()
local x,y = gfx.mouse_x, gfx.mouse_y

  if bounds.width then
    return x> bounds.x and x < bounds.x + bounds.width 
    and    y > bounds.y and y < bounds.y + bounds.height
  else
    return (x > bounds.x1 and x < bounds.x2 and y > bounds.y1 and y < bounds.y2)
  end
end

local function addSelectedTracks()
  if reaper.CountSelectedTracks(0) < 2 then 
    reaper.ShowConsoleMsg("Non hai selezionato abbastanza tracce!")
    return
  elseif reaper.CountSelectedTracks(0) > 2 then
    reaper.ShowConsoleMsg("Hai selezionato troppe tracce!")
    return
  end
  
  local track1, track2 =  reaper.GetSelectedTrack(0,0), reaper.GetSelectedTrack(0,1)
  
  
  for i = 1, #linkPairs do
    if linkPairs[i][1] == track1 or linkPairs[i][2] == track1
    or linkPairs[i][1] == track2 or linkPairs[i][2] == track2
    then
      reaper.ShowConsoleMsg("Le tracce selezionate sono già state linkate")
      return
    end
  end
  
  table.insert(linkPairs, {reaper.GetSelectedTrack(0,0), reaper.GetSelectedTrack(0,1)})
end

local function removeSelectedLink()
  if tableSelection then 
    table.remove(linkPairs, tableSelection + 1)
  end
end

local prevClick = 0
function handleMouse()
--reaper.ShowConsoleMsg("click")
 
  if gfx.mouse_cap == 1 and prevClick == 0
  then
  
   --click out on table view
  elseif prevClick == 1 and gfx.mouse_cap == 0 then 
    if
    (gfx.mouse_x < tableBounds.x + tableBounds.width and gfx.mouse_x > tableBounds.x) 
    and 
    (gfx.mouse_y < tableBounds.y + tableBounds.height and gfx.mouse_y > tableBounds.y)
    then 
      if (gfx.mouse_y <= padding + innerPadding + #linkPairs*40) and (gfx.mouse_y > padding + innerPadding) then 
        tableSelection =  math.floor((gfx.mouse_y - innerPadding - padding)/40)
      else
      tableSelection = nil
      end
     elseif inBounds(b1Bounds) then
      addSelectedTracks()
     elseif inBounds(b2Bounds) then
      removeSelectedLink()
    end
    
  elseif inBounds(b1Bounds) then buttonHover = b1Bounds
  elseif inBounds(b2Bounds) then buttonHover = b2Bounds
  else buttonHover = nil end
  prevClick = gfx.mouse_cap
  --reaper.ShowConsoleMsg("click")
end


--[[ Main function to draw the window and handle button click
 gfx.init("Linkage list")
 gfx.ext_retina = 1
 reaper.ShowConsoleMsg(gfx.ext_retina)
 draw_scale = 2
function main()
    -- Draw the window
   
    
    -- Draw the button
    -- gfx.rect(buttonX, buttonY, buttonWidth, buttonHeight, true)
    gfx.set(1, 1, 1) -- Set text color to white
    gfx.x = 0
    gfx.y = 0
    gfx.setfont(1, "Helvetica", 24)
    --gfx.showmenu("item11|item2|item3")
    gfx.drawstr("Click me!")
    gfx.drawstr("Click me!")

    -- Update the window
    --gfx.update()

    -- Check for user input
    local char = gfx.getchar()

    -- Handle button click
    if char == 1 then
        -- Button was clicked (left mouse button)
        reaper.ShowConsoleMsg("Button clicked!\n")

        -- Close the window
        gfx.quit()
    elseif char > 0 then
        -- Close the window on any other user input
        gfx.quit()
    else
        -- Continue running the main function
        reaper.defer(main)
    end
end

-- Start the main function
main()
function getDpi()
  local newScale, os = 1, reaper.GetOS()
  if gfx.ext_retina>1.49 then newScale = 2 end

  if os ~= "OSX64" and os ~= "OSX32" and os ~= "macOS-arm64" then
    -- disable (non-macOS) hidpi if window is constrained in height or width
    local minw, minh = 500, 660
    if _dockedRoot.visible ~= false then  minw, minh = 400, 24 end

    if gfx.h < minh*newScale or gfx.w < minw*newScale then newScale = 1 end
    drawScale_nonmac = newScale
    drawScale_inv_nonmac = 1/newScale
  else
    drawScale_inv_mac = 1/newScale
  end

  if newScale ~= drawScale then
    drawScale = newScale
    resize = 1
  end
end
]]--
 gfx.init("Links (tengo er cazzo duro)")
 gfx.ext_retina = 1
function drawLoop()
  tableView()
  buttons()
  handleMouse()
  gfx.update()
  reaper.defer(drawLoop)
end

drawLoop()
