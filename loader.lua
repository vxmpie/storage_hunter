local url = "https://raw.githubusercontent.com/vxmpie/storage_hunter/main/src/main.lua?t=" .. tostring(tick())
local success, code = pcall(function() return game:HttpGet(url) end)

if not success then
    warn("[Network Error] โหลดไฟล์จาก GitHub ไม่ได้ เช็กลิงก์หรืออินเทอร์เน็ต")
else
    local func, err = loadstring(code)
    if not func then
        warn("[Syntax Error] ตรวจพบจุดผิดในไฟล์ main.lua!")
        warn("บรรทัดที่พัง: " .. tostring(err))
    else
        func()
    end
end