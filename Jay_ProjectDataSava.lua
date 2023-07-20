function main()
    -- 先弹出保存工程对话框
    reaper.Main_OnCommand(40026, 0) -- File: Save project
    reaper.defer(function() end) -- 这里用来挂起脚本，等待用户保存工程后再继续执行

    -- 获取工程路径
    local projectPath = reaper.GetProjectPath("")
    if not projectPath then
        reaper.ShowMessageBox("错误：无法获取工程路径。\n\n请先保存工程。", "项目数据保存器", 0)
        return
    end

    local projectName = reaper.GetProjectName(0, "")
    if projectName == "" then
        reaper.ShowMessageBox("错误：工程未保存。\n\n请先保存工程。", "项目数据保存器", 0)
        return
    end

    local dataFolder = projectPath:sub(1, -6) .. "data/"

    -- 检查文件夹是否存在
    local folderExists = reaper.RecursiveCreateDirectory(dataFolder, 1)
    if not folderExists then
        local createFolderResult = reaper.ShowMessageBox("数据文件夹不存在，是否创建？\n\n路径：" .. dataFolder, "项目数据保存器", 4)
        if createFolderResult == 7 then
            return
        end

        if not reaper.RecursiveCreateDirectory(dataFolder, 0) then
            reaper.ShowMessageBox("错误：无法创建数据文件夹。", "项目数据保存器", 0)
            return
        end

        reaper.ShowMessageBox("已成功创建数据文件夹：\n\n" .. dataFolder, "项目数据保存器", 0)
    end

    if reaper.CF_ShellExecute(dataFolder) then
        
    else
        reaper.ShowMessageBox("错误：无法打开数据文件夹。", "项目数据保存器", 0)
    end
end

main()
