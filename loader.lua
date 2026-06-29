local url = "https://raw.githubusercontent.com/vxmpie/storage_hunter/main/src/main.lua?t=" .. tostring(tick())
local success, code = pcall(function() return game:HttpGet(url) end)
if not success then
    warn("[Network Error] โหลดไฟล์จาก GitHub ไม่ได้")
else
    local func, err = loadstring(code)
    if not func then
        warn("[Syntax Error] " .. tostring(err))
    else
        local ok, runErr = pcall(func)
        if not ok then
            warn("[Runtime Error] ตรวจพบบั๊กขณะสคริปต์ทำงาน: " .. tostring(runErr))
        end
    end
end