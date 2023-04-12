-- @created on reaper version 6.12c
-- @version 1.0
-- @author JIANG

assert(reaper.CF_GetClipboard, "SWS v2.9.5 or newer is required")


reaper.Main_OnCommand(39201, 0)
-- Get the items count
_itemsCount = reaper.CountMediaItems(0)

regionList = {}
-- Func remove repeat
function removeRepeat(a)
    local b = {}
    for k,v in ipairs(a) do
        if(#b == 0) then b[1] =v
        else 
            local index =0
            for i = 1, #b do
                if (v==b[i]) then break end
                index = index + 1
            end
            if(index == #b) then b[#b+1] = v end
        end
    end
    return b
end          

-- Func split string
function splitString(str, repl)
    local ret = {}
    local pattern = string.format("([^%s]+)",repl)
    string.gsub(str, pattern, 
        function(w) 
            table.insert(ret,w) 
        end)
    return ret
end

-- Func trim
function trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- Get selected items pos
for i = 0, _itemsCount -1 do 
    local item = reaper.GetMediaItem(0, i)

    if reaper.IsMediaItemSelected(item) then 
        
        local curSelPos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        
        -- Compare pos to get selected regionsId
        markerId, regionId = reaper.GetLastMarkerAndCurRegion(0, curSelPos) 
        if regionId >=0 then table.insert(regionList, regionId) end
    
    end
end

nRegionList = removeRepeat(regionList)
table.sort(nRegionList)

local clipBoardData = reaper.CF_GetClipboard('')
local clupBoardDataWithoutTab = string.gsub(clipBoardData,"\t","\n")
local clipList = splitString(clupBoardDataWithoutTab, '\n')

for k,v in ipairs(clipList) do
    v = trim(v)
end

if #nRegionList >= #clipList then 
    for k,v in ipairs(clipList) do
        theRetval, theIsrgn, thePos, theRgnend, theName, theMarkrgnindexnumber = reaper.EnumProjectMarkers(nRegionList[k])
        reaper.SetProjectMarker( theMarkrgnindexnumber, 1, thePos, theRgnend, string.gsub(v,'\r',''))

    end
else 
    for k,v in ipairs(nRegionList) do
        theRetval, theIsrgn, thePos, theRgnend, theName, theMarkrgnindexnumber = reaper.EnumProjectMarkers(v)
        reaper.SetProjectMarker( theMarkrgnindexnumber, 1, thePos, theRgnend, string.gsub(clipList[k],'\r',''))
    end
end


reaper.UpdateArrange()