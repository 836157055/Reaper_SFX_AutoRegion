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
        -- 确定添加
        -- 获取 Reaper 资源路径
        local resPath = reaper.GetResourcePath()
        -- 拼接出 script1.lua 的完整路径
        local script1Path = resPath .. "\\Scripts\\Paste_values_for_region.lua"
        -- 检查 script1.lua 是否存在
        local script1_exists = reaper.file_exists(script1Path)
        --如果存在，则调用 script1.lua 脚本，否则显示错误信息
        if script1_exists then
            -- 调用 script1.lua 脚本
            dofile(script1Path)
        else
            -- 显示错误信息，提示用户将 script1.lua 脚本放到 Reaper 资源路径下的 Scripts 文件夹中,并由用户选择是否打开scripts文件夹
            local button = reaper.ShowMessageBox("请将 Paste_values_for_region.lua 脚本放到 Reaper 资源路径下的 Scripts 文件夹中。\n\nReaper 资源路径：" .. resPath.."\n\n\n点击确认打开Scripts文件夹", "错误", 1)
            if button == 1 then
                -- 打开资源路径
                reaper.CF_ShellExecute(resPath.."\\Scripts")
            end
        end
    end

    reaper.PreventUIRefresh(-1) -- 恢复UI刷新
    reaper.UpdateArrange() -- 更新排列
    reaper.Undo_EndBlock("Add region to adjacent items or merge regions of overlapping items and paste clipboard data", -1) -- 结束撤销块
end

reaper.defer(main) -- 延迟执行main函数
