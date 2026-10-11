-- Vector FPS loader :: interlink into the Vector menu
-- paste this one-liner into Vector:
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/simplyaether/vector-fps/main/loader.lua"))()

local PAYLOAD = "https://raw.githubusercontent.com/simplyaether/vector-fps/main/vector_fps.lua"

local function fetch(url)
    for _, n in ipairs({ "HttpGet", "HttpGetAsync", "HttpGetString" }) do
        local f = nil
        local ok1, r1 = pcall(function() return game[n] end)
        if ok1 then f = r1 end
        if type(f) == "function" then
            local ok2, src = pcall(f, game, url)
            if ok2 and type(src) == "string" then return src end
            ok2, src = pcall(f, url)
            if ok2 and type(src) == "string" then return src end
        end
    end

    local ok, src = pcall(function() return HttpGet(url) end)
    if ok and type(src) == "string" then return src end

    ok, src = pcall(function() return http_get(url) end)
    if ok and type(src) == "string" then return src end

    ok, src = pcall(function() return game:HttpGet(url) end)
    if ok and type(src) == "string" then return src end

    return nil
end

local src = fetch(PAYLOAD)
if type(src) ~= "string" or #src < 64 then
    print("[vector-fps] fetch failed - paste vector_fps.lua directly")
    return
end

local chunk, err = loadstring(src)
if not chunk then
    print("[vector-fps] compile error: " .. tostring(err))
    return
end

local ok, run_err = pcall(chunk)
if not ok then
    print("[vector-fps] runtime error: " .. tostring(run_err))
    return
end

print("[vector-fps] online")
