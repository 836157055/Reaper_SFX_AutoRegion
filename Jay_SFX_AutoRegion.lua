function main()
    reaper.Undo_BeginBlock() -- 开始一个撤销块
    reaper.PreventUIRefresh(1) -- 防止UI刷新

    local item_count = reaper.CountSelectedMediaItems(0) -- 获取选中的媒体项数量

    if item_count < 1 then
        -- 如果没有选中任何媒体项，则显示错误信息并退出
        reaper.ShowMessageBox("没有选中的对象，请选择至少一个对象。", "错误", 0)
        return
    end

    local regions = {} -- 存储所有可能成为区域的媒体项

    -- 遍历选中的媒体项，将其添加到regions表格中
    for i = 0, item_count - 1 do
        local item = reaper.GetSelectedMediaItem(0, i) -- 获取选中的媒体项
        local track = reaper.GetMediaItem_Track(item) -- 获取媒体项所在的轨道
        local track_mute = reaper.GetMediaTrackInfo_Value(track, "B_MUTE") -- 获取轨道是否静音
        local track_vol = reaper.GetMediaTrackInfo_Value(track, "D_VOL") -- 获取轨道音量
        local item_mute = reaper.GetMediaItemInfo_Value(item, "B_MUTE") -- 获取媒体项是否静音

        -- 如果轨道没有静音，音量大于0，媒体项没有静音，则将其添加到regions表格中
        if track_mute == 0 and track_vol > 0 and item_mute == 0 then
            local item_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION") -- 获取媒体项在时间轴上的位置
            local item_len = reaper.GetMediaItemInfo_Value(item, "D_LENGTH") -- 获取媒体项的长度
            local item_end = item_pos + item_len -- 计算媒体项结束的位置

            -- 如果regions表格为空，则将媒体项作为一个新的区域添加到regions表格中
            if #regions == 0 then
                table.insert(regions, { start_time = item_pos, end_time = item_end })
            else
                -- 遍历regions表格，检查媒体项是否与已有区域重叠或相邻，如果是，则合并它们
                local region_added = false
                for _, region in ipairs(regions) do
                    if (item_pos >= region.start_time and item_pos <= region.end_time) or
                            (item_end >= region.start_time and item_end <= region.end_time) or
                            (item_pos <= region.start_time and item_end >= region.end_time) then
                        region.end_time = math.max(region.end_time, item_end)
                        if item_pos < region.start_time then
                            region.start_time = item_pos
                        end
                        region_added = true
                        break
                    end
                end

                -- 如果媒体项没有被合并到已有区域，则将其作为一个新的区域添加到regions表格中
                if not region_added then
                    table.insert(regions, { start_time = item_pos, end_time = item_end })
                end
            end
        end
    end

    -- 根据区域的开始时间对regions表格进行排序
    table.sort(regions, function(a, b)
        return a.start_time < b.start_time
    end)

    -- 合并重叠的区域
    local merged_regions = {}
    for _, region in ipairs(regions) do
        if #merged_regions == 0 or region.start_time > merged_regions[#merged_regions].end_time then
            table.insert(merged_regions, region)
        else
            merged_regions[#merged_regions].end_time = region.end_time
        end
    end

    -- 将合并后的区域添加到项目标记中
    for _, region in ipairs(merged_regions) do
        reaper.AddProjectMarker2(0, true, region.start_time, region.end_time, "", -1, 0)
    end

    -- 询问是否将粘贴板上的数据添加到区域中
    local should_paste = reaper.ShowMessageBox("是否将粘贴板上的数据添加到新的标记中？", "提示", 4)

    if should_paste == 6 then
        -- 替换为第二个脚本中的内容
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
        
    end

    reaper.PreventUIRefresh(-1) -- 恢复UI刷新
    reaper.UpdateArrange() -- 更新排列
    reaper.Undo_EndBlock("Add region to adjacent items or merge regions of overlapping items and paste clipboard data", -1) -- 结束撤销块
end

reaper.defer(main) -- 延迟执行main函数
